#!/usr/bin/env bash
# PreToolUse Bash: blocks dangerous commands (exit 2, reason on stderr).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
[ -n "$cmd" ] || exit 0
# Directory the command runs in; updated by `cd` segments. Git rules apply to the repository the
# segment targets (cwd or `git -C <dir>`), so they hold for every repository of the workspace.
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[ -d "$cwd" ] || cwd="$(jt_project_dir)"

resolve_dir() {
  local d="$1"
  case "$d" in "~"|"~/"*) d="$HOME${d#\~}" ;; esac
  case "$d" in /*) ;; *) d="$cwd/$d" ;; esac
  printf '%s' "$d"
}

block() {
  echo "java-developer: command blocked: $1 Safe alternative: $2" >&2
  exit 2
}

# Split command chains into separate segments.
while IFS= read -r seg; do
  [ -n "${seg// /}" ] || continue
  # shellcheck disable=SC2086
  read -r -a t <<<"$(printf '%s' "$seg" | tr -d "'\"")"
  [ "${#t[@]}" -gt 0 ] || continue
  t[0]="${t[0]#(}"
  s=" ${t[*]} "
  # `git -C <dir> ...` and `git -c k=v ...`: drop the options so the git rules below match the subcommand.
  [[ "$s" =~ [[:space:]]git[[:space:]] ]] && s="$(sed -E 's/[[:space:]]-[Cc][[:space:]]+[^[:space:]]+//g' <<<"$s") "

  # Track `cd <dir>` and find the repository this segment targets.
  if [ "${t[0]}" = "cd" ] && [ -n "${t[1]:-}" ]; then
    [ -d "$(resolve_dir "${t[1]}")" ] && cwd="$(cd "$(resolve_dir "${t[1]}")" && pwd)"
    continue
  fi
  target="$cwd"
  for i in "${!t[@]}"; do
    [ "${t[$i]}" = "-C" ] && [ -n "${t[$((i+1))]:-}" ] && target="$(resolve_dir "${t[$((i+1))]}")"
  done
  current_branch="$(git -C "$target" symbolic-ref --short -q HEAD 2>/dev/null)"

  # rm -rf outside target/
  if [[ "$s" =~ [[:space:]]rm[[:space:]] ]] && [[ "$s" =~ [[:space:]](-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)[[:space:]] ]]; then
    for a in "${t[@]}"; do
      case "$a" in -*|rm|sudo) continue ;; esac
      if [[ "$a" == *..* ]] || ! [[ "$a" =~ ^(\./)?([^[:space:]]*/)?target(/.*)?$ ]]; then
        block "recursive delete of '$a' outside target/." "delete only target/ (mvn clean) or specific files."
      fi
    done
  fi

  # git push
  if [[ "$s" =~ [[:space:]]git[[:space:]]+push[[:space:]] ]]; then
    for a in "${t[@]}"; do
      case "$a" in
        --force|--force-with-lease*|--force-if-includes|-f|-[a-zA-Z]*f*)
          [[ "$a" == -* ]] && block "git push with --force/-f." "a plain git push to your own branch; agree history rewrites with the tech lead." ;;
      esac
    done
    for a in "${t[@]}"; do
      b="${a#HEAD:}"; b="${b#:}"; b="${b#refs/heads/}"
      jt_protected_branch "$b" && block "git push to protected branch $b." "push your working branch and open a PR."
    done
    if jt_protected_branch "$current_branch"; then
      block "git push from branch $current_branch." "create a branch (git checkout -b) and push it."
    fi
  fi

  # No commits on protected branches
  if [[ "$s" =~ [[:space:]]git[[:space:]]+commit[[:space:]] ]] && jt_protected_branch "$current_branch"; then
    block "commit on protected branch $current_branch." "create <type>/<TICKET>/<Short-description> from the base branch."
  fi

  # No Claude attribution in commit messages
  if [[ "$s" =~ [[:space:]]git[[:space:]]+commit([[:space:]]|$) ]]; then
    if jt_has_attribution "$cmd"; then
      block "Claude attribution (Co-Authored-By / Claude-Session / Generated with) in the commit message." "commit message is only '<TICKET> <imperative summary>'."
    fi
    # message read from a file: -F <file> / --file=<file> / -t <file>
    for i in "${!t[@]}"; do
      f=""
      case "${t[$i]}" in
        -F|--file|-t|--template) f="${t[$((i+1))]:-}" ;;
        --file=*|--template=*) f="${t[$i]#*=}" ;;
      esac
      [ -n "$f" ] && [ -f "$f" ] && jt_has_attribution <"$f" && \
        block "Claude attribution in commit message file '$f'." "remove the attribution lines from the file."
    done
  fi

  [[ "$s" =~ [[:space:]]git[[:space:]]+reset[[:space:]].*--hard ]] && \
    block "git reset --hard destroys uncommitted changes." "git stash or git restore for specific files."

  if [[ "$s" =~ [[:space:]]git[[:space:]]+clean[[:space:]] ]] && [[ "$s" =~ [[:space:]]-[a-zA-Z]*f[a-zA-Z]*[[:space:]] ]] && [[ "$s" =~ [[:space:]]-[a-zA-Z]*x[a-zA-Z]* ]]; then
    block "git clean -fdx deletes ignored files (including local settings)." "git clean -n to preview, or mvn clean."
  fi

  # Reading sensitive files
  if [[ "$s" =~ [[:space:]](cat|less|more|head|tail|grep|egrep|fgrep|rg|sed|awk|bat|xxd|strings|base64|cp|scp|source|\.)[[:space:]] ]]; then
    for a in "${t[@]}"; do
      a="${a#<}"
      case "$a" in -*) continue ;; esac
      if jt_is_sensitive "$a"; then
        block "reading sensitive file '$a'." "use application-local*/application-test* or ask the developer to provide the values."
      fi
    done
  fi

  # Sending files out
  if [[ "$s" =~ [[:space:]](curl|wget)[[:space:]] ]] && \
     [[ "$s" =~ ([[:space:]](-d|--data|--data-binary|--data-raw|--data-urlencode|-F|--form)[[:space:]=]*[^[:space:]]*@|--upload-file|--post-file|[[:space:]]-T[[:space:]]) ]]; then
    block "curl/wget uploads files to an external address." "download data with GET only; upload files manually."
  fi

  # Maven: publish, release, migrations
  if [[ "$s" =~ [[:space:]](mvn|\./mvnw|mvnw)[[:space:]] ]]; then
    [[ "$s" =~ [[:space:]](deploy|[a-z-]+:deploy)[[:space:]] ]] && block "mvn deploy publishes artifacts." "use mvn verify."
    [[ "$s" =~ [[:space:]]release: ]] && block "mvn release:* changes versions and publishes." "releases are done by CI/the tech lead."
    if [[ "$s" =~ (flyway:migrate|liquibase:update) ]] && ! [[ "$s" =~ [[:space:]]-P[[:space:]]?[^[:space:]]*(test|local) ]]; then
      block "DB migrations with a non-test profile." "add a test profile (-Ptest) or apply migrations through CI."
    fi
  fi
done < <(printf '%s\n' "$cmd" | sed -e 's/&&/\n/g' -e 's/||/\n/g' -e 's/[;|&]/\n/g')

exit 0

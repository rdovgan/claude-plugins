#!/usr/bin/env bash
# PreToolUse Bash: blocks dangerous commands (exit 2, reason on stderr).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

cmd="$(jq -r '.tool_input.command // empty' <<<"$(cat)")"
[ -n "$cmd" ] || exit 0

block() {
  echo "java-team: command blocked: $1 Safe alternative: $2" >&2
  exit 2
}

current_branch="$(jt_branch)"

# Split command chains into separate segments.
while IFS= read -r seg; do
  [ -n "${seg// /}" ] || continue
  # shellcheck disable=SC2086
  read -r -a t <<<"$(printf '%s' "$seg" | tr -d "'\"")"
  [ "${#t[@]}" -gt 0 ] || continue
  s=" ${t[*]} "

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
    if [[ "$s" =~ [[:space:]](main|master|HEAD:main|HEAD:master|:main|:master|refs/heads/main|refs/heads/master)[[:space:]] ]]; then
      block "git push to main/master." "push a feature branch and open a PR."
    fi
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
      block "git push from branch $current_branch." "create a branch (git checkout -b) and push it."
    fi
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

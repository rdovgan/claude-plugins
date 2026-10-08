#!/usr/bin/env bash
# PreToolUse Bash: allowlist of read-only commands (exit 2, reason on stderr).
# Everything that can write, delete, build, commit or reach the network is refused.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ja_require_jq
ja_off && exit 0

cmd="$(jq -r '.tool_input.command // empty' <<<"$(cat)")"
[ -n "$cmd" ] || exit 0

block() {
  echo "java-analyst: command blocked: $1 This plugin is read-only (analysis only). Use Read/Grep/Glob to explore and the Write tool for documents in .claude/analysis/<task>/." >&2
  exit 2
}

# Command substitution runs code even inside double quotes.
case "$cmd" in
  *'$('*|*'`'*|*'<('*|*'>('*) block "command substitution is not allowed." ;;
esac

# Same text with quoted parts replaced by Q (backslash-aware). Redirects and separators are judged on it.
bare="$(printf '%s' "$cmd" | awk '
  BEGIN { st = 0 }
  { if (NR > 1) printf "\n"
    n = length($0)
    for (i = 1; i <= n; i++) {
      c = substr($0, i, 1)
      if (st == 0) {
        if (c == "\\") { printf "Q"; i++ }
        else if (c == "\047") { st = 1; printf "Q" }
        else if (c == "\"") { st = 2; printf "Q" }
        else printf "%s", c
      } else if (st == 1) { if (c == "\047") st = 0 }
      else { if (c == "\\") i++; else if (c == "\"") st = 0 }
    }
  }')"

# Output redirects: only the harmless 2>&1, >/dev/null and 2>/dev/null survive.
stripped="$(sed -E 's/[0-9]?>>?[[:space:]]*\/dev\/null//g; s/[0-9]?>&[0-9]//g' <<<"$bare")"
case "$stripped" in *'>'*) block "output redirection writes files." ;; esac

# Sensitive files by name, whatever the command is.
for a in $(printf '%s' "$cmd" | tr -d "'\"" | tr -s '[:space:]' '\n'); do
  a="${a#<}"
  case "$a" in -*) continue ;; esac
  ja_is_sensitive "$a" && block "reading sensitive file '$a'."
done

while IFS= read -r seg; do
  [ -n "${seg// /}" ] || continue
  # shellcheck disable=SC2206
  t=($seg)
  [ "${#t[@]}" -gt 0 ] || continue
  c="${t[0]#(}"
  s=" ${t[*]} "

  # Options that make an otherwise read-only command write files or run programs.
  case "$c" in
    sort) [[ "$s" =~ [[:space:]](-o|--output)([[:space:]=]|$) ]] && block "sort -o writes a file." ;;
    tree) [[ "$s" =~ [[:space:]]-[a-zA-Z]*o[[:space:]] ]] && block "tree -o writes a file." ;;
    rg)   [[ "$s" =~ [[:space:]]--(pre|hostname-bin)([[:space:]=]|$) ]] && block "rg --pre runs a program." ;;
    uniq) n=0; for a in "${t[@]:1}"; do case "$a" in -*) ;; *) n=$((n+1)) ;; esac; done
          [ "$n" -gt 1 ] && block "uniq with an output file writes it." ;;
  esac

  case "$c" in
    ls|cat|head|tail|wc|grep|egrep|fgrep|rg|tree|stat|file|pwd|cd|echo|printf|sort|uniq|cut|tr|diff|basename|dirname|realpath|which|date|true|jq|column|nl|du|uname|whoami|test|\[) ;;
    sed)
      [[ "$s" =~ [[:space:]](-i[^[:space:]]*|--in-place[^[:space:]]*)[[:space:]] ]] && block "sed -i edits files."
      # w/e commands and the s///w, s///e flags write files or run commands
      printf '%s' "$cmd" | grep -qE "s(/|#|\|)[^/#|]*(/|#|\|)[^/#|]*(/|#|\|)[gpiI0-9]*[we]|(^|[;{}'\"[:space:]])[0-9,$]*[we][[:space:]]+[^[:space:]]" && \
        block "sed script that writes files or runs commands." ;;
    awk)
      printf '%s' "$cmd" | grep -qE 'system[[:space:]]*\(|getline|print[^|]*\|[[:space:]]*"|>>?[[:space:]]*"' && \
        block "awk program that writes files or runs commands." ;;
    xargs)
      nxt=""
      for a in "${t[@]:1}"; do case "$a" in -*) continue ;; *) nxt="$a"; break ;; esac; done
      case "$nxt" in grep|egrep|fgrep|rg|cat|ls|wc|head|tail|file|stat|echo|basename|dirname) ;; *) block "xargs may run only read-only commands (grep, cat, ls, wc, head, tail, file, stat)." ;; esac ;;
    npm|pnpm|yarn)
      [[ "$s" =~ [[:space:]](ls|list|view|info|outdated|explain|why|root|prefix)[[:space:]] ]] || \
        block "only read-only '$c ls|list|view|outdated|explain|why' is allowed; installs and scripts change files or run project code." ;;
    node|python|python3|java|javac|ruby|go|rustc|cargo|dotnet|php)
      case "${t[1]:-}" in -v|-V|--version|-version|version) [ "${#t[@]}" -le 2 ] || block "'$c' runs code; only a bare version query is allowed." ;;
        *) block "'$c' runs code; only its version query is allowed." ;; esac ;;
    find)
      [[ "$s" =~ [[:space:]](-exec|-execdir|-ok|-okdir|-delete|-fprint|-fprint0|-fprintf|-fls)[[:space:]] ]] && \
        block "find with -exec/-delete/-fprint." ;;
    git)
      sub=""; skip=0
      for a in "${t[@]:1}"; do
        if [ "$skip" = 1 ]; then skip=0; continue; fi
        case "$a" in -C) skip=1; continue ;; -c|-c*) block "git -c can run configured programs." ;; -*) continue ;; esac
        sub="$a"; break
      done
      case "$sub" in
        status|log|diff|show|blame|rev-parse|ls-files|ls-tree|grep|cat-file|describe|shortlog|merge-base|rev-list|name-rev|show-ref|for-each-ref|reflog) ;;
        branch|tag|remote)
          [[ "$s" =~ [[:space:]](-d|-D|-m|-M|-c|-C|-f|--delete|--move|--copy|--force|--set-upstream-to|--unset-upstream|add|remove|rm|rename|set-url|prune|update)[[:space:]] ]] && \
            block "git $sub that changes the repository."
          [ "$sub" = remote ] && [[ "$s" =~ [[:space:]]remote[[:space:]]+[^-[:space:]] ]] && ! [[ "$s" =~ [[:space:]]remote[[:space:]]+(show|get-url)[[:space:]] ]] && \
            block "git remote with this subcommand."
          if [ "$sub" = branch ] || [ "$sub" = tag ]; then
            # a bare name after branch/tag would create one
            after=0
            for a in "${t[@]:1}"; do
              if [ "$after" = 1 ]; then case "$a" in -*) ;; *) block "git $sub '$a' would create a ref." ;; esac; fi
              [ "$a" = "$sub" ] && after=1
            done
          fi ;;
        *) block "git ${sub:-<none>} is not read-only." ;;
      esac
      [[ "$s" =~ [[:space:]]--output ]] && block "git --output writes a file."
      [[ "$s" =~ [[:space:]](-O|--open-files-in-pager|--ext-diff|--textconv)([[:space:]=]|$) ]] && block "git option that runs an external program." ;;
    mvn|./mvnw|mvnw)
      [[ "$s" =~ [[:space:]](dependency:tree|dependency:list|help:effective-pom|help:evaluate)[[:space:]] ]] || \
        block "only 'mvn dependency:tree', 'dependency:list' and 'help:effective-pom' are allowed; builds and tests change target/."
      [[ "$s" =~ [[:space:]]-D(output|append) ]] && block "mvn output options write files." ;;
    *) block "'$c' is not on the read-only list." ;;
  esac
done < <(printf '%s\n' "$bare" | sed -e 's/&&/\n/g' -e 's/||/\n/g' -e 's/[;|&]/\n/g')
exit 0

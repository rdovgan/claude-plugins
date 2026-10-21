#!/usr/bin/env bash
# Checks the code references of documents: every `repo/path/File.ext` or `repo/path/File.ext:LINE[-LINE]`
# in backticks must name an existing repository, an existing file and a line inside it.
# Usage: check-refs.sh <file.md | folder> ...   Prints one problem per line; exit 1 if any, 0 if clean.
# Prints "refs: N checked" on stdout at the end. Reads only the documents and the file sizes.
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"

root="$(qd_root)"
[ "$#" -gt 0 ] || { echo "usage: check-refs.sh <file.md | folder> ..." >&2; exit 2; }

docs=()
for a in "$@"; do
  if [ -d "$a" ]; then
    while IFS= read -r f; do docs+=("$f"); done < <(find "$a" -name '*.md' -not -path '*/work/*' | sort)
  elif [ -f "$a" ]; then docs+=("$a"); fi
done

n=0; bad=0
for doc in "${docs[@]}"; do
  while IFS= read -r ref; do
    path="${ref%%:*}"; lines=""
    [ "$path" != "$ref" ] && lines="${ref#*:}"
    repo="${path%%/*}"
    # Only tokens that look like a file in a repository: repo/.../name.ext
    case "${path##*/}" in *.*) ;; *) continue ;; esac
    n=$((n + 1))
    if [ ! -e "$root/$repo/.git" ]; then
      # links between documents (work/trace.md) are not code references; a mistyped repo is
      case "${path##*.}" in java|kt|groovy|scala|php|js|jsx|ts|tsx|vue|py|xml|sql|yml|yaml|properties|json|twig|html) ;; *) n=$((n - 1)); continue ;; esac
      echo "$doc: \`$ref\`: '$repo' is not a repository in $root"; bad=$((bad + 1)); continue
    fi
    if [ ! -f "$root/$path" ]; then
      echo "$doc: \`$ref\`: file does not exist"; bad=$((bad + 1)); continue
    fi
    if [ -n "$lines" ]; then
      last="${lines##*-}"
      total="$(wc -l < "$root/$path" | tr -d ' ')"
      case "$last" in ''|*[!0-9]*) echo "$doc: \`$ref\`: bad line number"; bad=$((bad + 1)); continue ;; esac
      if [ "$last" -gt "$((total + 1))" ]; then
        echo "$doc: \`$ref\`: line $last is past the end of the file ($total lines)"; bad=$((bad + 1))
      fi
    fi
  done < <(grep -oE '`[A-Za-z0-9_.-]+/[^` :]+(:[0-9]+(-[0-9]+)?)?`' "$doc" 2>/dev/null | tr -d '`' | sort -u)
done
echo "refs: $n checked, $bad broken"
[ "$bad" -eq 0 ]

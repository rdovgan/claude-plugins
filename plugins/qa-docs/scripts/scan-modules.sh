#!/usr/bin/env bash
# Prints a compact table of the source repositories in the workspace: kind (maven, gradle, php, js, other),
# branch, commit, last commit date, the build name, and which other workspace repositories each one
# names in its build files. Reads build manifests only (pom.xml, build.gradle, composer.json, package.json),
# never sources or secret files. Usage: scan-modules.sh
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"

# Root artifactId of a pom: first <artifactId> outside <parent>, before dependencies/build.
pom_artifact() {
  awk '
    /<parent>/ {skip=1}
    /<\/parent>/ {skip=0; next}
    /<dependencies>|<dependencyManagement>|<build>|<profiles>/ {exit}
    !skip && match($0, /<artifactId>[^<]+<\/artifactId>/) {
      print substr($0, RSTART + 12, RLENGTH - 25); exit
    }' "$1"
}

json_name() { jq -r '.name // empty' "$1" 2>/dev/null; }

repos=(); kinds=(); names=(); tokens=()
while IFS= read -r repo; do
  k=other; n=""; tok=""
  if [ -f "$repo/pom.xml" ]; then k=maven; n="$(pom_artifact "$repo/pom.xml")"; tok="<artifactId>$n</artifactId>"
  elif [ -f "$repo/build.gradle" ] || [ -f "$repo/build.gradle.kts" ]; then k=gradle; n="$(basename "$repo")"; tok="$n"
  elif [ -f "$repo/composer.json" ]; then k=php; n="$(json_name "$repo/composer.json")"; tok="\"$n\""
  elif [ -f "$repo/package.json" ]; then k=js; n="$(json_name "$repo/package.json")"; tok="\"$n\""
  fi
  repos+=("$repo"); kinds+=("$k"); names+=("${n:-?}"); tokens+=("$tok")
done < <(qd_repos)

printf 'repo\tkind\tbranch\tcommit\tdate\tname\tuses\n'
for i in "${!repos[@]}"; do
  repo="${repos[$i]}"
  manifests="$(git -C "$repo" ls-files -- '*pom.xml' '*build.gradle' '*build.gradle.kts' '*composer.json' '*package.json' 2>/dev/null | grep -v node_modules)"
  uses=""
  if [ -n "$manifests" ]; then
    for j in "${!repos[@]}"; do
      [ "$i" = "$j" ] && continue
      t="${tokens[$j]}"
      [ -n "$t" ] && [ "${names[$j]}" != "?" ] || continue
      if (cd "$repo" && printf '%s\n' "$manifests" | tr '\n' '\0' | xargs -0 grep -qF -- "$t" 2>/dev/null); then
        uses="$uses $(basename "${repos[$j]}")"
      fi
    done
  fi
  branch="$(git -C "$repo" symbolic-ref --short -q HEAD 2>/dev/null)"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(basename "$repo")" "${kinds[$i]}" "${branch:-detached}" \
    "$(git -C "$repo" rev-parse --short=12 HEAD 2>/dev/null)" "$(git -C "$repo" log -1 --format=%cs 2>/dev/null)" \
    "${names[$i]}" "${uses# }"
done
exit 0

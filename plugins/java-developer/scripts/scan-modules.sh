#!/usr/bin/env bash
# Prints a compact map of the team's Maven repositories in the workspace: branch, root artifactId,
# and which other scanned artifacts each repo mentions in its tracked pom.xml files.
# Scope: workspace repositories named (in backticks) in reference/modules.md, plus the project repo.
# Reads pom.xml files only (no sources, no secret files). Usage: scan-modules.sh [workspace-dir]
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"

[ -n "${1:-}" ] && JAVA_TEAM_WORKSPACE="$1"
export JAVA_TEAM_WORKSPACE
root="$(jt_project_dir)"
map="$(dirname "$0")/../reference/modules.md"

# Artifact id of a pom: first <artifactId> outside <parent> and the dependencies/build blocks.
pom_artifact() {
  awk '
    /<parent>/ {skip=1}
    /<\/parent>/ {skip=0; next}
    /<dependencies>|<dependencyManagement>|<build>|<profiles>/ {exit}
    !skip && match($0, /<artifactId>[^<]+<\/artifactId>/) {
      print substr($0, RSTART + 12, RLENGTH - 25); exit
    }' "$1"
}

in_scope() { [ "$1" = "$root" ] || grep -qF "\`$(basename "$1")\`" "$map" 2>/dev/null; }

repos=()
arts=()
while IFS= read -r repo; do
  [ -f "$repo/pom.xml" ] && in_scope "$repo" || continue
  repos+=("$repo")
  arts+=("$(pom_artifact "$repo/pom.xml")")
done < <(jt_workspace_repos)

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
for j in "${!arts[@]}"; do [ -n "${arts[$j]}" ] && printf '<artifactId>%s</artifactId>\n' "${arts[$j]}"; done > "$tmp"

for i in "${!repos[@]}"; do
  repo="${repos[$i]}"
  found="$(git -C "$repo" ls-files -z -- '*pom.xml' 2>/dev/null | (cd "$repo" && xargs -0 grep -ohFf "$tmp" 2>/dev/null) | sort -u)"
  uses=""
  for j in "${!repos[@]}"; do
    [ "$i" = "$j" ] && continue
    [ -n "${arts[$j]}" ] && grep -qxF "<artifactId>${arts[$j]}</artifactId>" <<<"$found" && uses="$uses $(basename "${repos[$j]}")"
  done
  branch="$(git -C "$repo" symbolic-ref --short -q HEAD 2>/dev/null)"
  printf '%s: branch=%s artifact=%s uses=[%s]\n' "$(basename "$repo")" "${branch:-detached}" "${arts[$i]:-?}" "${uses# }"
done
exit 0

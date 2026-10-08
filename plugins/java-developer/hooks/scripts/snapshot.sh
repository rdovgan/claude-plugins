#!/usr/bin/env bash
# PreCompact, SessionEnd: mechanical state snapshot in ${CLAUDE_PLUGIN_DATA}.
# Only branch, changed files, spec path, time. session-summary logic is not duplicated here.
# Team repositories (reference/modules.md) of the workspace with uncommitted changes are listed after the project.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

root="$(jt_project_dir)"
data="$(jt_data_dir)"
cd "$root" 2>/dev/null || exit 0
command -v git >/dev/null 2>&1 || exit 0

branch="$(jt_branch)"
key="$(jt_jira_key "$branch")"
spec=""
[ -n "$key" ] && [ -f ".claude/specs/$key.md" ] && spec=".claude/specs/$key.md"
id="$(printf '%s' "$root" | cksum | cut -d' ' -f1)"

{
  echo "time: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "branch: ${branch:-detached}"
  echo "spec: ${spec:-none}"
  echo "changed files:"
  git status --porcelain 2>/dev/null | head -n 50 | sed 's/^/  /'
  while IFS= read -r repo; do
    [ "$repo" = "$root" ] && continue
    grep -qF "\`$(basename "$repo")\`" "${CLAUDE_PLUGIN_ROOT}/reference/modules.md" 2>/dev/null || continue
    st="$(git -C "$repo" status --porcelain 2>/dev/null | grep -v '\.DS_Store' | head -n 20)"
    [ -n "$st" ] || continue
    echo "other repo $(basename "$repo") (branch $(git -C "$repo" symbolic-ref --short -q HEAD)):"
    printf '%s\n' "$st" | sed 's/^/  /'
  done < <(jt_workspace_repos)
} > "$data/snapshot.$id.txt"
exit 0

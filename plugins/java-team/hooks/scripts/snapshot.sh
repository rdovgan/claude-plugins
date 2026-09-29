#!/usr/bin/env bash
# PreCompact, SessionEnd: mechanical state snapshot in ${CLAUDE_PLUGIN_DATA}.
# Only branch, changed files, spec path, time. session-summary logic is not duplicated here.
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
} > "$data/snapshot.$id.txt"
exit 0

#!/usr/bin/env bash
# PreCompact, SessionEnd: механічний знімок стану в ${CLAUDE_PLUGIN_DATA}.
# Лише гілка, змінені файли, шлях до специфікації, час. Логіка session-summary тут не дублюється.
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
  echo "spec: ${spec:-немає}"
  echo "changed files:"
  git status --porcelain 2>/dev/null | head -n 50 | sed 's/^/  /'
} > "$data/snapshot.$id.txt"
exit 0

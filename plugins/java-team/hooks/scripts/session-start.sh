#!/usr/bin/env bash
# SessionStart: stdout goes into the agent's context.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

sid="$(jq -r '.session_id // "unknown"' <<<"$(cat)")"
root="$(jt_project_dir)"
data="$(jt_data_dir)"
cd "$root" 2>/dev/null || exit 0

: > "$data/start.$sid"   # session start marker for verify.sh

command -v git >/dev/null 2>&1 || exit 0
branch="$(jt_branch)"
key="$(jt_jira_key "$branch")"
echo "java-team: branch ${branch:-detached}"
[ -n "$key" ] && echo "java-team: Jira key from the branch name: $key"
if [ -n "$key" ] && [ -f ".claude/specs/$key.md" ]; then
  echo "java-team: task spec: .claude/specs/$key.md - read it and continue from it."
elif [ -n "$key" ]; then
  echo "java-team: no spec for $key yet - start with task-research."
fi

id="$(printf '%s' "$root" | cksum | cut -d' ' -f1)"
if [ -f "$data/snapshot.$id.txt" ]; then
  echo "java-team: latest state snapshot:"
  sed 's/^/  /' "$data/snapshot.$id.txt"
fi
exit 0

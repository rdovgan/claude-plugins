#!/usr/bin/env bash
# SessionStart: stdout потрапляє в контекст агента.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

sid="$(jq -r '.session_id // "unknown"' <<<"$(cat)")"
root="$(jt_project_dir)"
data="$(jt_data_dir)"
cd "$root" 2>/dev/null || exit 0

: > "$data/start.$sid"   # початок сесії для verify.sh

command -v git >/dev/null 2>&1 || exit 0
branch="$(jt_branch)"
key="$(jt_jira_key "$branch")"
echo "java-team: гілка ${branch:-detached}"
[ -n "$key" ] && echo "java-team: ключ Jira з назви гілки: $key"
if [ -n "$key" ] && [ -f ".claude/specs/$key.md" ]; then
  echo "java-team: специфікація задачі: .claude/specs/$key.md — прочитай її і продовжуй за нею."
elif [ -n "$key" ]; then
  echo "java-team: специфікації для $key ще немає — починай із task-research."
fi

id="$(printf '%s' "$root" | cksum | cut -d' ' -f1)"
if [ -f "$data/snapshot.$id.txt" ]; then
  echo "java-team: останній знімок стану:"
  sed 's/^/  /' "$data/snapshot.$id.txt"
fi
exit 0

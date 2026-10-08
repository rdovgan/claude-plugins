#!/usr/bin/env bash
# PostToolUse Bash: safety net. After a git commit, removes Claude attribution lines from the
# new HEAD message. Only rewrites a commit that is not yet on any remote branch.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

cmd="$(jq -r '.tool_input.command // empty' <<<"$(cat)")"
[[ "$cmd" =~ git[[:space:]]+commit([[:space:]]|$) ]] || exit 0

root="$(jt_project_dir)"
msg="$(git -C "$root" log -1 --format=%B 2>/dev/null)" || exit 0
jt_has_attribution "$msg" || exit 0

if [ -n "$(git -C "$root" branch -r --contains HEAD 2>/dev/null)" ]; then
  echo "java-developer: HEAD commit contains Claude attribution but is already on a remote branch; not rewriting. Tell the developer." >&2
  exit 2
fi

clean="$(printf '%s\n' "$msg" | grep -viE 'co-authored-by:[[:space:]]*claude|claude-session:|generated with.*claude|noreply@anthropic\.com|🤖 generated' \
  | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}')"
git -C "$root" -c core.hooksPath=/dev/null commit --amend --no-verify -q -m "$clean" >/dev/null 2>&1 \
  && echo "java-developer: removed Claude attribution from the last commit message." >&2
exit 0

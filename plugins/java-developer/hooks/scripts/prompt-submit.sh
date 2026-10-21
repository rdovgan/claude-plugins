#!/usr/bin/env bash
# UserPromptSubmit: process reminder when the prompt has a Jira key and no spec.
# The amount of process is decided by task-triage, so the reminder does not demand a spec.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

prompt="$(jq -r '.prompt // empty' <<<"$(cat)")"
root="$(jt_project_dir)"

for key in $(printf '%s' "$prompt" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | sort -u); do
  if [ ! -f "$root/.claude/specs/$key.md" ]; then
    echo "java-developer: the prompt mentions task $key and .claude/specs/$key.md does not exist. Start with task-research; its task-triage step decides the level. Trivial: a short plan in chat, then the change. Standard/complex: task-interview and task-spec; do not change code before the spec is confirmed."
  fi
done
exit 0

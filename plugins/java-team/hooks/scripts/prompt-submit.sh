#!/usr/bin/env bash
# UserPromptSubmit: нагадування про процес, якщо в запиті є ключ Jira без специфікації.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

prompt="$(jq -r '.prompt // empty' <<<"$(cat)")"
root="$(jt_project_dir)"

for key in $(printf '%s' "$prompt" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | sort -u); do
  if [ ! -f "$root/.claude/specs/$key.md" ]; then
    echo "java-team: у запиті задача $key, специфікації .claude/specs/$key.md немає. Почни з task-research, потім task-interview і task-spec; код не змінюй до підтвердженої специфікації."
  fi
done
exit 0

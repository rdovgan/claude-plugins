#!/usr/bin/env bash
# UserPromptSubmit: process reminder when the prompt has a Jira key and there is no analysis yet.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qa_require_jq
qa_off && exit 0

prompt="$(jq -r '.prompt // empty' <<<"$(cat)")"
out="$(qa_out_root)"

for key in $(printf '%s' "$prompt" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | sort -u); do
  if [ ! -d "$out/$key" ]; then
    echo "qa-analyst: the prompt mentions task $key and .claude/qa-analysis/$key/ does not exist. Run the QA analysis workflow (/qa-analyst:analyze $key: research, interview, report). Do not change any code."
  fi
done
exit 0

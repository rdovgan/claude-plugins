#!/usr/bin/env bash
# UserPromptSubmit: a Jira key in the prompt starts a conversation about the task, not a report.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ja_require_jq
ja_off && exit 0

prompt="$(jq -r '.prompt // empty' <<<"$(cat)")"
out="$(ja_out_root)"

# A report or full run: the formats selected right now (the formats row may have changed them since the session started).
case "$prompt" in
  /java-analyst:report*|/java-analyst:analyze*)
    fmts="$(ja_formats | tr '\n' ' ')"; fmts="${fmts% }"
    echo "java-analyst: formats selected now: ${fmts:-none}. Flags in the command replace them for this run." ;;
esac

for key in $(printf '%s' "$prompt" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | sort -u); do
  case "$prompt" in /java-analyst:*) continue ;; esac
  notes="no notes yet"; [ -f "$out/$key/notes.md" ] && notes="read .claude/analysis/$key/notes.md first"
  echo "java-analyst: the prompt mentions task $key ($notes). Answer the question in chat: read the ticket and only the sources this question needs, reply short. Do not run /java-analyst:analyze and do not write report documents unless the developer asks for a report. Keep what you established in .claude/analysis/$key/notes.md (a few lines). Do not change any code."
done
exit 0

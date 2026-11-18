#!/usr/bin/env bash
# Stop: a report written in this session (.claude/reports/<KEY>/.formats, written by task-report when it starts)
# must have every file of its formats, filled. Only the formats of that report are checked (D-48).
# Blocks once; with stop_hook_active it only warns, so there is no loop.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
# shellcheck source=glossary.sh
. "$(dirname "$0")/glossary.sh"
jt_require_jq

input="$(cat)"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
active="$(jq -r '.stop_hook_active // false' <<<"$input")"
marker="$(jt_data_dir)/start.$sid"
out="$(jt_reports_dir)"
[ -d "$out" ] && [ -f "$marker" ] || exit 0

problems=""
add() { problems="$problems
- $1"; }
for f in "$out"/*/.formats; do
  [ -f "$f" ] && [ "$f" -nt "$marker" ] || continue
  dir="$(dirname "$f")"; d="${dir##*/}"
  for fmt in $(jt_format_order "$(cat "$f")"); do
    file="$(jt_format_file "$fmt")"
    [ -n "$file" ] || continue
    if [ ! -f "$dir/$file" ]; then add "$d/$file is missing: the $fmt format is in this report"; continue; fi
    grep -q '{{' "$dir/$file" && add "$d/$file still has {{placeholders}}"
    case "$fmt" in
      pr) grep -q '^## How it was tested' "$dir/$file" || add "$d/pr.md has no '## How it was tested' section" ;;
      qa) grep -q '^## How to test' "$dir/$file" || add "$d/qa-handoff.md has no '## How to test' section"
          grep -qE '^- \[ \]|^\| *[0-9]+ *\|' "$dir/$file" || add "$d/qa-handoff.md has no checks (a checklist or a steps table)" ;;
      review) grep -qiE '^## (Verdict|Summary)' "$dir/$file" || add "$d/review.md has no '## Verdict' section" ;;
    esac
  done
  # Team terms (D-49): no translation from the glossary's "avoid" column in the files of this report.
  files=()
  for fmt in $(jt_format_order "$(cat "$f")"); do
    file="$(jt_format_file "$fmt")"
    [ -n "$file" ] && [ -f "$dir/$file" ] && files+=("$dir/$file")
  done
  while IFS= read -r t; do
    [ -n "$t" ] && add "${t#"$out"/} (glossary)"
  done < <(gl_check ${files[@]+"${files[@]}"} -- "${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}" "$(jt_workspace_dir)" "$(jt_project_dir)/.claude/glossary.md")
done

[ -n "$problems" ] || exit 0
msg="The report is not finished (only the formats of this report are checked):$problems
Do not fill gaps just to pass this check; if something cannot be done now, tell the developer what is missing and why, then stop."
if [ "$active" = true ]; then echo "java-developer: $msg" >&2; exit 0; fi
jq -n --arg r "$msg" '{decision: "block", reason: $r}'
exit 0

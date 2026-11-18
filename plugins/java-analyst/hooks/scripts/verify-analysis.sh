#!/usr/bin/env bash
# Stop: checks the report written in this session, and only the formats that report was asked for.
# A conversation (answers in chat, notes.md, 01-research.md, 02-interview.md) is never checked.
# Which formats a report has: .claude/analysis/<task>/.formats, written by analysis-report when it starts
# (the selected formats or the flags of the run). Without it (a single format through /java-analyst:present),
# the formats whose files were written in this session.
# Blocks once; with stop_hook_active it only warns, so there is no loop.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ja_require_jq
ja_off && exit 0

input="$(cat)"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
active="$(jq -r '.stop_hook_active // false' <<<"$input")"
out="$(ja_out_root)"
marker="$(ja_data_dir)/start.$sid"
[ -d "$out" ] && [ -f "$marker" ] || exit 0

problems=""
add() { problems="$problems
- $1"; }

for dir in "$out"/*/; do
  dir="${dir%/}"; d="${dir##*/}"
  [ -d "$dir" ] || continue
  if [ -f "$dir/.formats" ] && [ "$dir/.formats" -nt "$marker" ]; then
    fmts="$(ja_format_order "$(cat "$dir/.formats")")"
  else
    fmts="$(find "$dir" -maxdepth 1 -type f -newer "$marker" 2>/dev/null | while IFS= read -r f; do ja_file_format "${f##*/}"; done)"
    fmts="$(ja_format_order "$(printf '%s ' $fmts)")"
  fi
  [ -n "$fmts" ] || continue

  for fmt in $fmts; do
    for file in $(ja_format_files "$fmt"); do
      if [ ! -f "$dir/$file" ]; then
        add "$d/$file is missing: the $fmt format is in this report; $(case "$fmt" in summary) printf 'write it (analysis-report, the summary format)' ;; dev) printf 'run the present-dev-guide skill' ;; *) printf 'run the present-%s skill' "$fmt" ;; esac)"
        continue
      fi
      grep -q '{{' "$dir/$file" && add "$d/$file still has {{placeholders}}"
    done
    case "$fmt" in
      summary)
        [ -f "$dir/03-flows.md" ] && ! grep -q '^```mermaid' "$dir/03-flows.md" && add "$d/03-flows.md has no mermaid diagram"
        for doc in 04-findings.md 06-implementation-guide.md; do
          [ -f "$dir/$doc" ] && ! grep -qE '\bR[0-9]+\b' "$dir/$doc" && add "$d/$doc does not refer to any requirement R*: show which requirements it covers"
        done ;;
      dev)
        g="$dir/07-dev-guide.md"
        [ -f "$g" ] || continue
        grep -qE '^[[:space:]]*(classDiagram|sequenceDiagram)' "$g" || add "$d/07-dev-guide.md has no classDiagram or sequenceDiagram of the design"
        grep -qE '^[[:space:]]*```(java|kotlin|groovy|xml|sql|yaml)' "$g" || add "$d/07-dev-guide.md has no reference code or templates"
        grep -qE '\bR[0-9]+\b' "$g" || add "$d/07-dev-guide.md does not refer to any requirement R*" ;;
    esac
  done
done

[ -n "$problems" ] || exit 0
msg="The report is not finished (only the formats of this report are checked):$problems
Do not fill gaps just to pass this check. If something needs more research, do it; if it cannot be done now, tell the developer what is missing and why, then stop."
if [ "$active" = true ]; then
  echo "java-analyst: $msg" >&2
  exit 0
fi
jq -n --arg r "$msg" '{decision: "block", reason: $r}'
exit 0

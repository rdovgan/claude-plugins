#!/usr/bin/env bash
# Stop: an analysis started in this session must be complete (all documents, no placeholders, a flow chart,
# numbered requirements referenced by the findings and the guide, a confirmed understanding).
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
while IFS= read -r f; do
  d="${f#"$out"/}"; d="${d%%/*}"
  printf '%s\n' "$d"
done < <(find "$out" -type f -newer "$marker" 2>/dev/null) | sort -u > "$(ja_data_dir)/touched.$sid"

while IFS= read -r d; do
  [ -n "$d" ] || continue
  dir="$out/$d"
  for doc in $(ja_docs); do
    [ -f "$dir/$doc" ] || { problems="$problems
- $d/$doc is missing"; continue; }
    grep -q '{{' "$dir/$doc" && problems="$problems
- $d/$doc still has {{placeholders}}"
  done
  [ -f "$dir/01-research.md" ] && ! grep -q '^## Sources' "$dir/01-research.md" && problems="$problems
- $d/01-research.md has no Sources section: list the Jira tickets and Confluence pages that were read, and what was not"
  [ -f "$dir/03-flows.md" ] && ! grep -q '^```mermaid' "$dir/03-flows.md" && problems="$problems
- $d/03-flows.md has no mermaid diagram"
  [ -f "$dir/01-research.md" ] && ! grep -qE '^- \*\*R[0-9]+\*\*' "$dir/01-research.md" && problems="$problems
- $d/01-research.md has no numbered requirements (R1, R2, ...) taken from the ticket and Confluence"
  [ -f "$dir/02-interview.md" ] && ! grep -q '^## Understanding confirmed' "$dir/02-interview.md" && problems="$problems
- $d/02-interview.md does not record that the developer confirmed your understanding of the task"
  for doc in 04-findings.md 06-implementation-guide.md; do
    [ -f "$dir/$doc" ] && ! grep -qE '\bR[0-9]+\b' "$dir/$doc" && problems="$problems
- $d/$doc does not refer to any requirement R*: show which requirements it covers"
  done
done < "$(ja_data_dir)/touched.$sid"

[ -n "$problems" ] || exit 0
msg="The analysis is not finished:$problems
Do not fill gaps just to pass this check. If something needs more research, do it; if it cannot be done now, tell the developer what is missing and why, then stop."
if [ "$active" = true ]; then
  echo "java-analyst: $msg" >&2
  exit 0
fi
jq -n --arg r "$msg" '{decision: "block", reason: $r}'
exit 0

#!/usr/bin/env bash
# Stop: a QA analysis started in this session must be complete (all documents, no placeholders, a flow chart,
# numbered requirements referenced by the findings and the test scenarios, a confirmed understanding, an answer,
# and no program code in the QA-facing documents).
# Blocks once; with stop_hook_active it only warns, so there is no loop.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qa_require_jq
qa_off && exit 0

input="$(cat)"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
active="$(jq -r '.stop_hook_active // false' <<<"$input")"
out="$(qa_out_root)"
marker="$(qa_data_dir)/start.$sid"
[ -d "$out" ] && [ -f "$marker" ] || exit 0

problems=""
while IFS= read -r f; do
  d="${f#"$out"/}"; d="${d%%/*}"
  printf '%s\n' "$d"
done < <(find "$out" -type f -newer "$marker" 2>/dev/null) | sort -u > "$(qa_data_dir)/touched.$sid"

while IFS= read -r d; do
  [ -n "$d" ] || continue
  dir="$out/$d"
  for doc in $(qa_docs); do
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
- $d/01-research.md has no numbered requirements or expected behaviour (R1, R2, ...) taken from the ticket and Confluence"
  [ -f "$dir/02-interview.md" ] && ! grep -q '^## Understanding confirmed' "$dir/02-interview.md" && problems="$problems
- $d/02-interview.md does not record that the user confirmed your understanding of the task"
  [ -f "$dir/00-README.md" ] && ! grep -q '^## Answer' "$dir/00-README.md" && problems="$problems
- $d/00-README.md has no Answer section: state the verdict in plain language"
  [ -f "$dir/05-test-scenarios.md" ] && ! grep -qE '^### T[0-9]+' "$dir/05-test-scenarios.md" && problems="$problems
- $d/05-test-scenarios.md has no numbered test scenarios (### T1, ### T2, ...)"
  for doc in 04-findings.md 05-test-scenarios.md; do
    [ -f "$dir/$doc" ] && ! grep -qE '\bR[0-9]+\b' "$dir/$doc" && problems="$problems
- $d/$doc does not refer to any requirement R*: show which requirements it covers"
  done
  # QA documents explain behaviour in words: no program code. Mermaid, SQL check queries, log lines,
  # request/response bodies and shell commands to reproduce are allowed.
  for doc in 00-README.md 03-flows.md 04-findings.md 05-test-scenarios.md 06-ticket-notes.md; do
    [ -f "$dir/$doc" ] || continue
    langs="$(grep -oE '^[[:space:]]*```[A-Za-z+#-]+' "$dir/$doc" | sed -E 's/^[[:space:]]*```//' | tr '[:upper:]' '[:lower:]' \
      | grep -xE 'java|kotlin|kt|groovy|scala|javascript|js|jsx|typescript|ts|tsx|python|py|php|go|golang|ruby|rb|c|cpp|c\+\+|cs|csharp|c#|rust|rs|swift|diff|patch' | sort -u | tr '\n' ' ')"
    [ -n "$langs" ] && problems="$problems
- $d/$doc contains program code (${langs% }): QA documents describe behaviour in words; name the place in the technical references instead of quoting code"
  done
done < "$(qa_data_dir)/touched.$sid"

[ -n "$problems" ] || exit 0
msg="The analysis is not finished:$problems
Do not fill gaps just to pass this check. If something needs more research, do it; if it cannot be done now, tell the user what is missing and why, then stop."
if [ "$active" = true ]; then
  echo "qa-analyst: $msg" >&2
  exit 0
fi
jq -n --arg r "$msg" '{decision: "block", reason: $r}'
exit 0

#!/usr/bin/env bash
# Stop: checks the report written in this session, and only the formats that report was asked for.
# A conversation (answers in chat, notes.md, 01-research.md, 02-interview.md) is never checked.
# Which formats a report has: .claude/qa-analysis/<task>/.formats, written by analysis-report when it starts
# (the selected formats or the flags of the run). Without it (a single format through /qa-analyst:present),
# the formats whose files were written in this session.
# Blocks once; with stop_hook_active it only warns, so there is no loop.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
# shellcheck source=glossary.sh
. "$(dirname "$0")/glossary.sh"
qa_require_jq
qa_off && exit 0

input="$(cat)"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
active="$(jq -r '.stop_hook_active // false' <<<"$input")"
out="$(qa_out_root)"
marker="$(qa_data_dir)/start.$sid"
[ -d "$out" ] && [ -f "$marker" ] || exit 0

problems=""
add() { problems="$problems
- $1"; }

for dir in "$out"/*/; do
  dir="${dir%/}"; d="${dir##*/}"
  [ -d "$dir" ] || continue
  if [ -f "$dir/.formats" ] && [ "$dir/.formats" -nt "$marker" ]; then
    fmts="$(qa_format_order "$(cat "$dir/.formats")")"
  else
    fmts="$(find "$dir" -maxdepth 1 -type f -newer "$marker" 2>/dev/null | while IFS= read -r f; do qa_file_format "${f##*/}"; done)"
    fmts="$(qa_format_order "$(printf '%s ' $fmts)")"
  fi
  [ -n "$fmts" ] || continue

  for fmt in $fmts; do
    for file in $(qa_format_files "$fmt"); do
      if [ ! -f "$dir/$file" ]; then
        # logs: a task without logs gets no file.
        if [ "$fmt" = logs ] && ! cat "$dir/notes.md" "$dir/01-research.md" 2>/dev/null | grep -qiE '\.log|log file|logs?:'; then continue; fi
        add "$d/$file is missing: the $fmt format is in this report; $([ "$fmt" = summary ] && printf 'write it (analysis-report, the summary format)' || printf 'run the present-%s skill' "$fmt")"
        continue
      fi
      grep -q '{{' "$dir/$file" && add "$d/$file still has {{placeholders}}"
    done
    case "$fmt" in
      summary)
        [ -f "$dir/00-README.md" ] && ! grep -q '^## Answer' "$dir/00-README.md" && add "$d/00-README.md has no Answer section: state the verdict in plain language"
        [ -f "$dir/03-flows.md" ] && ! grep -q '^```mermaid' "$dir/03-flows.md" && add "$d/03-flows.md has no mermaid diagram"
        [ -f "$dir/04-findings.md" ] && ! grep -qE '\bR[0-9]+\b' "$dir/04-findings.md" && add "$d/04-findings.md does not refer to any requirement R*: show which requirements it covers" ;;
      tests)
        tc="$dir/05-test-cases.md"
        if [ -f "$tc" ]; then
          ncases="$(grep -cE '^### TC-[0-9]+' "$tc")"
          nsteps="$(grep -cE '^\|[[:space:]]*#[[:space:]]*\|' "$tc")"
          if [ "$ncases" -eq 0 ]; then add "$d/05-test-cases.md has no numbered test cases (### TC-1, ### TC-2, ...)"
          elif [ "$nsteps" -lt "$ncases" ]; then add "$d/05-test-cases.md: $ncases test cases but $nsteps steps tables; every case needs its '| # | Step | Expected result |' table"; fi
          grep -qE '\bR[0-9]+\b' "$tc" || add "$d/05-test-cases.md does not refer to any requirement R*: show which requirements it covers"
        fi ;;
      impact|decision|logs|regression)
        file="$dir/$(qa_format_files "$fmt")"
        [ -f "$file" ] || continue
        grep -q '^## Conclusions' "$file" || add "$d/${file##*/} has no '## Conclusions' section: explain what the data means"
        grep -qE '^\|.*\|' "$file" || add "$d/${file##*/} has no table with the data"
        [ "$fmt" = impact ] && ! grep -q '^```sql' "$file" && ! grep -q '^## Limits' "$file" && add "$d/${file##*/} has no SELECT behind its numbers ('## How to check'), and no '## Limits' saying why"
        [ "$fmt" = decision ] && ! grep -qE '\bR[0-9]+\b' "$file" && add "$d/${file##*/} does not refer to any requirement R*: every expected result comes from one"
        [ "$fmt" = regression ] && ! grep -qE '^- \[ \]' "$file" && add "$d/${file##*/} has no checklist (- [ ] ...)" ;;
    esac
    # QA documents explain behaviour in words: no program code. Mermaid, SQL check queries, log lines,
    # request/response bodies and shell commands to reproduce are allowed.
    for file in $(qa_format_files "$fmt"); do
      case "$file" in *.md) ;; *) continue ;; esac
      [ -f "$dir/$file" ] || continue
      langs="$(grep -oE '^[[:space:]]*```[A-Za-z+#-]+' "$dir/$file" | sed -E 's/^[[:space:]]*```//' | tr '[:upper:]' '[:lower:]' \
        | grep -xE 'java|kotlin|kt|groovy|scala|javascript|js|jsx|typescript|ts|tsx|python|py|php|go|golang|ruby|rb|c|cpp|c\+\+|cs|csharp|c#|rust|rs|swift|diff|patch' | sort -u | tr '\n' ' ')"
      [ -n "$langs" ] && add "$d/$file contains program code (${langs% }): QA documents describe behaviour in words; name the place in the technical references instead of quoting code"
    done
  done
  # Team terms (D-49): no translation from the glossary's "avoid" column in the files of this report.
  files=()
  for fmt in $fmts; do
    for file in $(qa_format_files "$fmt"); do
      case "$file" in *.html) continue ;; esac
      [ -f "$dir/$file" ] && files+=("$dir/$file")
    done
  done
  while IFS= read -r t; do
    [ -n "$t" ] && add "${t#"$out"/} (glossary)"
  done < <(gl_check ${files[@]+"${files[@]}"} -- "${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}" "$(qa_workspace_dir)" "$(qa_project_dir)/.claude/glossary.md")
done

[ -n "$problems" ] || exit 0
msg="The report is not finished (only the formats of this report are checked):$problems
Do not fill gaps just to pass this check. If something needs more research, do it; if it cannot be done now, tell the user what is missing and why, then stop."
if [ "$active" = true ]; then
  echo "qa-analyst: $msg" >&2
  exit 0
fi
jq -n --arg r "$msg" '{decision: "block", reason: $r}'
exit 0

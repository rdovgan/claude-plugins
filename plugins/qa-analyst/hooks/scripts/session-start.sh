#!/usr/bin/env bash
# SessionStart: stdout goes into the agent's context.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qa_require_jq

sid="$(jq -r '.session_id // "unknown"' <<<"$(cat)")"
root="$(qa_project_dir)"
data="$(qa_data_dir)"
cd "$root" 2>/dev/null || exit 0
: > "$data/start.$sid"   # session start marker for verify-analysis.sh

if qa_off; then
  echo "qa-analyst: QA_ANALYST_OFF=1, guards are disabled in this session."
  exit 0
fi

echo "qa-analyst: QA ANALYSIS mode. The user is a QA engineer: analyse Jira tickets, Confluence requirements, logs, the database and the code, and answer in plain language a non-developer can act on (what happens, is it a bug, what to test, what to write in the ticket). No code examples and no fix proposals in the answers; code is evidence you read, not something you write. Never change source code, tests, build files (pom.xml, package.json, ...) or application configs in any repository. You MAY create and update documentation (.md/.txt/.rst/.adoc/.puml/.mmd), CLAUDE.md, .gitignore, .mcp.json and anything under .claude/ in the project; analysis documents go to .claude/qa-analysis/<task>/. First-time setup: /qa-analyst:setup."
echo "qa-analyst: CONVERSATION FIRST. Most prompts are questions and clarifications about a task: answer them in chat, reading only the sources the question needs; no report documents, no full workflow. Keep a short running record per task in .claude/qa-analysis/<task>/notes.md (sections: Understanding, Requirements as - **R1** ..., Facts with their source, Decisions, Open questions; a few lines per update, no template). A REPORT is written only when the user asks for it: the REPORT button in the formats row, /qa-analyst:report [task] [--format ...], or words like 'make the report', 'summary', 'друкуй звіт', 'оформи результат', 'we are done'. Then run the analysis-report skill, which writes only the formats of that report. /qa-analyst:analyze <task> is the full run in one go (research, interview, report) for when the user asks for it."
for other in java-developer java-team java-analyst qa-docs; do
  if qa_plugin_enabled "$other"; then
    echo "qa-analyst: CONFLICT: $other is also enabled here. The plugins must not run together: their hooks and guards contradict each other (qa-analyst blocks code changes, the other plugin's flow or write rules block the QA analysis documents) and a bare ticket key could start either workflow. Tell the user in your first reply, once, to disable one of them (/plugin, or enabledPlugins in .claude/settings.json). Until then follow qa-analyst only: analysis, no code changes."
  fi
done

# First-run hint (shown in the first 3 sessions until onboarding is done).
if [ ! -f "$data/onboarded" ]; then
  n="$(cat "$data/hint.count" 2>/dev/null || echo 0)"
  if [ "$n" -lt 3 ] 2>/dev/null; then
    echo "$((n + 1))" > "$data/hint.count"
    echo "qa-analyst: this user has not done onboarding yet. Mention once, in one line, at the start of your first reply: /qa-analyst:setup checks the project and shows exactly which settings to add; /qa-analyst:onboarding is a 3-minute tour."
  fi
fi

# Keep the output out of git without touching the tracked .gitignore.
if [ -d "$root/.git" ]; then
  ex="$root/.git/info/exclude"
  mkdir -p "$(dirname "$ex")" 2>/dev/null
  grep -qxF '.claude/qa-analysis/' "$ex" 2>/dev/null || printf '.claude/qa-analysis/\n' >> "$ex" 2>/dev/null
fi

fmts="$(qa_formats | tr '\n' ' ')"; fmts="${fmts% }"
if [ -n "$fmts" ]; then
  echo "qa-analyst: report formats (selected in the formats row or the plugin options): ${fmts// /, }. They apply only when a report is written."
else
  echo "qa-analyst: report formats: none selected. When the user asks for a report, ask which formats with AskUserQuestion (summary, tests, impact, decision, logs, regression, confluence, visual)."
fi
command -v git >/dev/null 2>&1 && echo "qa-analyst: branch $(git symbolic-ref --short -q HEAD 2>/dev/null || echo detached)"

out="$(qa_out_root)"
if [ -d "$out" ]; then
  list="$(cd "$out" && ls -1d -- */ 2>/dev/null | tr -d / | head -n 20)"
  [ -n "$list" ] && echo "qa-analyst: existing analyses in .claude/qa-analysis/: $(printf '%s' "$list" | tr '\n' ' ') - continue one instead of starting over if the task matches."
fi

ws="$(qa_workspace_dir)"
# Team terms (D-49): the rule and the glossary.
. "$(dirname "$0")/glossary.sh"
gl_context qa-analyst "$root/.claude/glossary.md" "${CLAUDE_PLUGIN_ROOT}" "$ws" "$root/.claude/glossary.md"
echo "qa-analyst: workspace $ws (all repositories are siblings of this project)."
main="${QA_ANALYST_MAIN_PROJECT:-}"
if [ -n "$main" ] && [ "$(basename "$root")" != "$main" ] && [ -d "$ws/$main" ]; then
  echo "qa-analyst: $main (../$main) is the main project: the core business logic lives there. Check how $main uses anything this task touches and say so in the findings."
fi
curated="${QA_ANALYST_MODULES_FILE:-$ws/modules.md}"
[ -f "$curated" ] || curated="${CLAUDE_PLUGIN_ROOT}/reference/modules.md"
[ -f "$curated" ] && echo "qa-analyst: module map with notes: $curated - read it before researching a task that may span repositories."
if [ -x "${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh" ]; then
  scan="$("${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh" 2>/dev/null | head -n 40)"
  if [ -n "$scan" ]; then
    echo "qa-analyst: Maven repositories next to this project (branch, artifact, which others they mention in pom.xml):"
    printf '%s\n' "$scan" | sed 's/^/  /'
  fi
fi
exit 0

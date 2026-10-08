#!/usr/bin/env bash
# SessionStart: stdout goes into the agent's context.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ja_require_jq

sid="$(jq -r '.session_id // "unknown"' <<<"$(cat)")"
root="$(ja_project_dir)"
data="$(ja_data_dir)"
cd "$root" 2>/dev/null || exit 0
: > "$data/start.$sid"   # session start marker for verify-analysis.sh

if ja_off; then
  echo "java-analyst: JAVA_ANALYST_OFF=1, guards are disabled in this session."
  exit 0
fi

echo "java-analyst: ANALYSIS mode. Never change source code, tests, build files (pom.xml, package.json, ...) or application configs in any repository. You MAY create and update documentation (.md/.txt/.rst/.adoc/.puml/.mmd), CLAUDE.md, .gitignore, .mcp.json and anything under .claude/ in the project; analysis documents go to .claude/analysis/<task>/. Start a task with /java-analyst:analyze <Jira key, link or description>; first-time setup: /java-analyst:setup."
if ja_plugin_enabled java-developer || ja_plugin_enabled java-team; then
  echo "java-analyst: CONFLICT: java-developer is also enabled here. The two plugins must not run together: the read-only guards of java-analyst block the implementation flow of java-developer (specs, code, tests, commits) and a bare ticket key could start either one. Tell the developer in your first reply, once, to disable one of them (/plugin, or enabledPlugins in .claude/settings.json). Until then follow java-analyst only: analysis, no code changes."
fi

# First-run hint (shown in the first 3 sessions until onboarding is done).
if [ ! -f "$data/onboarded" ]; then
  n="$(cat "$data/hint.count" 2>/dev/null || echo 0)"
  if [ "$n" -lt 3 ] 2>/dev/null; then
    echo "$((n + 1))" > "$data/hint.count"
    echo "java-analyst: this developer has not done onboarding yet. Mention once, in one line, at the start of your first reply: /java-analyst:setup checks the project and shows exactly which settings to add; /java-analyst:onboarding is a 3-minute tour."
  fi
fi

# Keep the output out of git without touching the tracked .gitignore.
if [ -d "$root/.git" ]; then
  ex="$root/.git/info/exclude"
  mkdir -p "$(dirname "$ex")" 2>/dev/null
  grep -qxF '.claude/analysis/' "$ex" 2>/dev/null || printf '.claude/analysis/\n' >> "$ex" 2>/dev/null
fi

command -v git >/dev/null 2>&1 && echo "java-analyst: branch $(git symbolic-ref --short -q HEAD 2>/dev/null || echo detached)"

out="$(ja_out_root)"
if [ -d "$out" ]; then
  list="$(cd "$out" && ls -1d -- */ 2>/dev/null | tr -d / | head -n 20)"
  [ -n "$list" ] && echo "java-analyst: existing analyses in .claude/analysis/: $(printf '%s' "$list" | tr '\n' ' ') - continue one instead of starting over if the task matches."
fi

ws="$(ja_workspace_dir)"
echo "java-analyst: workspace $ws (all repositories are siblings of this project)."
main="${JAVA_ANALYST_MAIN_PROJECT:-}"
if [ -n "$main" ] \&\& [ "$(basename "$root")" != "$main" ] \&\& [ -d "$ws/$main" ]; then
  echo "java-analyst: $main (../$main) is the main project: the core business logic lives there. Check how $main uses anything this task touches and say so in the findings."
fi
curated="${JAVA_ANALYST_MODULES_FILE:-$ws/modules.md}"
[ -f "$curated" ] || curated="${CLAUDE_PLUGIN_ROOT}/reference/modules.md"
[ -f "$curated" ] && echo "java-analyst: module map with notes: $curated - read it before researching a task that may span repositories."
if [ -x "${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh" ]; then
  scan="$("${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh" 2>/dev/null | head -n 40)"
  if [ -n "$scan" ]; then
    echo "java-analyst: Maven repositories next to this project (branch, artifact, which others they mention in pom.xml):"
    printf '%s\n' "$scan" | sed 's/^/  /'
  fi
fi
exit 0

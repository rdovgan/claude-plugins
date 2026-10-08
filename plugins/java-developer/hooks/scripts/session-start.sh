#!/usr/bin/env bash
# SessionStart: stdout goes into the agent's context.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

sid="$(jq -r '.session_id // "unknown"' <<<"$(cat)")"
root="$(jt_project_dir)"
data="$(jt_data_dir)"
cd "$root" 2>/dev/null || exit 0

: > "$data/start.$sid"   # session start marker for verify.sh

# First-run hint (shown in the first 3 sessions until onboarding is done).
if [ ! -f "$data/onboarded" ]; then
  n="$(cat "$data/hint.count" 2>/dev/null || echo 0)"
  if [ "$n" -lt 3 ] 2>/dev/null; then
    echo "$((n + 1))" > "$data/hint.count"
    echo "java-developer: this developer has not done onboarding yet. Mention once, in one line, at the start of your first reply: type /java-developer:onboarding for a 5-minute tour, or /java-developer:help for a cheat sheet."
  fi
fi

if jt_plugin_enabled java-analyst; then
  echo "java-developer: CONFLICT: java-analyst is also enabled here. The two plugins must not run together: the read-only guards of java-analyst block the implementation flow (specs, code, tests, commits) and a bare ticket key could start either one. Tell the developer in your first reply, once, to disable one of them (/plugin, or enabledPlugins in .claude/settings.json)."
fi

command -v git >/dev/null 2>&1 || exit 0
branch="$(jt_branch)"
key="$(jt_jira_key "$branch")"
echo "java-developer: branch ${branch:-detached}"
[ -n "$key" ] && echo "java-developer: Jira key from the branch name: $key"
if [ -n "$key" ] && [ -f ".claude/specs/$key.md" ]; then
  echo "java-developer: task spec: .claude/specs/$key.md - read it and continue from it."
  spec=".claude/specs/$key.md"
  jt_spec_ticks "$spec" > "$data/specticks.$sid"
  prog="$(jt_spec_progress "$spec")"
  nums="${prog%%|*}"; nxt="${prog#*|}"
  set -- $nums
  if [ "${2:-0}" -gt 0 ] 2>/dev/null; then
    if [ -n "$nxt" ]; then
      echo "java-developer: spec progress: $1 of $2 steps done. Next: $nxt ($3 criteria open). Continue from it; tick criteria in the spec as you verify them."
    else
      echo "java-developer: spec progress: all $2 steps done. Next: self-check against the criteria, then /java-developer:review."
    fi
  fi
elif [ -n "$key" ]; then
  echo "java-developer: no spec for $key yet - start with task-research."
fi

# Workspace map: sibling repositories, curated notes, live scan of poms.
ws="$(jt_workspace_dir)"
echo "java-developer: workspace $ws (all repositories are siblings of this project)."
main="${JAVA_TEAM_MAIN_PROJECT:-}"
if [ -n "$main" ] && [ "$(basename "$root")" != "$main" ] && [ -d "$ws/$main" ]; then
  echo "java-developer: $main (../$main) is the main project: the core business logic lives there. Before changing a public method, event or contract in this repository, check how $main uses it."
fi
curated="${JAVA_TEAM_MODULES_FILE:-$ws/modules.md}"
[ -f "$curated" ] || curated="${CLAUDE_PLUGIN_ROOT}/reference/modules.md"
[ -f "$curated" ] && echo "java-developer: module map with notes: $curated - read it before researching a task that may span repositories."
if [ -x "${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh" ]; then
  scan="$("${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh" 2>/dev/null | head -n 40)"
  if [ -n "$scan" ]; then
    echo "java-developer: Maven repositories next to this project (branch, artifact, which others they mention in pom.xml):"
    printf '%s\n' "$scan" | sed 's/^/  /'
  fi
fi

id="$(printf '%s' "$root" | cksum | cut -d' ' -f1)"
if [ -f "$data/snapshot.$id.txt" ]; then
  echo "java-developer: latest state snapshot:"
  sed 's/^/  /' "$data/snapshot.$id.txt"
fi
exit 0

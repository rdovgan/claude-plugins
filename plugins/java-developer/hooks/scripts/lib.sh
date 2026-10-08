#!/usr/bin/env bash
# Shared helpers for java-developer hooks. Sourced via `source`.
# Dependencies: bash, jq, git, mvn. Contents of secret files are never read here.

# Without jq a hook only warns and exits with code 0.
jt_require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "java-developer: jq not found, hook skipped" >&2
    exit 0
  }
}

jt_project_dir() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }

jt_data_dir() {
  local d="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/java-developer}"
  mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}

# Jira key from a string (first match), format ABC-123.
jt_jira_key() { printf '%s' "$1" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -n1; }

# Claude/Anthropic attribution in text (stdin or $1). Exit 0 = found.
jt_has_attribution() {
  local re='co-authored-by:[[:space:]]*claude|claude-session:|generated with.*claude|noreply@anthropic\.com|🤖 generated'
  if [ $# -gt 0 ]; then printf '%s' "$1" | grep -qiE "$re"; else grep -qiE "$re"; fi
}

# Protected branches: main and master, plus any listed (space-separated) in JAVA_TEAM_PROTECTED_BRANCHES.
jt_protected_branch() {
  local b
  for b in main master ${JAVA_TEAM_PROTECTED_BRANCHES:-}; do [ "$1" = "$b" ] && return 0; done
  return 1
}
jt_branch() { git -C "$(jt_project_dir)" symbolic-ref --short -q HEAD 2>/dev/null; }

# Sensitive path by name (contents are not read). Exit 0 = sensitive.
jt_is_sensitive() {
  local p="${1%/}" b
  b="${p##*/}"
  case "$b" in
    application-test*|application-local*) return 1 ;;
    .env|.env.*|application-prod*|application-stage*|credentials*) return 0 ;;
    *.pem|*.key|*.jks|*.p12|*.keystore) return 0 ;;
  esac
  case "$p" in
    */secrets/*|secrets/*|*/secrets|secrets) return 0 ;;
    */.ssh/*|*/.aws/*|*/.m2/settings.xml|~/.ssh/*|~/.aws/*|~/.m2/settings.xml) return 0 ;;
  esac
  return 1
}

# Workspace = the folder that holds all repositories (the parent of the repo Claude was started in).
# Override with JAVA_TEAM_WORKSPACE.
jt_workspace_dir() { printf '%s' "${JAVA_TEAM_WORKSPACE:-$(dirname "$(jt_project_dir)")}"; }

# Git repositories in the workspace (the project repo first, then its siblings), one path per line.
jt_workspace_repos() {
  local root ws d
  root="$(jt_project_dir)"
  ws="$(jt_workspace_dir)"
  [ -e "$root/.git" ] && printf '%s\n' "$root"
  for d in "$ws"/*/; do
    d="${d%/}"
    [ "$d" = "$root" ] && continue
    [ -e "$d/.git" ] && printf '%s\n' "$d"
  done
}

# Root of the git repository that contains the given path.
jt_repo_root() {
  local d
  d="$(dirname "$1")"
  [ -d "$d" ] || return 1
  git -C "$d" rev-parse --show-toplevel 2>/dev/null
}

# Nearest directory with pom.xml, walking up from the file to the root of its git repository
# (or the workspace root). Works for files in any repository of the workspace.
jt_module_dir() {
  local d ws
  ws="$(jt_workspace_dir)"
  d="$(dirname "$1")"
  while [ "$d" != "/" ] && [ "$d" != "$ws" ]; do
    [ -f "$d/pom.xml" ] && { printf '%s' "$d"; return 0; }
    [ -e "$d/.git" ] && return 1
    d="$(dirname "$d")"
  done
  return 1
}

# ./mvnw of the repository in JT_REPO_ROOT (default: the project), otherwise mvn.
jt_mvn() {
  local root
  root="${JT_REPO_ROOT:-$(jt_project_dir)}"
  if [ -x "$root/mvnw" ]; then "$root/mvnw" "$@"; else mvn "$@"; fi
}

# Spec file of the current task: .claude/specs/<Jira key from the branch>.md. Exit 0 and prints the path if it exists.
jt_spec_file() {
  local key f
  key="$(jt_jira_key "$(jt_branch)")"
  [ -n "$key" ] || return 1
  f="$(jt_project_dir)/.claude/specs/$key.md"
  [ -f "$f" ] && printf '%s' "$f"
}

# Checked criteria in a spec file.
jt_spec_ticks() { grep -cE '^[[:space:]]*- \[[xX]\]' "$1" 2>/dev/null || true; }

# Spec progress: prints "<steps done> <steps total> <open criteria of the next step>|<next step heading>".
# A step is done when it has no unchecked criteria.
jt_spec_progress() {
  awk '
    function fin() {
      if (in_step) {
        total++
        if (open > 0) { if (nxt == "") { nxt = name; nxt_open = open } } else done++
      }
      in_step = 0
    }
    /^### Step/ { fin(); in_step = 1; name = $0; sub(/^### /, "", name); open = 0; next }
    /^## /      { fin(); next }
    in_step && /^[[:space:]]*- \[ \]/ { open++ }
    END { fin(); printf "%d %d %d|%s\n", done, total, nxt_open, nxt }
  ' "$1"
}

# Exit 0 if a plugin named $1 is enabled in user, project or local settings (any marketplace).
jt_plugin_enabled() {
  local f
  for f in "$HOME/.claude/settings.json" "$(jt_project_dir)/.claude/settings.json" "$(jt_project_dir)/.claude/settings.local.json"; do
    [ -f "$f" ] || continue
    jq -e --arg n "$1" '(.enabledPlugins // {}) | to_entries | any(.value == true and (.key | startswith($n + "@")))' "$f" >/dev/null 2>&1 && return 0
  done
  return 1
}

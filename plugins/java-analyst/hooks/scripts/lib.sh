#!/usr/bin/env bash
# Shared helpers for java-analyst hooks. Sourced via `source`.
# Dependencies: bash, jq, git. Contents of secret files are never read here.
# JAVA_ANALYST_OFF=1 switches every guard off (for work outside this plugin's purpose).

# Without jq the guards cannot work. The plugin must not run unprotected, so this fails closed.
ja_require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "java-analyst: jq not found; install it (brew install jq). Without it the read-only guard cannot work, so tool calls are blocked." >&2
    exit 2
  }
}

ja_off() { [ "${JAVA_ANALYST_OFF:-}" = 1 ]; }

ja_project_dir() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }

ja_data_dir() {
  local d="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/java-analyst}"
  mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}

# Output folder of all analyses; the only place where this plugin may write.
ja_out_root() { printf '%s/.claude/analysis' "$(ja_project_dir)"; }

# Jira key from a string (first match), format ABC-123.
ja_jira_key() { printf '%s' "$1" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -n1; }

# Sensitive path by name (contents are not read). Exit 0 = sensitive.
ja_is_sensitive() {
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
# Override with JAVA_ANALYST_WORKSPACE.
ja_workspace_dir() { printf '%s' "${JAVA_ANALYST_WORKSPACE:-$(dirname "$(ja_project_dir)")}"; }

# Git repositories in the workspace (the project repo first, then its siblings), one path per line.
ja_workspace_repos() {
  local root ws d
  root="$(ja_project_dir)"
  ws="$(ja_workspace_dir)"
  [ -e "$root/.git" ] && printf '%s\n' "$root"
  for d in "$ws"/*/; do
    d="${d%/}"
    [ "$d" = "$root" ] && continue
    [ -e "$d/.git" ] && printf '%s\n' "$d"
  done
}

# Required documents of one analysis, in reading order.
ja_docs() {
  printf '%s\n' 00-README.md 01-research.md 02-interview.md 03-flows.md 04-findings.md 05-proposals.md 06-implementation-guide.md
}

# Resolve a path without requiring it to exist: absolute, `.` and `..` collapsed.
ja_abspath() {
  local p="$1" base="${2:-$PWD}" out="" seg
  case "$p" in "~"|"~/"*) p="$HOME${p#\~}" ;; esac
  case "$p" in /*) ;; *) p="$base/$p" ;; esac
  local IFS=/
  # shellcheck disable=SC2086
  set -- $p
  for seg in "$@"; do
    case "$seg" in
      ''|.) ;;
      ..) out="${out%/*}" ;;
      *) out="$out/$seg" ;;
    esac
  done
  printf '%s' "${out:-/}"
}

# Exit 0 if a plugin named $1 is enabled in user, project or local settings (any marketplace).
ja_plugin_enabled() {
  local f
  for f in "$HOME/.claude/settings.json" "$(ja_project_dir)/.claude/settings.json" "$(ja_project_dir)/.claude/settings.local.json"; do
    [ -f "$f" ] || continue
    jq -e --arg n "$1" '(.enabledPlugins // {}) | to_entries | any(.value == true and (.key | startswith($n + "@")))' "$f" >/dev/null 2>&1 && return 0
  done
  return 1
}

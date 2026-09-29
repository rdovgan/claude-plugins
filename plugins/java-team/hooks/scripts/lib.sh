#!/usr/bin/env bash
# Shared helpers for java-team hooks. Sourced via `source`.
# Dependencies: bash, jq, git, mvn. Contents of secret files are never read here.

# Without jq a hook only warns and exits with code 0.
jt_require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "java-team: jq not found, hook skipped" >&2
    exit 0
  }
}

jt_project_dir() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }

jt_data_dir() {
  local d="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/java-team}"
  mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}

# Jira key from a string (first match), format ABC-123.
jt_jira_key() { printf '%s' "$1" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -n1; }

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

# Nearest directory with pom.xml, walking up from the file, not above the project root.
jt_module_dir() {
  local root d
  root="$(jt_project_dir)"
  d="$(dirname "$1")"
  while [ "$d" != "/" ] && [ "${#d}" -ge "${#root}" ]; do
    [ -f "$d/pom.xml" ] && { printf '%s' "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}

# ./mvnw if the project has it, otherwise mvn.
jt_mvn() {
  local root
  root="$(jt_project_dir)"
  if [ -x "$root/mvnw" ]; then "$root/mvnw" "$@"; else mvn "$@"; fi
}

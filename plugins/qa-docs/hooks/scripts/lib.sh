#!/usr/bin/env bash
# Shared helpers for qa-docs hooks and scripts. Sourced via `source`.
# Dependencies: bash, jq, git. Contents of secret files are never read here.
# There is no switch that turns the guards off: the plugin runs on a shared server, so the guards
# must hold for every user. To work outside its purpose, disable the plugin.

# Without jq the guards cannot work. The plugin must not run unprotected, so this fails closed.
qd_require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "qa-docs: jq not found; ask the server admin to install it. Without it the guards cannot work, so tool calls are blocked." >&2
    exit 2
  }
}

qd_project_dir() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }

# Workspace root: the folder that holds all source repositories, the shared results (qa-docs/) and
# the admin files (.qa-docs/). Normally the folder Claude was started in; when it was started inside
# one repository (with the others as additionalDirectories), the parent. Override: QA_DOCS_ROOT.
qd_root() {
  local p
  if [ -n "${QA_DOCS_ROOT:-}" ]; then printf '%s' "${QA_DOCS_ROOT%/}"; return; fi
  p="$(qd_project_dir)"
  if [ -d "$p/.qa-docs" ] || [ -d "$p/qa-docs" ]; then printf '%s' "$p"; return; fi
  if [ -d "$(dirname "$p")/.qa-docs" ] || [ -d "$(dirname "$p")/qa-docs" ]; then dirname "$p"; return; fi
  printf '%s' "$p"
}

# Admin-owned files: config.env, sensitive.txt, branches.conf, sources.tsv (written by cron).
qd_admin_dir() { printf '%s/.qa-docs' "$(qd_root)"; }

# Shared results: module map, domain map, one folder per domain.
qd_out() { printf '%s/qa-docs' "$(qd_root)"; }
qd_domains() { printf '%s/qa-docs/domains' "$(qd_root)"; }

# Value of KEY from .qa-docs/config.env (KEY=value lines; the file is parsed, never sourced).
# Environment variables of the same name win.
qd_conf() {
  local key="$1" def="${2:-}" v="${!1:-}" f
  if [ -z "$v" ]; then
    f="$(qd_admin_dir)/config.env"
    [ -f "$f" ] && v="$(grep -E "^[[:space:]]*$key=" "$f" | tail -n1 | cut -d= -f2- | sed -E 's/^[[:space:]]*["'\'']?//; s/["'\'']?[[:space:]]*$//')"
  fi
  printf '%s' "${v:-$def}"
}

qd_user() { printf '%s' "${QA_DOCS_USER:-${USER:-unknown}}"; }

qd_data_dir() {
  local d="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/qa-docs-$(id -u)}"
  mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}

# Sensitive path by name (contents are not read). Exit 0 = sensitive.
# Extra glob patterns, one per line, in .qa-docs/sensitive.txt (matched against the file name and the path).
qd_is_sensitive() {
  local p="${1%/}" b lb pat f
  b="${p##*/}"
  lb="$(printf '%s' "$b" | tr '[:upper:]' '[:lower:]')"
  case "$lb" in
    application-test*|application-local*|*.example|*.sample|*.dist|*.template) return 1 ;;
    # source code is never a secret store by name (CredentialsService.java, SecretMapper.php)
    *.java|*.kt|*.groovy|*.scala|*.php|*.js|*.jsx|*.ts|*.tsx|*.vue|*.py|*.go|*.cs|*.rb|*.sql|*.md) ;;
    .env|.env.*|*.env|application-prod*|application-stage*|credentials*|*secret*|gitleaks-report*) return 0 ;;
    *.pem|*.key|*.jks|*.p12|*.pfx|*.keystore|*.truststore|id_rsa*|id_ed25519*|*.ppk) return 0 ;;
    .npmrc|.pypirc|.netrc|.pgpass|.my.cnf|.htpasswd|auth.json|wp-config.php|parameters.yml|parameters.yaml|settings.xml) return 0 ;;
  esac
  case "$p" in
    */secrets/*|secrets/*|*/secrets|secrets) return 0 ;;
    */.ssh/*|*/.aws/*|*/.gnupg/*|*/.kube/*|*/.docker/config.json|~/.ssh/*|~/.aws/*) return 0 ;;
  esac
  f="$(qd_admin_dir)/sensitive.txt"
  if [ -f "$f" ]; then
    while IFS= read -r pat; do
      pat="${pat%%#*}"; pat="$(printf '%s' "$pat" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
      [ -n "$pat" ] || continue
      # shellcheck disable=SC2053
      [[ "$b" == $pat || "$p" == $pat || "$p" == */$pat ]] && return 0
    done < "$f"
  fi
  return 1
}

# Resolve a path without requiring it to exist: absolute, `.` and `..` collapsed.
qd_abspath() {
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

# Same path with symlinked directories resolved (the file itself may not exist yet).
qd_realpath() {
  # Resolve the nearest existing ancestor, so a new folder (domains/<new-slug>/) compares like its parent.
  local dir="$1" rest=""
  while [ "$dir" != "/" ] && [ "$dir" != "." ] && [ ! -d "$dir" ]; do
    rest="/$(basename "$dir")$rest"; dir="$(dirname "$dir")"
  done
  [ -d "$dir" ] && dir="$(cd -P "$dir" && pwd)"
  [ "$dir" = "/" ] && dir=""
  printf '%s' "$dir$rest"
}

# Git repositories in the workspace root, one path per line.
qd_repos() {
  local d
  for d in "$(qd_root)"/*/; do
    d="${d%/}"
    [ -e "$d/.git" ] && printf '%s\n' "$d"
  done
}

# Domain slug of a path under qa-docs/domains/ (empty otherwise).
qd_domain_of() {
  local rel="${1#"$(qd_domains)"/}"
  [ "$rel" != "$1" ] || return 0
  printf '%s' "${rel%%/*}"
}

# Write locks: one session writes a domain (or the shared maps) at a time; results are shared,
# sessions are not. Lock names: the domain slug, or "maps" for modules.md/domains.md.
# A lock older than QA_DOCS_LOCK_MINUTES (default 120) is stale and is taken over.
# qd_lock <name> <session id>: exit 0 = this session holds the lock now; exit 1 = held by another
# session (the holder is printed).
qd_locks_dir() { printf '%s/.locks' "$(qd_out)"; }

qd_lock() {
  local name="$1" sid="$2" f now age max osid ouser oat
  f="$(qd_locks_dir)/$name.lock"
  now="$(date +%s)"
  max=$(( $(qd_conf QA_DOCS_LOCK_MINUTES 120) * 60 ))
  if [ -f "$f" ]; then
    read -r osid ouser oat < "$f"
    age=$(( now - ${oat:-0} ))
    if [ "$osid" != "$sid" ] && [ "$age" -lt "$max" ]; then
      printf '%s (since %s)' "${ouser:-?}" "$(date -r "${oat:-0}" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@${oat:-0}" '+%Y-%m-%d %H:%M' 2>/dev/null)"
      return 1
    fi
  fi
  mkdir -p "$(dirname "$f")" 2>/dev/null
  printf '%s %s %s\n' "$sid" "$(qd_user)" "$now" > "$f" 2>/dev/null
  printf '%s\n' "$name" >> "$(qd_data_dir)/locks.$sid"
  return 0
}

# Release every domain lock this session holds.
qd_unlock_all() {
  local sid="$1" list name f osid
  list="$(qd_data_dir)/locks.$sid"
  [ -f "$list" ] || return 0
  sort -u "$list" | while IFS= read -r name; do
    f="$(qd_locks_dir)/$name.lock"
    [ -f "$f" ] || continue
    read -r osid _ < "$f"
    [ "$osid" = "$sid" ] && rm -f "$f"
  done
  rm -f "$list"
}

# Current commit of each source repository as "repo<TAB>sha" lines.
qd_current_shas() {
  local r
  while IFS= read -r r; do
    printf '%s\t%s\n' "$(basename "$r")" "$(git -C "$r" rev-parse --short=12 HEAD 2>/dev/null || echo '?')"
  done < <(qd_repos)
}

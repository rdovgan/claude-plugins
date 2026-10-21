#!/usr/bin/env bash
# PreToolUse Read|Grep|Glob|Edit|Write|NotebookEdit: no secrets; reads stay in the workspace;
# writes only into qa-docs/ (documents), under a per-domain lock.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qd_require_jq

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
file="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[ -d "$cwd" ] || cwd="$(qd_project_dir)"
[ -n "$file" ] || file="$cwd"

if qd_is_sensitive "$file"; then
  echo "qa-docs: access to '$file' is blocked (secrets, prod configs, keys, personal data). Documentation never needs secret values: describe the setting by its name and where it is read in the code." >&2
  exit 2
fi

root="$(qd_root)"
[ -d "$root" ] && root="$(cd -P "$root" && pwd)"
target="$(qd_realpath "$(qd_abspath "$file" "$cwd")")"
plugin="${CLAUDE_PLUGIN_ROOT:-}"
[ -n "$plugin" ] && [ -d "$plugin" ] && plugin="$(cd -P "$plugin" && pwd)"

inside() { [ -n "$2" ] && { [ "$1" = "$2" ] || [[ "$1" == "$2"/* ]]; }; }

case "$tool" in
  Read|Grep|Glob)
    # Matching lines from every repository at once flood the context and burn the user's limit.
    if [ "$tool" = Grep ] && [ "$target" = "$root" ] && [ "$(jq -r '.tool_input.output_mode // empty' <<<"$input")" = content ]; then
      echo "qa-docs: Grep with output_mode 'content' over the whole workspace is blocked: it returns lines from every repository. Find the repositories first (output_mode 'files_with_matches', the default), then search inside one with path, for example 'core-module/src'." >&2
      exit 2
    fi
    # The workspace, the plugin itself, and Claude's own session files. Not other users' homes.
    inside "$target" "$root" && exit 0
    inside "$target" "$plugin" && exit 0
    inside "$target" "$HOME/.claude" && exit 0
    case "$target" in /tmp/claude*|/private/tmp/claude*|"${TMPDIR%/}"/claude*) exit 0 ;; esac
    echo "qa-docs: reading '$file' is blocked: it is outside the workspace ($root). Sources, maps and documents are all inside it." >&2
    exit 2 ;;
esac

out="$(qd_out)"
[ -d "$out" ] && out="$(cd -P "$out" && pwd)"
if ! inside "$target" "$out"; then
  echo "qa-docs: writing '$file' is blocked. Source repositories, .claude/ and .qa-docs/ are read-only for this plugin (the server admin owns them). Documents go to $out/: domains/<domain>/ for a domain, modules.md and domains.md for the maps." >&2
  exit 2
fi

rel="${target#"$out"/}"
lower="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"
case "$rel" in
  .locks/*) echo "qa-docs: lock files are managed by the plugin hooks; do not write them." >&2; exit 2 ;;
esac
case "$lower" in
  *.md|*.mmd|*.json|*.txt|*.csv|*.svg|*.png) ;;
  *) echo "qa-docs: writing '$file' is blocked: only documents (.md .mmd .json .txt .csv .svg .png) are kept in qa-docs/." >&2; exit 2 ;;
esac

case "$rel" in
  domains/*/*) name="${rel#domains/}"; name="${name%%/*}" ;;
  modules.md|domains.md) name="maps" ;;
  *) name="" ;;
esac
if [ -n "$name" ]; then
  case "$name" in
    *[!a-z0-9-]*|-*) echo "qa-docs: domain folder '$name' is not a valid slug: use lowercase latin letters, digits and '-' (for example 'payment-refunds')." >&2; exit 2 ;;
  esac
  if ! holder="$(qd_lock "$name" "$sid")"; then
    echo "qa-docs: '$name' is being edited in another session by $holder. Results are shared, so two sessions must not write the same domain at once. Tell the user; they can wait, work on another domain, or ask that person to finish. A lock is released when that session ends, or after $(qd_conf QA_DOCS_LOCK_MINUTES 120) minutes without writes." >&2
    exit 2
  fi
fi
exit 0

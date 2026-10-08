#!/usr/bin/env bash
# PreToolUse Read|Edit|Write|NotebookEdit: no secrets, and writes only into .claude/analysis/.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ja_require_jq
ja_off && exit 0

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
file="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // empty' <<<"$input")"
[ -n "$file" ] || exit 0

if ja_is_sensitive "$file"; then
  echo "java-analyst: access to '$file' is blocked (secrets, prod configs, personal data). Use application-local*/application-test* or ask the developer to provide the needed values." >&2
  exit 2
fi

[ "$tool" = "Read" ] && exit 0

# Writes: documentation and Claude's own files inside the project, never code. Symlinks are resolved
# so a link cannot lead out of the project.
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[ -d "$cwd" ] || cwd="$(ja_project_dir)"
target="$(ja_abspath "$file" "$cwd")"
dir="$(dirname "$target")"
[ -d "$dir" ] && dir="$(cd -P "$dir" && pwd)" && target="$dir/$(basename "$target")"
proj="$(ja_project_dir)"
[ -d "$proj" ] && proj="$(cd -P "$proj" && pwd)"

if [[ "$target" == "$proj"/* ]]; then
  rel="${target#"$proj"/}"
  base="$(basename "$target")"
  lower="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
  case "$rel" in .claude/*|.mcp.json|.gitignore) exit 0 ;; esac
  case "$base" in CLAUDE.md|CLAUDE.local.md) exit 0 ;; esac
  case "$lower" in *.md|*.mdx|*.markdown|*.txt|*.rst|*.adoc|*.puml|*.mmd|*.drawio) exit 0 ;; esac
  echo "java-analyst: writing '$file' is blocked: it is not documentation. This plugin does not change code, tests, build files or application configs. Allowed: documents (.md .mdx .txt .rst .adoc .puml .mmd .drawio), CLAUDE.md, .gitignore, .mcp.json and anything under .claude/ inside the project. Put the proposed change in .claude/analysis/<task>/05-proposals.md or 06-implementation-guide.md; the developer implements it. To work outside this plugin's purpose: JAVA_ANALYST_OFF=1." >&2
  exit 2
fi
echo "java-analyst: writing '$file' is blocked: it is outside the project directory ($proj). Documents and settings may be written only inside the project." >&2
exit 2

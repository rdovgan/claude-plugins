#!/usr/bin/env bash
# PreToolUse Read|Edit|Write|NotebookEdit: no secrets, and writes only to documentation and .claude/, never code.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qa_require_jq
qa_off && exit 0

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
file="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // empty' <<<"$input")"
[ -n "$file" ] || exit 0

if qa_is_sensitive "$file"; then
  echo "qa-analyst: access to '$file' is blocked (secrets, prod configs, personal data). Use application-local*/application-test* or ask the user to provide the needed values." >&2
  exit 2
fi

[ "$tool" = "Read" ] && exit 0

# Writes: documentation and Claude's own files inside the project, never code. Symlinks are resolved
# so a link cannot lead out of the project.
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[ -d "$cwd" ] || cwd="$(qa_project_dir)"
target="$(qa_abspath "$file" "$cwd")"
# The folder may not exist yet (a new .claude/qa-analysis/<task>/): resolve the nearest existing ancestor.
dir="$(dirname "$target")"; rest="$(basename "$target")"
while [ ! -d "$dir" ] && [ "$dir" != / ]; do rest="$(basename "$dir")/$rest"; dir="$(dirname "$dir")"; done
dir="$(cd -P "$dir" && pwd)" && target="${dir%/}/$rest"
proj="$(qa_project_dir)"
[ -d "$proj" ] && proj="$(cd -P "$proj" && pwd)"

if [[ "$target" == "$proj"/* ]]; then
  rel="${target#"$proj"/}"
  base="$(basename "$target")"
  lower="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
  case "$rel" in .claude/*|.mcp.json|.gitignore) exit 0 ;; esac
  case "$base" in CLAUDE.md|CLAUDE.local.md) exit 0 ;; esac
  case "$lower" in *.md|*.mdx|*.markdown|*.txt|*.rst|*.adoc|*.puml|*.mmd|*.drawio) exit 0 ;; esac
  echo "qa-analyst: writing '$file' is blocked: it is not documentation. This plugin does not change code, tests, build files or application configs. Allowed: documents (.md .mdx .txt .rst .adoc .puml .mmd .drawio), CLAUDE.md, .gitignore, .mcp.json and anything under .claude/ inside the project. QA analysis results go to .claude/qa-analysis/<task>/; fixes are made by developers. To work outside this plugin's purpose: QA_ANALYST_OFF=1." >&2
  exit 2
fi
echo "qa-analyst: writing '$file' is blocked: it is outside the project directory ($proj). Documents and settings may be written only inside the project." >&2
exit 2

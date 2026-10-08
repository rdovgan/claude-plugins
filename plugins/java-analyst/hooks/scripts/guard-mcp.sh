#!/usr/bin/env bash
# PreToolUse mcp__*: only read-style MCP tools. Jira/Confluence are read-only; IDE, mail, browser and
# other servers cannot be used to change code or publish anything. The plugin's own DB server may run
# SELECT-style statements only (the real guarantee is still the read-only DB user, see decisions D-05).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
ja_require_jq
ja_off && exit 0

input="$(cat)"
name="$(jq -r '.tool_name // empty' <<<"$input")"
op="${name##*__}"

case "$name" in
  mcp__plugin_java-analyst_db__*)
    sql="$(jq -r '.tool_input.sql // .tool_input.query // empty' <<<"$input")"
    lead="$(printf '%s' "$sql" | sed -E 's#/\*[^*]*\*+([^/*][^*]*\*+)*/##g; s/--[^\n]*//g' | tr -s '[:space:]' ' ' | sed -E 's/^ +//')"
    first="$(printf '%s' "$lead" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')"
    body="$(printf '%s' "$lead" | sed -E 's/;[[:space:]]*$//')"
    case "$first" in select|show|describe|desc|explain) ;; *)
      echo "java-analyst: DB statement blocked: only SELECT/SHOW/DESCRIBE/EXPLAIN are allowed." >&2; exit 2 ;;
    esac
    case "$body" in *';'*) echo "java-analyst: DB statement blocked: one statement per call." >&2; exit 2 ;; esac
    if printf '%s' "$body" | grep -qiE '(into[[:space:]]+(outfile|dumpfile)|for[[:space:]]+update|lock[[:space:]]+in[[:space:]]+share)'; then
      echo "java-analyst: DB statement blocked: writes files or takes locks." >&2; exit 2
    fi
    exit 0 ;;
esac

case "$op" in
  get*|search*|list*|read*|fetch|find*|lookup*|preview*|introspect*|atlassianUserInfo|authenticate|complete_authentication|xdebug_get*|xdebug_list*) exit 0 ;;
esac
echo "java-analyst: MCP tool '$op' is blocked. Only read-style tools (get/search/list/read/fetch/find) are allowed; nothing is created, edited or published. Results stay in local files under .claude/analysis/." >&2
exit 2

#!/usr/bin/env bash
# PreToolUse mcp__*: read-style tools only, with one exception: the plugin's own Atlassian server may
# create a page in the configured Confluence space under the configured parent, update pages that
# qa-docs exported before, and add a footer comment (the link to the updated version) on the old page
# a mirror document was made from. Nothing else is created, edited, commented or transitioned.
# Publishing itself is approved by the user: the settings template keeps these tools off the
# allow list, so Claude Code asks every time.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qd_require_jq

input="$(cat)"
name="$(jq -r '.tool_name // empty' <<<"$input")"
op="${name##*__}"
arg() { jq -r --arg k "$1" '.tool_input[$k] // empty' <<<"$input"; }

block() { echo "qa-docs: $1" >&2; exit 2; }

# Page ids qa-docs exported, from qa-docs/domains/*/meta.json (confluence.pageId and confluence.pages).
exported_ids() {
  local f
  for f in "$(qd_domains)"/*/meta.json; do
    [ -f "$f" ] && jq -r '.confluence.pageId // empty, (.confluence.pages // {} | .[]? | .pageId? // empty)' "$f" 2>/dev/null
  done | grep -v '^$'
}

# Old pages that mirror documents were made from (source.pageId of layout "mirror").
source_ids() {
  local f
  for f in "$(qd_domains)"/*/meta.json; do
    [ -f "$f" ] && jq -r 'select(.layout == "mirror") | .source.pageId // empty' "$f" 2>/dev/null
  done | grep -v '^$'
}

space="$(qd_conf QA_DOCS_CONFLUENCE_SPACE)"
space_id="$(qd_conf QA_DOCS_CONFLUENCE_SPACE_ID)"
parent="$(qd_conf QA_DOCS_CONFLUENCE_PARENT)"

case "$name" in
  mcp__plugin_qa-docs_*__createConfluencePage)
    [ -n "$space" ] && [ -n "$parent" ] || block "export is not configured: the admin must set QA_DOCS_CONFLUENCE_SPACE and QA_DOCS_CONFLUENCE_PARENT in .qa-docs/config.env."
    [ "$(arg contentType)" = blog ] && block "only pages are created, not blog posts."
    s="$(arg spaceId)"
    [ "$s" = "$space" ] || { [ -n "$space_id" ] && [ "$s" = "$space_id" ]; } || \
      block "pages are created only in space '$space' (got '${s:-none}')."
    p="$(arg parentId)"
    [ "$p" = "$parent" ] || exported_ids | grep -qxF "$p" || \
      block "pages are created only under the qa-docs parent page $parent or under a page qa-docs exported before (got '${p:-none}')."
    exit 0 ;;
  mcp__plugin_qa-docs_*__updateConfluencePage)
    p="$(arg pageId)"
    [ -n "$p" ] && exported_ids | grep -qxF "$p" || \
      block "page '${p:-none}' was not exported by qa-docs (no domains/*/meta.json has it as confluence.pageId). Only pages qa-docs created are updated; others are read-only."
    mv_parent="$(arg parentId)"; mv_space="$(arg spaceId)"
    { [ -z "$mv_parent" ] || [ "$mv_parent" = "$parent" ] || exported_ids | grep -qxF "$mv_parent"; } || block "moving a page out of the qa-docs tree is not allowed."
    { [ -z "$mv_space" ] || [ "$mv_space" = "$space" ] || [ "$mv_space" = "$space_id" ]; } || block "moving a page to another space is not allowed."
    exit 0 ;;
  mcp__plugin_qa-docs_*__createConfluenceFooterComment)
    p="$(arg pageId)"
    [ -n "$p" ] && source_ids | grep -qxF "$p" || \
      block "comments are added only on an old page a mirror document was made from (source.pageId in domains/*/meta.json with layout mirror); got '${p:-none}'."
    [ -z "$(arg parentCommentId)" ] || block "only a top-level link comment is added, not a reply."
    exit 0 ;;
esac

case "$op" in
  get*|search*|list*|read*|fetch|find*|lookup*|atlassianUserInfo|authenticate|complete_authentication) exit 0 ;;
esac
block "MCP tool '$op' is blocked. Jira and Confluence are read-only for qa-docs; the only writes are Confluence pages, and a link comment on the page a mirror was made from, through /qa-docs:export."

#!/usr/bin/env bash
# Read-only check of the workspace for onboarding: tools, admin setup, sources, maps, export settings.
# Prints statuses and the fix, never secret values.
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"

root="$(qd_root)"; admin="$(qd_admin_dir)"; out="$(qd_out)"
chk() { if command -v "$1" >/dev/null 2>&1; then echo "ok    $1"; else echo "MISS  $1 - $2"; fi; }

echo "== Tools"
chk git "required; ask the admin"
chk jq "required: without it every tool call is blocked; ask the admin"
chk "$(qd_conf QA_DOCS_MMDC mmdc)" "mermaid-cli: renders diagrams to PNG; without it documents keep the mermaid code only; ask the admin (server/README.md)"

echo "== Workspace: $root (user $(qd_user))"
n="$(qd_repos | wc -l | tr -d ' ')"
[ "$n" -gt 0 ] && echo "ok    $n source repositories" || echo "MISS  no git repositories in $root - start claude in the workspace folder"
[ -d "$admin" ] && echo "ok    admin folder .qa-docs/" || echo "MISS  $admin - the admin has not set up the server (plugins/qa-docs/server/README.md)"
if [ -f "$admin/sources.tsv" ]; then
  echo "ok    sources.tsv (last cron run: $(date -r "$admin/sources.tsv" '+%Y-%m-%d %H:%M' 2>/dev/null))"
  awk -F'\t' 'NR > 1 && $6 != "ok" { print "MISS  " $1 ": last update " $6 " - tell the admin" }' "$admin/sources.tsv"
else
  echo "MISS  sources.tsv - cron with server/update-sources.sh is not running; tell the admin"
fi
if [ -f "$root/.ignore" ]; then echo "ok    .ignore in the workspace (build output and dependencies are not searched)"
else echo "MISS  .ignore in $root - searches also go through target/, vendor/, node_modules/ and spend more of the limit; the admin copies templates/server/ignore"; fi
if [ -d "$out" ] && [ -w "$out" ]; then echo "ok    shared results folder qa-docs/ is writable"
else echo "MISS  $out is missing or not writable for $(qd_user) - the admin must create it group-writable"; fi
for m in modules.md domains.md; do
  [ -f "$out/$m" ] && echo "ok    $m" || echo "info  no $m yet - /qa-docs:map builds it"
done

echo "== Confluence export"
for k in QA_DOCS_CONFLUENCE_CLOUD QA_DOCS_CONFLUENCE_SPACE QA_DOCS_CONFLUENCE_PARENT; do
  [ -n "$(qd_conf "$k")" ] && echo "ok    $k is set" || echo "MISS  $k - the admin sets it in .qa-docs/config.env; until then documents stay local"
done

echo "== Jira and Confluence"
echo "info  cannot be checked from a script: run /mcp, pick 'jira' (plugin qa-docs), finish OAuth with your own Atlassian account"
exit 0

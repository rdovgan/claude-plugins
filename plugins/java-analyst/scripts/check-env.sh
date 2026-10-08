#!/usr/bin/env bash
# Read-only environment and project check for onboarding and setup. Prints statuses and the fix, never values.
chk() { if command -v "$1" >/dev/null 2>&1; then echo "ok    $1"; else echo "MISS  $1 - $2"; fi; }
echo "== Tools"
chk git "required"
chk jq "required, the read-only guards do not work without it: brew install jq"
echo "== Optional: database (read-only MCP 'db'; without it the db server shows 'failed' in /mcp, that is normal)"
for v in JAVA_TEAM_DB_URL JAVA_TEAM_DB_USER JAVA_TEAM_DB_PASSWORD; do
  if [ -n "${!v:-}" ]; then echo "ok    $v is set"; else echo "MISS  $v - add 'export $v=...' to ~/.zshrc (see docs/install.md), then restart claude"; fi
done
echo "== Project: $PWD"
[ -f CLAUDE.md ] && echo "ok    CLAUDE.md exists" || echo "info  no CLAUDE.md - run /init (it is allowed)"
f=.claude/settings.json
if [ -f "$f" ] && command -v jq >/dev/null 2>&1; then
  echo "ok    $f exists"
  jq -e '(.enabledPlugins // {}) | keys | any(startswith("java-analyst@"))' "$f" >/dev/null 2>&1 \
    && echo "ok    plugin enabled for the team (enabledPlugins)" || echo "MISS  enabledPlugins has no java-analyst - run /java-analyst:setup"
  jq -e '(.permissions.deny // []) | any(test("\\.env"))' "$f" >/dev/null 2>&1 \
    && echo "ok    deny rules for secrets" || echo "MISS  no deny rules for secrets - run /java-analyst:setup"
  jq -e '(.permissions.additionalDirectories // []) | length > 0' "$f" >/dev/null 2>&1 \
    && echo "ok    sibling repositories are reachable (additionalDirectories)" || echo "MISS  no additionalDirectories - other repositories cannot be read; run /java-analyst:setup"
else
  echo "MISS  $f - run /java-analyst:setup"
fi
echo "== Jira (read-only)"
echo "info  cannot be checked from a script: in Claude Code run /mcp, pick 'jira', finish OAuth with your Atlassian account"
b="$(git symbolic-ref --short -q HEAD 2>/dev/null)"; [ -n "$b" ] && echo "info  git branch: $b"
exit 0

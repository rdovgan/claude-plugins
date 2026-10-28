#!/usr/bin/env bash
# Acceptance tests for the qa-docs hooks and scripts: builds a throwaway workspace with two repositories,
# runs update-sources.sh, then feeds tool calls to the guards and checks allow (0) / block (2).
#   test-fixtures/qa-docs/test-guards.sh      prints PASS/FAIL per case, exit 1 on any failure
set -u
P="$(cd "$(dirname "$0")/../../plugins/qa-docs" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/qa-docs-test.XXXXXX")"
W="$T/ws"
mkdir -p "$T/data" "$T/origin/core" "$T/origin/web" "$W"
commit() { git add -A && git -c user.email=t@t -c user.name=t commit -qm "$1"; }

(cd "$T/origin/core" && git init -q -b main && mkdir -p src \
  && printf '<project><artifactId>core</artifactId></project>\n' > pom.xml \
  && printf 'class A {\n  int x;\n}\n' > src/A.java && commit init)
(cd "$T/origin/web" && git init -q -b master && printf '{"name":"acme/web"}\n' > composer.json && commit init)
git clone -q "$T/origin/core" "$W/core-module"
git clone -q "$T/origin/web" "$W/web"
mkdir -p "$W/.qa-docs" "$W/qa-docs"
sed -e 's/^QA_DOCS_CONFLUENCE_SPACE=$/QA_DOCS_CONFLUENCE_SPACE=QA/' -e 's/^QA_DOCS_CONFLUENCE_PARENT=$/QA_DOCS_CONFLUENCE_PARENT=1000/' \
  "$P/templates/server/config.env" > "$W/.qa-docs/config.env"

export CLAUDE_PROJECT_DIR="$W" CLAUDE_PLUGIN_ROOT="$P" CLAUDE_PLUGIN_DATA="$T/data"
fails=0
t() { # name expected-exit hook json
  local out rc
  out="$(printf '%s' "$4" | "$P/hooks/scripts/$3" 2>&1)"; rc=$?
  if [ "$rc" = "$2" ]; then echo "PASS $1"; else echo "FAIL $1 (exit $rc, expected $2): $(printf '%s' "$out" | head -c 200)"; fails=$((fails + 1)); fi
}
f() { jq -nc --arg t "$1" --arg p "$2" --arg s "${3:-s1}" --arg c "$W" '{tool_name:$t,session_id:$s,cwd:$c,tool_input:{file_path:$p}}'; }
b() { jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }
m() { jq -nc --arg n "$1" --argjson i "$2" '{tool_name:$n,tool_input:$i}'; }
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }

# cron script and scanner
"$P/server/update-sources.sh" "$W"
check "sources.tsv has both repos ok" "[ \"\$(awk -F'\t' 'NR>1 && \$6==\"ok\"' '$W/.qa-docs/sources.tsv' | wc -l | tr -d ' ')\" = 2 ]"
check "scan-modules detects php" "'$P/scripts/scan-modules.sh' | grep -q '^web	php	master'"
check "session-start prints export target" "echo '{\"session_id\":\"s0\"}' | '$P/hooks/scripts/session-start.sh' | grep -q 'space QA'"

# files: secrets and reads
t "read source" 0 guard-files.sh "$(f Read "$W/core-module/src/A.java")"
t "read env example" 0 guard-files.sh "$(f Read "$W/core-module/.env.example")"
t "read dotenv" 2 guard-files.sh "$(f Read "$W/core-module/.env")"
t "read CredentialsService.java" 0 guard-files.sh "$(f Read "$W/core-module/src/CredentialsService.java")"
t "read credentials.yml" 2 guard-files.sh "$(f Read "$W/core-module/credentials.yml")"
t "read gitleaks report" 2 guard-files.sh "$(f Read "$W/core-module/gitleaks-report.json")"
t "read outside workspace" 2 guard-files.sh "$(f Read /etc/hosts)"
t "read Claude's own files" 0 guard-files.sh "$(f Read "$HOME/.claude/x.md")"
t "grep without path" 0 guard-files.sh "$(jq -nc --arg c "$W" '{tool_name:"Grep",session_id:"s1",cwd:$c,tool_input:{pattern:"x"}}')"
t "grep content over workspace" 2 guard-files.sh "$(jq -nc --arg c "$W" '{tool_name:"Grep",session_id:"s1",cwd:$c,tool_input:{pattern:"x",output_mode:"content"}}')"
t "grep content in one repo" 0 guard-files.sh "$(jq -nc --arg c "$W" --arg p "$W/core-module" '{tool_name:"Grep",session_id:"s1",cwd:$c,tool_input:{pattern:"x",path:$p,output_mode:"content"}}')"
check "session-start prints research budget" "echo '{\"session_id\":\"s0\"}' | '$P/hooks/scripts/session-start.sh' | grep -q 'QA_DOCS_MAX_SUBFLOWS=6'"
check "check-env reports missing .ignore" "'$P/scripts/check-env.sh' | grep -q 'MISS  .ignore'"
printf 'application.properties\n' > "$W/.qa-docs/sensitive.txt"
t "read admin-listed sensitive file" 2 guard-files.sh "$(f Read "$W/core-module/src/main/resources/application.properties")"

# files: writes and locks
t "write source" 2 guard-files.sh "$(f Write "$W/core-module/src/A.java")"
t "write admin config" 2 guard-files.sh "$(f Write "$W/.qa-docs/config.env")"
t "write project settings" 2 guard-files.sh "$(f Write "$W/.claude/settings.json")"
t "write domain doc (s1)" 0 guard-files.sh "$(f Write "$W/qa-docs/domains/refunds/domain.md" s1)"
t "write same domain (s2, locked)" 2 guard-files.sh "$(f Write "$W/qa-docs/domains/refunds/00-scope.md" s2)"
t "write other domain (s2)" 0 guard-files.sh "$(f Write "$W/qa-docs/domains/payments/domain.md" s2)"
t "edit domains.md (s1)" 0 guard-files.sh "$(f Edit "$W/qa-docs/domains.md" s1)"
t "edit domains.md (s2, locked)" 2 guard-files.sh "$(f Edit "$W/qa-docs/domains.md" s2)"
t "write bad slug" 2 guard-files.sh "$(f Write "$W/qa-docs/domains/Refunds_X/domain.md" s1)"
t "write script into qa-docs" 2 guard-files.sh "$(f Write "$W/qa-docs/domains/refunds/x.sh" s1)"
t "write lock file" 2 guard-files.sh "$(f Write "$W/qa-docs/.locks/refunds.lock" s1)"
t "write through ../" 2 guard-files.sh "$(f Write "$W/qa-docs/../core-module/README.md" s1)"
echo '{"session_id":"s1"}' | "$P/hooks/scripts/session-end.sh"
t "s1 ended, s2 writes refunds" 0 guard-files.sh "$(f Write "$W/qa-docs/domains/refunds/00-scope.md" s2)"

# bash
t "bash grep" 0 guard-bash.sh "$(b "grep -rn Refund $W/core-module")"
t "bash git -C log" 0 guard-bash.sh "$(b "git -C $W/core-module log --oneline -5")"
t "bash plugin script" 0 guard-bash.sh "$(b "$P/scripts/check-refs.sh $W/qa-docs")"
t "bash admin script" 2 guard-bash.sh "$(b "$P/server/update-sources.sh $W")"
t "bash plugin script via ../" 2 guard-bash.sh "$(b "$P/scripts/../server/update-sources.sh $W")"
t "bash redirect" 2 guard-bash.sh "$(b "echo x > $W/core-module/a")"
t "bash git pull" 2 guard-bash.sh "$(b "git -C $W/core-module pull")"
t "bash php" 2 guard-bash.sh "$(b "php artisan migrate")"

# mcp
t "jira read" 0 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__getJiraIssue '{}')"
t "jira comment" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__addCommentToJiraIssue '{}')"
t "create page in target" 0 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluencePage '{"spaceId":"QA","parentId":"1000","body":"x"}')"
t "create page, other space" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluencePage '{"spaceId":"ENG","parentId":"1000","body":"x"}')"
t "create page, other parent" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluencePage '{"spaceId":"QA","parentId":"5","body":"x"}')"
t "update unknown page" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__updateConfluencePage '{"pageId":"77","body":"x"}')"
mkdir -p "$W/qa-docs/domains/refunds"
echo '{"confluence":{"pageId":"77"}}' > "$W/qa-docs/domains/refunds/meta.json"
t "update exported page" 0 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__updateConfluencePage '{"pageId":"77","body":"x"}')"
t "update moves page to other space" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__updateConfluencePage '{"pageId":"77","spaceId":"ENG","body":"x"}')"
t "create via another Atlassian server" 2 guard-mcp.sh "$(m mcp__claude_ai_Atlassian_Rovo__createConfluencePage '{"spaceId":"QA","parentId":"1000"}')"
t "send mail" 2 guard-mcp.sh "$(m mcp__claude_ai_Gmail__send_message '{}')"

# reference check and stop hook
printf '# R\n\n- ok `core-module/src/A.java:2`\n- past end `core-module/src/A.java:99`\n- missing `core-module/src/B.java`\n- doc link `work/plan.md`\n' > "$W/qa-docs/domains/refunds/domain.md"
out="$("$P/scripts/check-refs.sh" "$W/qa-docs/domains/refunds/domain.md")"
check "check-refs finds 2 broken of 3" "printf '%s' \"\$out\" | grep -q 'refs: 3 checked, 2 broken'"
echo '{"session_id":"s3"}' | "$P/hooks/scripts/session-start.sh" >/dev/null
sleep 1; touch "$W/qa-docs/domains/refunds/domain.md"
check "stop hook blocks inconsistent domain" "echo '{\"session_id\":\"s3\"}' | '$P/hooks/scripts/verify-docs.sh' | grep -q '\"block\"'"

# mirror pages, page trees, link comment
echo '{"layout":"mirror","source":{"pageId":"500"},"confluence":{"pageId":"78","pages":{"changes.md":{"pageId":"79"}}}}' > "$W/qa-docs/domains/refunds/meta.json"
t "update child page of a tree" 0 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__updateConfluencePage '{"pageId":"79","body":"x"}')"
t "create child under exported child" 0 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluencePage '{"spaceId":"QA","parentId":"79","body":"x"}')"
t "update the old source page" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__updateConfluencePage '{"pageId":"500","body":"x"}')"
t "link comment on source page" 0 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluenceFooterComment '{"pageId":"500","body":"x"}')"
t "comment on another page" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluenceFooterComment '{"pageId":"501","body":"x"}')"
t "reply to a comment on source page" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluenceFooterComment '{"pageId":"500","parentCommentId":"9","body":"x"}')"
t "inline comment on source page" 2 guard-mcp.sh "$(m mcp__plugin_qa-docs_jira__createConfluenceInlineComment '{"pageId":"500","body":"x"}')"

# diagrams: a stub mermaid-cli that fails on "BROKEN"
mkdir -p "$T/bin"
cat > "$T/bin/mmdc" <<'STUB'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do case "$1" in -i) i="$2"; shift ;; -o) o="$2"; shift ;; esac; shift; done
grep -q BROKEN "$i" && { echo "Error: Parse error on line 2:" >&2; echo "    at foo (x.js:1)" >&2; exit 1; }
printf 'PNG' > "$o"
STUB
chmod +x "$T/bin/mmdc"
D="$W/qa-docs/domains/bookings"
mkdir -p "$D/doc/flows"
printf '{"domain":"bookings","modules":{"core-module":"abc"}}\n' > "$D/meta.json"
printf '# Bookings\n\n![Overview](diagrams/overview.png)\n\n```mermaid\nflowchart LR\n  A --> B\n```\n\n- [Create](flows/create.md)\n- ref `core-module/src/A.java:2`\n\n## Sources\n\n- core-module@abc\n' > "$D/doc/README.md"
printf '# Create\n\n> Part of [Bookings](../README.md).\n\n![Create](../diagrams/create.png)\n\n```mermaid\nsequenceDiagram\n  A->>B: go\n```\n' > "$D/doc/flows/create.md"
check "render without mmdc reports it, keeps going" "QA_DOCS_MMDC=/nonexistent '$P/scripts/render-diagrams.sh' '$D' 2>/dev/null | grep -q 'mermaid-cli (/nonexistent) is not installed'"
check "check without mmdc does not demand PNGs" "QA_DOCS_MMDC=/nonexistent '$P/scripts/render-diagrams.sh' '$D' --check >/dev/null"
export QA_DOCS_MMDC="$T/bin/mmdc"
check "check before render reports missing PNGs" "! '$P/scripts/render-diagrams.sh' '$D' --check >/dev/null"
check "render writes .mmd and .png" "'$P/scripts/render-diagrams.sh' '$D' 2>/dev/null | grep -q 'diagrams: 2 found, 2 rendered, 0 problems' && [ -f '$D/doc/diagrams/create.png' ] && grep -q sequenceDiagram '$D/doc/diagrams/create.mmd'"
check "check after render is clean" "'$P/scripts/render-diagrams.sh' '$D' --check >/dev/null"
check "second render renders nothing" "'$P/scripts/render-diagrams.sh' '$D' 2>/dev/null | grep -q '2 found, 0 rendered'"
sed -i.bak 's/A->>B: go/A->>B: go on/' "$D/doc/flows/create.md" && rm -f "$D/doc/flows/create.md.bak"
check "check notices a changed diagram" "'$P/scripts/render-diagrams.sh' '$D' --check 2>/dev/null | grep -q \"diagram 'create' changed\""
printf '# Cancel\n\n```mermaid\nflowchart TD\n  X --> Y\n```\n' > "$D/doc/flows/cancel.md"
check "block without picture link is reported" "'$P/scripts/render-diagrams.sh' '$D' 2>/dev/null | grep -q 'flows/cancel.md:3: mermaid block without a picture link'"
printf '# Cancel\n\n![Cancel](diagrams/cancel.png)\n\n```mermaid\nflowchart TD\n  X --> Y\n```\n' > "$D/doc/flows/cancel.md"
check "picture path relative to the page is checked" "'$P/scripts/render-diagrams.sh' '$D' 2>/dev/null | grep -q 'must point to doc/diagrams/cancel.png'"
printf '# Cancel\n\n![Cancel](../diagrams/create.png)\n\n```mermaid\nflowchart TD\n  BROKEN\n```\n' > "$D/doc/flows/cancel.md"
check "duplicate diagram name is reported" "'$P/scripts/render-diagrams.sh' '$D' 2>/dev/null | grep -q \"name 'create' is used twice\""
printf '# Cancel\n\n![Cancel](../diagrams/cancel.png)\n\n```mermaid\nflowchart TD\n  BROKEN\n```\n' > "$D/doc/flows/cancel.md"
out="$("$P/scripts/render-diagrams.sh" "$D")"
check "syntax error is reported without stack lines" "printf '%s' \"\$out\" | grep -q \"'cancel' does not render: Error: Parse error on line 2:\" && ! printf '%s' \"\$out\" | grep -q 'at foo'"
check "render refuses a folder outside domains" "! '$P/scripts/render-diagrams.sh' '$W/core-module' 2>/dev/null"
rm -f "$D/doc/flows/cancel.md"
"$P/scripts/render-diagrams.sh" "$D" >/dev/null

# stop hook on the page layout
echo '{"session_id":"s4"}' | "$P/hooks/scripts/session-start.sh" >/dev/null
sleep 1
printf '# History\n\n## %s - t - created\n' "$(date +%Y-%m-%d)" > "$D/history.md"
touch "$D/doc/README.md"
check "stop hook passes a consistent page set" "[ -z \"\$(echo '{\"session_id\":\"s4\"}' | '$P/hooks/scripts/verify-docs.sh')\" ]"
printf '\n- [Rules](reference/rules.md)\n' >> "$D/doc/README.md"
check "stop hook reports a broken page link" "echo '{\"session_id\":\"s4\"}' | '$P/hooks/scripts/verify-docs.sh' | grep -q \"link to 'reference/rules.md'\""
check "session start flags old single-file domains" "echo '{\"session_id\":\"s5\"}' | '$P/hooks/scripts/session-start.sh' | grep -q 'refunds: .*update of Confluence page 500.*rewrite refunds'"

echo; [ "$fails" = 0 ] && echo "all passed ($T)" || echo "$fails failed ($T)"
[ "$fails" = 0 ]

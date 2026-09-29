# Decisions and deviations from the requirements

Notes for the tech lead. Current Claude Code documentation takes priority over the requirements.

| ID | Topic | Decision / reason | Status |
| --- | --- | --- | --- |
| D-01 | Names | Marketplace `team-plugins`, plugin `java-team`, repository `claude-plugins` are the names proposed in the requirements; change them if the owner provides others | Open |
| D-02 | Rule syntax | `templates/settings.json` uses `Bash(mvn test *)` (space before `*`) and the `sandbox.filesystem.denyRead` / `sandbox.network.allowedDomains` blocks. Verify against current settings docs before release; `claude plugin validate` does not check the template | To verify |
| D-03 | `session-summary` | Ported from `~/.claude/commands/session-summary.md` together with `scripts/save_session.sh`. Logic unchanged; only machine-specific paths were removed: the hardcoded local vault path became `$JAVA_TEAM_VAULT` (default `~/Claude Vault`; `VAULT` still overrides), and the script path became `${CLAUDE_PLUGIN_ROOT}`. The skill writes to each developer's Obsidian vault, so everyone must set `JAVA_TEAM_VAULT` | Ported, agree with owner |
| D-04 | Jira MCP | Uses the remote server `https://mcp.atlassian.com/v1/mcp` (`type: http`, OAuth). Verify the URL and transport against Atlassian docs | To verify |
| D-05 | DB MCP | DBMS is MySQL. `scripts/db-mcp.sh` runs `@benborla29/mcp-server-mysql@2.0.9` (version pinned; writes disabled via `ALLOW_*_OPERATION=false`; the real read-only guarantee is the DB user's grants). Variables: `JAVA_TEAM_DB_URL` (`mysql://host:port/db`, no credentials), `JAVA_TEAM_DB_USER`, `JAVA_TEAM_DB_PASSWORD`. The server does not start without them. Verify the package choice and variable names against its docs | To verify |
| D-06 | Sandbox network | Nexus/Artifactory, git host and Jira hosts are set during project initialization: `permissions-setup` replaces the placeholders `<NEXUS_HOST>`, `<GIT_HOST>`, `<JIRA_HOST>` | Accepted |
| D-07 | Marketplace git URL | `project-init` asks the user for it because the repository has no remote yet | Open |
| D-08 | `verify.sh` and `stop_hook_active` | Requirement: do not block twice. Implemented: with `stop_hook_active=true` tests run again but a failure only warns instead of blocking, so no loop is possible and the fix is still verified. The `session-summary` reminder is sent once per session via a flag | Implemented |
| D-09 | "Changed in session" | `verify.sh` takes `.java` files from `git diff` against the base (`main`/`master`) plus new files, filtered by mtime newer than the marker created by `session-start.sh` | Implemented |
| D-10 | `test-writer` restriction | Writing only to `src/test/**` cannot be expressed in `tools`; it is enforced by `guard-files.sh` via the `agent_type` field of the hook input JSON. Verify that Claude Code passes this field for subagents | To verify |
| D-11 | `tools` with patterns | `java-reviewer` uses `Bash(git diff:*)` etc. in `tools`. Verify that plugin subagents accept such patterns; otherwise use plain `Bash` restricted in the prompt | To verify |
| D-12 | Language | All plugin content (docs, skills, agents, hook messages, templates) is in English | Accepted |

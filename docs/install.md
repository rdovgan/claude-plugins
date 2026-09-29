# Installing the `java-team` plugin

## 1. Connect the marketplace and the plugin

Automatic: `project-init` adds `extraKnownMarketplaces` and `enabledPlugins` to the project's `.claude/settings.json`; Claude Code offers to install the plugin when the project is opened.

Manual:

```
/plugin marketplace add <git URL of the claude-plugins repository>
/plugin install java-team@team-plugins
```

Update: `/plugin marketplace update team-plugins`.

## 2. Dependencies

`jq`, `git`, `mvn` (or `./mvnw` in the project). Without `jq` the hooks only warn and do not break the session.

## 3. Jira (MCP)

1. Start `claude`, run `/mcp`, pick `jira` and complete OAuth in the browser with your own Atlassian account.
2. Reading tickets works right away; creating and changing tickets requires confirmation.

## 4. Database (MCP, read-only)

Set environment variables (in `~/.zshrc` or a secrets manager; never commit them):

```
export JAVA_TEAM_DB_URL="mysql://host:3306/dbname"   # no login or password
export JAVA_TEAM_DB_USER="readonly_user"
export JAVA_TEAM_DB_PASSWORD="..."
```

The DB user must have read-only grants and only on a non-prod environment. Without the variables the DB server does not start; the rest of the plugin keeps working.

## 5. Session summary

Set the Obsidian vault directory: `export JAVA_TEAM_VAULT="$HOME/Claude Vault"` (this is the default).

## 6. First run in a project

Tell the agent: "initialize the project". Review the summary of changes and confirm the write.

## Hook controls

- `JAVA_TEAM_SKIP_VERIFY=1` - disable the test check on stop (for research without code changes).

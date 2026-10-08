# Installing the `java-developer` plugin

## Quick start (new developer)

```
git clone git@github.com:rdovgan/claude-plugins.git
cd claude-plugins && ./install.sh
```

The script checks your tools, connects the marketplace, installs the plugin and tells you which variables to set. Then open any project, run `claude` and type `/java-developer:onboarding`: a 5-minute guided tour (environment check, safety demo, Jira, task flow, project setup). `/java-developer:help` prints a cheat sheet. Everything below is reference for what the tour covers.

## 1. Connect the marketplace and the plugin

Automatic: `project-init` adds `extraKnownMarketplaces` and `enabledPlugins` to the project's `.claude/settings.json`; Claude Code offers to install the plugin when the project is opened.

Manual:

```
/plugin marketplace add git@github.com:rdovgan/claude-plugins.git
/plugin install java-developer@team-plugins
```

Update: `/plugin marketplace update team-plugins`.

## 2. Dependencies

`jq`, `git`, `mvn` (or `./mvnw` in the project). Without `jq` the hooks only warn and do not break the session.

## 3. Jira (MCP)

1. Jira is your Atlassian site (`https://<your-site>.atlassian.net`). Start `claude`, run `/mcp`, pick `jira` and complete OAuth in the browser with your own Atlassian account.
2. Reading tickets works right away; creating and changing tickets requires confirmation.

## 4. Database (MCP, read-only)

Both plugins (`java-developer` and `java-analyst`) read the same variables and start the same read-only DB server, so set them once. Set environment variables (in `~/.zshrc` or a secrets manager; never commit them):

```
export JAVA_TEAM_DB_URL="mysql://host:3306/dbname"   # no login or password
export JAVA_TEAM_DB_USER="readonly_user"
export JAVA_TEAM_DB_PASSWORD="..."
```

The database is MySQL; use a non-prod environment. Schema changes are not made through this server. The DB user must have read-only grants and only on a non-prod environment. Without the variables the DB server does not start; the rest of the plugin keeps working. In `java-analyst` the server accepts only single `SELECT`/`SHOW`/`DESCRIBE`/`EXPLAIN` statements (`guard-mcp.sh`); `JAVA_TEAM_VAULT` is used by `java-developer` only (`session-summary`).

## 5. Session summary

Set the Obsidian vault directory: `export JAVA_TEAM_VAULT="$HOME/Claude Vault"` (this is the default).

## 6. First run in a project

Tell the agent: "initialize the project". Review the summary of changes and confirm the write.

## Hook controls

- `JAVA_TEAM_SKIP_VERIFY=1` - disable the test check on stop (for research without code changes).

## Demo for a team (show the whole onboarding again)

The tour itself is repeatable: `/java-developer:onboarding` always starts from step 1. To make the start-up hint appear again and show a clean state:

1. Reset the "done" flag: ask the agent "reset onboarding state" (it runs `scripts/mark-onboarded.sh --reset`), or delete `onboarded` and `hint.count` in the plugin data directory.
2. Use a clean project: a fresh `git clone` of any repo, or a copy of `test-fixtures/sample-maven-project` (no `CLAUDE.md`, so step 5 offers `project-init`).
3. Show the missing-variables case without touching your profile: `env -u JAVA_TEAM_VAULT -u JAVA_TEAM_DB_URL claude`.
4. To show the installation itself: `claude plugin uninstall java-developer@team-plugins`, then `./install.sh`.
5. Jira OAuth cannot be reset from the plugin: show it with a colleague's or a test account, or describe it.

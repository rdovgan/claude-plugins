# claude-plugins

Team Claude Code marketplace for a Java team (`team-plugins`) with the `java-team` plugin.

The plugin provides Maven project initialization (`CLAUDE.md`, permissions, sandbox), secret protection, check hooks, a task workflow (research -> interview -> spec -> implementation -> review), subagents, and MCP for Jira and the DB.

- Installation: [docs/install.md](docs/install.md)
- Decisions and deviations: [docs/decisions.md](docs/decisions.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)

## How to use

### Once per developer machine

1. Install `jq`, `git`, `mvn` (or use the project's `./mvnw`).
2. Connect the marketplace and the plugin:
   ```
   /plugin marketplace add <git URL of this repository>
   /plugin install java-team@team-plugins
   ```
3. Set environment variables (details in [docs/install.md](docs/install.md)):
   - `JAVA_TEAM_VAULT` - Obsidian vault directory for `session-summary`;
   - `JAVA_TEAM_DB_URL` (`mysql://host:3306/db`), `JAVA_TEAM_DB_USER`, `JAVA_TEAM_DB_PASSWORD` - only for DB access; without them the DB server simply does not start.
4. In Claude Code run `/mcp` and complete OAuth for `jira`.

### In each project

1. Open the project in `claude` and say: "initialize the project".
2. `project-init` scans the Maven project, shows a summary and, after confirmation, creates `CLAUDE.md` (root and per module), `.claude/settings.json` and `.gitignore` entries. It asks for the Nexus, git and Jira hosts during initialization.
3. Commit `CLAUDE.md` and `.claude/settings.json`; teammates get the plugin automatically.

### Daily work

Just give a task: a Jira key (`ABC-123`), a link, or a description. The agent runs the phases itself:

| Phase | What happens |
| --- | --- |
| Research (`task-research`) | Reads the ticket from Jira, searches code via `code-explorer`, does not change code |
| Interview (`task-interview`) | Asks concrete questions in groups of up to 5 |
| Specification (`task-spec`) | Writes `.claude/specs/<key>.md` (not committed) and waits for your confirmation |
| Implementation | Step by step in plan mode; `test-writer` writes tests |
| Self-check and review | `/java-team:review` runs `java-reviewer` on the branch changes |

What happens automatically:

- **Protection:** secrets, `.env*`, prod configs and keys cannot be read; `git push --force`, pushes to `main`/`master`, `mvn deploy` and `rm -rf` outside `target/` are blocked with an explanation.
- **Formatting:** after a `.java` edit the formatter and checkstyle run, if configured in `pom.xml`.
- **Check on stop:** tests of the changed modules run; on failure the agent cannot finish. Then it reminds once about `session-summary`.
- **Recovery:** at session start the agent sees the branch, the Jira key, the spec and the latest state snapshot.

### Commands

| Command | Action |
| --- | --- |
| `/java-team:review` | Review the current branch's changes |
| `/java-team:update-claude-md` | Update `CLAUDE.md` and settings, keeping manual sections |

The `session-summary` and `permissions-setup` skills can also be invoked directly ("save the session", "set up permissions").

### Tips

- `JAVA_TEAM_SKIP_VERIFY=1 claude` - disable the test check on stop (research without code changes).
- Personal permission exceptions go in `.claude/settings.local.json` (git-ignored).
- Write manual notes in `CLAUDE.md` under "Manual notes": `project-init` never touches them.

## Developing the plugin

Plugin changes go through a PR reviewed by the tech lead. Every behavior change bumps `version` in `plugins/java-team/.claude-plugin/plugin.json` and adds a CHANGELOG entry. Before a release:

```bash
claude plugin validate . --strict
claude plugin validate plugins/java-team --strict
shellcheck plugins/java-team/hooks/scripts/*.sh
```

## Structure


```
.claude-plugin/marketplace.json
plugins/java-team/   skills, agents, commands, hooks, templates, .mcp.json
test-fixtures/       sample-maven-project for acceptance testing
docs/
```

# claude-plugins

Team Claude Code marketplace for a Java team (`team-plugins`) with two plugins: `java-developer` (full task workflow including implementation) and `java-analyst` (analysis only, never changes code).

The plugin provides Maven project initialization (`CLAUDE.md`, permissions, sandbox), secret protection, check hooks, a task workflow (research -> interview -> spec -> implementation -> review), subagents, and MCP for Jira and the DB.

- Installation: [docs/install.md](docs/install.md)
- Decisions and deviations: [docs/decisions.md](docs/decisions.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)

## How to use

**New here?** `git clone` this repo, run `./install.sh`, then in Claude Code type `/java-developer:onboarding`. Cheat sheet: `/java-developer:help`. The detailed steps below are optional reference.

### Once per developer machine

1. Install `jq`, `git`, `mvn` (or use the project's `./mvnw`).
2. Connect the marketplace and the plugin:
   ```
   /plugin marketplace add git@github.com:rdovgan/claude-plugins.git
   /plugin install java-developer@team-plugins
   ```
3. Set environment variables (details in [docs/install.md](docs/install.md)):
   - `JAVA_TEAM_VAULT` - Obsidian vault directory for `session-summary`;
   - `JAVA_TEAM_DB_URL` (`mysql://host:3306/db`), `JAVA_TEAM_DB_USER`, `JAVA_TEAM_DB_PASSWORD` - only for DB access; without them the DB server simply does not start.
4. In Claude Code run `/mcp` and complete OAuth for `jira`.

### In each project

1. Open the project in `claude` and say: "initialize the project".
2. `project-init` scans the Maven project, shows a summary and, after confirmation, creates `CLAUDE.md` (root and per module), `.claude/settings.json` and `.gitignore` entries. Network hosts (Nexus, git, Jira) are asked for and written to the sandbox allowlist.
3. Commit `CLAUDE.md` and `.claude/settings.json`; teammates get the plugin automatically.

### Daily work

Just give a task: a Jira key (`ABC-123`), a link, or a description. The agent runs the phases itself:

| Phase | What happens |
| --- | --- |
| Research (`task-research`) | Reads the ticket from Jira, searches code via `code-explorer`, does not change code |
| Interview (`task-interview`) | Asks concrete questions in groups of up to 5 |
| Specification (`task-spec`) | Writes `.claude/specs/<key>.md` (not committed) and waits for your confirmation |
| Implementation | Step by step in plan mode; `test-writer` writes tests |
| Self-check and review | `/java-developer:review` runs `java-reviewer` on the branch changes |

What happens automatically:

- **Protection:** secrets, `.env*`, prod configs and keys cannot be read; `git push --force`, pushes to `main`/`master`, `mvn deploy` and `rm -rf` outside `target/` are blocked with an explanation.
- **Formatting:** after a `.java` edit the formatter and checkstyle run, if configured in `pom.xml`.
- **Check on stop:** tests of the changed modules run; on failure the agent cannot finish. Then it reminds once about `session-summary`.
- **Recovery:** at session start the agent sees the branch, the Jira key, the spec and the latest state snapshot.

### Commands

| Command | Action |
| --- | --- |
| `/java-developer:review` | Review the current branch's changes |
| `/java-developer:update-claude-md` | Update `CLAUDE.md` and settings, keeping manual sections |

The `session-summary` and `permissions-setup` skills can also be invoked directly ("save the session", "set up permissions").

### Tips

- `JAVA_TEAM_SKIP_VERIFY=1 claude` - disable the test check on stop (research without code changes).
- Personal permission exceptions go in `.claude/settings.local.json` (git-ignored).
- Write manual notes in `CLAUDE.md` under "Manual notes": `project-init` never touches them.

## java-analyst: analysis without implementation

For analysis without implementation: the developer implements the change, the plugin prepares everything around it. `/java-analyst:analyze <Jira key | link | description>` runs research -> interview -> report and writes local documents to `.claude/analysis/<task>/` (git-excluded through `.git/info/exclude`): `00-README`, `01-research`, `02-interview`, `03-flows` (mermaid), `04-findings`, `05-proposals` (options with code examples), `06-implementation-guide` (steps with acceptance criteria). Nothing is published to Jira or Confluence.

First time in a project: `/java-analyst:setup` (shows exactly which settings are missing and adds them after confirmation) and `/java-analyst:onboarding` (a 3-minute tour).

It is enforced by hooks, not by prompts: source code, tests, build files and application configs cannot be written (documentation, `CLAUDE.md` and `.claude/` files can, so `/init` works), Bash is an allowlist of read-only commands, MCP is read-style tools only, and the agent cannot stop with an unfinished analysis. Install: `PLUGIN=java-analyst ./install.sh`, or `/plugin install java-analyst@team-plugins`. It reads the same `JAVA_TEAM_DB_URL` / `JAVA_TEAM_DB_USER` / `JAVA_TEAM_DB_PASSWORD` as `java-developer` (read-only DB, SELECT only). Do not enable it together with `java-developer` in the same project. `JAVA_ANALYST_OFF=1` disables the guards.

## Developing the plugin

Plugin changes go through a PR reviewed by the tech lead. Every behavior change bumps `version` in `plugins/java-developer/.claude-plugin/plugin.json` and adds a CHANGELOG entry. Before a release:

```bash
claude plugin validate . --strict
claude plugin validate plugins/java-developer --strict
claude plugin validate plugins/java-analyst --strict
shellcheck plugins/java-developer/hooks/scripts/*.sh plugins/java-analyst/hooks/scripts/*.sh
```

## Structure


```
.claude-plugin/marketplace.json
plugins/java-developer/   skills, agents, commands, hooks, templates, .mcp.json
plugins/java-analyst/ analysis-only: 3 skills, command, read-only guard hooks, document templates
test-fixtures/       sample-maven-project for acceptance testing
docs/
```

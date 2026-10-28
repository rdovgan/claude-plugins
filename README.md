# team-plugins

Claude Code plugins for the Java team. The marketplace is called `team-plugins` and holds three plugins: one for each role.

| Plugin | Who uses it | What it does | Changes code |
| --- | --- | --- | --- |
| [`java-developer`](#java-developer) | Developers | Takes a ticket from Jira to a reviewed branch: research, questions, spec, implementation, tests, review | Yes |
| [`java-analyst`](#java-analyst) | Analysts, leads | Analyses a ticket and writes local documents: flows, findings, solution options, implementation guide | No |
| [`qa-docs`](#qa-docs) | QA | Documents one business domain from the code of all repositories, Jira and Confluence, verifies it, exports to Confluence | No |

Enable only one of them in a project or session.

## Quick start

```bash
git clone git@github.com:rdovgan/claude-plugins.git
cd claude-plugins
./install.sh                        # java-developer
PLUGIN=java-analyst ./install.sh    # or java-analyst
PLUGIN=qa-docs ./install.sh         # or qa-docs (usually done by the server admin)
```

The script checks the tools (`jq`, `git`, `mvn`), connects the marketplace, installs the plugin and says which variables are missing. Then open a project, start `claude` and run:

1. `/mcp` → `jira` → log in with your Atlassian account.
2. `/java-developer:onboarding`, `/java-analyst:onboarding` or `/qa-docs:onboarding`: a 3-5 minute tour.

Manual installation, every variable and troubleshooting: [docs/install.md](docs/install.md).

### Environment variables

| Variable | Plugin | Needed for |
| --- | --- | --- |
| `JAVA_TEAM_DB_URL`, `JAVA_TEAM_DB_USER`, `JAVA_TEAM_DB_PASSWORD` | developer, analyst | Read-only MySQL access. Without them the DB server does not start, everything else works |
| `JAVA_TEAM_JIRA_URL`, `JAVA_TEAM_JIRA_EMAIL`, `JAVA_TEAM_JIRA_TOKEN` | developer, analyst | Downloading ticket attachments. The Jira MCP server returns only their names |
| `JAVA_TEAM_VAULT` | developer | Obsidian vault for `session-summary` (default `~/Claude Vault`) |

Never commit these values. qa-docs needs none: the admin configures `.qa-docs/config.env` on the server.

---

## java-developer

### Setting up a project (once)

Open the project in `claude` and say **"initialize the project"**. `project-init` scans the Maven modules, shows what it will create and, after you confirm, writes:

- `CLAUDE.md` at the root and for modules with special rules;
- `.claude/settings.json`: permissions, sandbox, network hosts (Nexus, git, Jira), the marketplace and the plugin;
- `.gitignore` entries.

Commit `CLAUDE.md` and `.claude/settings.json`. Teammates are offered the plugin when they open the project.

### Daily work

Give the agent a task: a Jira key (`ABC-123`), a link, or a description. It sizes the task first and runs only the phases the size needs:

| Phase | trivial (1-2 files, behavior stated) | standard | complex |
| --- | --- | --- | --- |
| Research: ticket, Confluence, code | ticket only | linked pages, one `code-explorer` call | full sweep, several repositories |
| Interview: questions to you | no | open questions only | full checklist |
| Spec in `.claude/specs/` | 3-line plan in chat | 1-3 steps | full spec |
| `spec-reviewer` checks the plan | no | if a contract, a table or several repos change | yes |
| Implementation and tests | directly | step by step | step by step, plan mode |
| `java-reviewer` checks the diff | on request | yes | yes |

Say **"quick"** or **"full"** to override the size. The spec is a checklist: each step has acceptance criteria and tests, and the agent ticks them as it goes. It is never committed.

### What runs automatically

| When | What |
| --- | --- |
| Every tool call | Secrets, `.env*`, prod configs and keys cannot be read. `git push --force`, pushes to `main`/`master`, `mvn deploy` and `rm -rf` outside `target/` are blocked with an explanation |
| After a `.java` edit | Formatter and checkstyle, if `pom.xml` configures them |
| When the agent stops | Tests of the changed modules run; a failure blocks finishing. Then one reminder to save the session |
| Session start | Branch, Jira key, spec progress (`N of M steps done`) and the last state snapshot, so work resumes where it stopped |

### Commands and agents

| Command | Action |
| --- | --- |
| `/java-developer:review` | Review the branch against `main`/`master` |
| `/java-developer:update-claude-md` | Refresh `CLAUDE.md` and settings, keeping manual sections |
| `/java-developer:help` | Cheat sheet |
| "save the session" | `session-summary`: a note in Obsidian |
| "set up permissions" | `permissions-setup` |

| Agent | Model | Role |
| --- | --- | --- |
| `code-explorer` | Haiku | Finds related classes, similar implementations, tests, integration points. Read-only |
| `spec-reviewer` | Opus | Checks the spec before implementation: uncovered requirements, consumers in other repositories, schema, access checks. Read-only |
| `java-reviewer` | Opus | Reviews the diff with the team checklist: blocker / must fix / consider. Read-only |
| `test-writer` | Sonnet | Writes tests in the module's style, runs only that module's tests. Never touches production code |

### Tips

- `JAVA_TEAM_SKIP_VERIFY=1 claude`: no test run on stop, for research sessions.
- Personal permission exceptions go to `.claude/settings.local.json` (git-ignored).
- Write your own notes in `CLAUDE.md` under "Manual notes": `project-init` never changes them.

---

## java-analyst

For a ticket that needs analysis before anyone writes code. The developer implements the change; the plugin prepares everything around it.

```
/java-analyst:setup                      # once per project: shows missing settings, adds them on confirmation
/java-analyst:analyze <key | link | text>
```

`analyze` runs research → interview → report. Requirements from the ticket and Confluence are quoted verbatim and mapped to code, and questions the sources already answer are not asked. The result lands in `.claude/analysis/<task>/` (excluded from git through `.git/info/exclude`):

| File | Content |
| --- | --- |
| `00-README` | Summary and index |
| `01-research` | Requirements, code, call paths |
| `02-interview` | Questions and answers |
| `03-flows` | Mermaid flow charts |
| `04-findings` | Problems and risks found |
| `05-proposals` | Solution options with code examples |
| `06-implementation-guide` | Steps with acceptance criteria |

Nothing is published to Jira or Confluence.

**Hooks enforce the guarantees, not prompts.** Source code, tests, build files and application configs cannot be written (documentation, `CLAUDE.md` and `.claude/` can, so `/init` works). Bash is limited to read-only commands, MCP to read tools, the DB to `SELECT`. The agent cannot stop with an unfinished analysis. `JAVA_ANALYST_OFF=1` turns the guards off.

---

## qa-docs

Builds a verified document per business domain from the real code of every repository (Java, PHP, JS), plus Jira and Confluence. QA uses it as the source of truth for requirements and test planning.

It runs on a shared server. Sources are read-only mirrors of `master`/`main`, refreshed by cron. Each QA uses their own account and Claude login, and results in `<workspace>/qa-docs/` are shared.

### Starting

Always start in the workspace root, the folder that holds all repositories:

```bash
ssh <qa-user>@<server>
cd /srv/projects && claude
```

Only there does the session load the workspace settings (secret rules, Confluence write confirmation, sandbox). From inside one repository, that repository's settings apply instead. The first time: `/mcp` → `jira`, then `/qa-docs:check` and `/qa-docs:onboarding`.

### Commands

| Command | Action |
| --- | --- |
| `/qa-docs:ask <question>` | One answer from the code with `repo/path:line`, writes nothing. Cheapest option |
| `/qa-docs:document <domain \| flow \| key \| page>` | Full document: scope (you confirm) → Jira/Confluence → code research → pages in `doc/` → verification |
| `/qa-docs:verify <slug>` | Check a document again: references, facts against the code, approval by a person |
| `/qa-docs:refresh <slug>` | Update a document after the code changed |
| `/qa-docs:export <slug>` | Publish to Confluence as a page tree, keeping manual edits on each page |
| `/qa-docs:update-page <link>` | New version of an old Confluence page in its own structure, with a list of what changed. The old page only gets a link comment |
| `/qa-docs:rewrite <slug>` | Move a 0.2 single-file document into the page set, without new research |
| `/qa-docs:map` | Build or update `qa-docs/modules.md` (repositories and their connections) and `qa-docs/domains.md` (domains and their status) |
| `/qa-docs:check` | Tools, server setup, freshness of sources and maps |
| `/qa-docs:help` | Cheat sheet |

A document is a set of short linked pages in `domains/<slug>/doc/`:

| Page | Content |
| --- | --- |
| `README.md` | Summary, overview diagram of actors, systems and data stores, list of processes |
| `flows/<flow>.md` | One process: sequence or flow diagram, steps, rules it applies, error paths, edge cases, what to test |
| `reference/` | `rules.md` (each rule stated once, linked from the process pages), `states.md`, `data.md`, `config.md`, `integrations.md` |
| `differences.md`, `open-questions.md` | Where the code disagrees with Jira/Confluence; what is still unknown |

Diagrams are rendered to PNG on the server with mermaid-cli (`doc/diagrams/`). Confluence gets the mermaid code and the PNG path, because the MCP server cannot upload attachments.

### Usage limits

A full document on a large workspace is the most expensive thing the team does with Claude. Agents run on Sonnet. Research covers at most `QA_DOCS_MAX_SUBFLOWS` sub-flows (default 6) and then asks whether to continue. Searches skip build output and dependencies. Use `/qa-docs:ask` when you only need an answer.

### Guarantees

Hooks block:

- secret files;
- reads outside the workspace;
- writes anywhere except documents in `qa-docs/`;
- two sessions working on one domain at once;
- non-read-only Bash and Jira calls;
- Confluence writes outside the configured parent page or to pages qa-docs did not create.

On stop, the documents must be consistent and every `repo/path:line` reference must resolve. The guards have no off switch.

Server setup (accounts, permissions, cron, settings): [plugins/qa-docs/server/README.md](plugins/qa-docs/server/README.md).

---

## Developing the plugins

Changes go through a PR reviewed by the tech lead. Every behavior change bumps `version` in the plugin's `.claude-plugin/plugin.json` and adds a [CHANGELOG](CHANGELOG.md) entry. Design decisions and open questions are in [docs/decisions.md](docs/decisions.md).

Before a release:

```bash
claude plugin validate . --strict
for p in java-developer java-analyst qa-docs; do claude plugin validate plugins/$p --strict; done
shellcheck plugins/*/hooks/scripts/*.sh plugins/qa-docs/scripts/*.sh plugins/qa-docs/server/*.sh
test-fixtures/qa-docs/test-guards.sh
```

```
.claude-plugin/marketplace.json   marketplace definition
plugins/java-developer/           skills, agents, commands, hooks, templates, .mcp.json
plugins/java-analyst/             analysis skills, read-only guard hooks, document templates
plugins/qa-docs/                  domain skills, agents, guard hooks, templates, server/ admin scripts
test-fixtures/                    sample Maven project and review bait for acceptance tests
docs/                             install guide, decisions, feature cheat sheet
```

# team-plugins

Claude Code plugins for the Java team, one per role. Enable only one of them in a project.

| Plugin | For | What it does | Changes code |
| --- | --- | --- | --- |
| [`java-developer`](#java-developer) | Developers | Ticket → research → spec → code and tests → review | Yes |
| [`java-analyst`](#java-analyst) | Analysts, leads | Analyses a ticket and the code: flows, findings, solution options, implementation guide | No |
| [`qa-analyst`](#qa-analyst) | QA | Answers "is this a bug?", "what to test?" from the ticket, logs, DB and code | No |
| [`qa-docs`](#qa-docs) | QA | Verified documentation of a business domain from the code, exported to Confluence | No |

## Install

```bash
git clone git@github.com:rdovgan/claude-plugins.git && cd claude-plugins
./install.sh                       # java-developer
PLUGIN=qa-analyst ./install.sh     # or java-analyst, qa-docs
```

Then in `claude`: `/mcp` → `jira` → log in, and `/<plugin>:onboarding` for a 3-minute tour. `/<plugin>:help` is the cheat sheet. Variables, manual setup and troubleshooting: [docs/install.md](docs/install.md).

| Variable | Needed for |
| --- | --- |
| `JAVA_TEAM_DB_URL`, `_USER`, `_PASSWORD` | Read-only MySQL access (optional) |
| `JAVA_TEAM_JIRA_URL`, `_EMAIL`, `_TOKEN` | Downloading Jira attachments |
| `JAVA_TEAM_VAULT` | Obsidian vault for session notes (java-developer) |
| `<PLUGIN>_FORMATS` | Optional override of the selected formats, e.g. `QA_ANALYST_FORMATS=summary,impact` |

## How the plugins work

- **Talk first.** Ask questions in chat; answers cost no documents. What is settled is kept in a short `notes.md` per task.
- **Report on request.** Pick the formats in the row above the prompt (violet = on, click to switch) and press the yellow **▶ REPORT** button, run `/<plugin>:report`, or say "make the report". Only the selected formats are written, and only they are checked.
- **Hooks enforce the rules.** Secrets cannot be read; the analysts and qa-docs cannot change code and use Jira, Confluence and the DB read-only.

## java-developer

Give a task (`ABC-123`, a link or a text). The agent sizes it and runs only what the size needs: a trivial fix goes straight to code and tests; a bigger task gets research, questions, a spec in `.claude/specs/`, then implementation and review. Say "quick" or "full" to override. On stop, the tests of the changed modules must pass.

First time in a project: say "initialize the project" (writes `CLAUDE.md` and `.claude/settings.json`; commit both).

| Format | Default | Result in `.claude/reports/<KEY>/` |
| --- | --- | --- |
| `pr` | on | PR title and description from the team template |
| `qa` | on | Handoff for QA: what changed, how to test, Jira comment |
| `review` | off | Self-review by `java-reviewer` |
| `summary` | off | Session note in Obsidian |

Commands: `/java-developer:report`, `/java-developer:review`, `/java-developer:update-claude-md`. `JAVA_TEAM_SKIP_VERIFY=1` skips the tests on stop.

## java-analyst

Analysis before anyone writes code. Ask about the task in chat; `/java-analyst:analyze <key>` runs the full research → interview → report. Results go to `.claude/analysis/<task>/`.

| Format | Default | Result |
| --- | --- | --- |
| `summary` | on | Flows, findings, solution options, implementation guide |
| `dev` | on | Developer guide: UML, patterns with reference code, templates |
| `visual` | off | Interactive page, published as a private Artifact |
| `confluence` | off | Page for the team, ready to paste into Confluence |

## qa-analyst

For QA who need an answer, not a fix. Reads the ticket and its Confluence pages, logs, the DB and the code, and answers in plain language without code. `/qa-analyst:analyze <key | log>` runs the full research → interview → report. Results go to `.claude/qa-analysis/<task>/`.

| Format | Default | Result |
| --- | --- | --- |
| `summary` | on | The answer, flows, findings, ready-to-paste ticket text |
| `tests` | on | Test cases with steps and expected results |
| `impact` | off | Affected records in numbers, with the queries |
| `decision` | off | Decision table of the business rule |
| `logs` | off | Error statistics from the logs |
| `regression` | off | What changed between releases and what to retest |
| `visual` | off | Interactive page, published as a private Artifact |
| `confluence` | off | Page for the team, ready to paste into Confluence |

## qa-docs

Runs on a shared server over read-only mirrors of all repositories. Start in the workspace root (`cd /srv/projects && claude`).

| Command | Action |
| --- | --- |
| `/qa-docs:ask <question>` | Quick answer from the code, writes nothing |
| `/qa-docs:document <domain>` | Full verified document: process pages with diagrams, rules, differences from Jira/Confluence |
| `/qa-docs:refresh`, `/qa-docs:verify` | Update after code changes, check again |
| `/qa-docs:report`, `/qa-docs:export` | Build the formats; publish to Confluence (asks first) |
| `/qa-docs:update-page <link>` | Bring an old Confluence page up to date in its own structure |

Formats: `confluence` (on, the pages with a local preview) and `visual` (off, an interactive overview). Server setup: [plugins/qa-docs/server/README.md](plugins/qa-docs/server/README.md).

## Developing

Changes go through a PR. Every behavior change bumps `version` in the plugin's `plugin.json` and adds a [CHANGELOG](CHANGELOG.md) entry; design decisions are in [docs/decisions.md](docs/decisions.md). Before a release:

```bash
for p in . plugins/*; do claude plugin validate "$p" --strict; done
shellcheck plugins/*/hooks/scripts/*.sh plugins/qa-docs/scripts/*.sh plugins/qa-docs/server/*.sh
test-fixtures/qa-docs/test-guards.sh
```

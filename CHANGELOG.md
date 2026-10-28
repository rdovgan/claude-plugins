# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/), versions follow semver. Every behavior change bumps the version in `plugin.json`.

## [0.10.0] - 2026-10-28

### Added
- `spec-reviewer` subagent (java-developer, `model: opus`, read-only): reviews the spec before implementation for ticket requirements no step covers, consumers of changed public methods, endpoints, DTOs and events in mbp and other repositories, DB changes without a changelog or deploy order, access checks the plan drops, and invariants of the touched code (transactions, idempotency, cache). Report is grouped as blocker / must fix / consider, each item backed by `repo/path:line` or a ticket quote. `task-spec` calls it once for complex tasks and for standard ones that touch a contract, a table or several repositories, updates the spec, and tells the user what changed. Until now the stronger model saw only the finished diff, where a gap in the plan is the most expensive to fix.

## [0.9.0] and java-analyst [0.6.0] - 2026-10-21

### Added
- `task-triage` (java-developer): sizes a new task as **trivial**, **standard** or **complex** right after the ticket is read. Trivial tasks (1-2 files, behavior fully stated, no API, schema or multi-repo change) skip the Confluence sweep, `code-explorer`, the interview, the spec file and `java-reviewer`: a plan of up to 3 lines in chat, the change, the module's tests, a 3-line self-check. Standard runs a light research and a short spec. "quick" and "full" override the level; the agent escalates when a task turns out bigger. Feedback was that one-line fixes ran the full cycle for half an hour.
- `scripts/jira-attachments.sh <KEY>` (java-developer, java-analyst): downloads ticket attachments into `.claude/attachments/<KEY>/` (added to `.gitignore`) through the Jira REST API with a personal API token (`JAVA_TEAM_JIRA_EMAIL`, `JAVA_TEAM_JIRA_TOKEN`, optional `JAVA_TEAM_JIRA_URL`). The Atlassian MCP server returns attachment metadata only, so screenshots and logs could not be opened. `task-research` and `analysis-research` call it when a ticket has attachments that matter and ask the user to paste them when the token is not set. `check-env.sh` and onboarding mention the variables; `templates/settings.json` allows `api.media.atlassian.com`, where Jira redirects attachment downloads.

### Changed
- `task-research` runs `task-triage` after reading the ticket and follows its level; the `prompt-submit` reminder no longer demands a spec for every Jira key. The `CLAUDE.md` template (Workflow, Definition of done), `/java-developer:help`, onboarding and the cheat sheet describe the trivial path. Existing projects pick up the new `CLAUDE.md` text with `/java-developer:update-claude-md`.

### Fixed
- java-analyst: the Bash guard refused the plugin's own `scripts/check-env.sh` and `mark-onboarded.sh`, so `/java-analyst:setup` and onboarding could not run them. Scripts in the plugin's `scripts/` are allowed now, except `db-mcp.sh`.

## qa-docs [0.2.0] - 2026-10-20

### Changed
- Usage limits: one run on a workspace of 30 repositories used two full 5-hour limits. `flow-tracer`, `source-reader` and `fact-checker` run on `model: sonnet` instead of the session model. `domain-research` has a budget (`QA_DOCS_MAX_SUBFLOWS`, default 6 sub-flows, one wave, only the repositories in scope), spot-checks the agents' facts instead of re-reading all the code, and stops after research to ask whether to write the document, trace the rest, or stop. `domain-verify` runs at most 3 `fact-checker` agents on rules, values, states and flow steps only. `domain-scope`, `module-map` and `/qa-docs:refresh` follow the same limits.
- `flow-tracer` and `fact-checker` search inside a repository (`path`), read large files in parts, and report an oversized sub-flow as an open end instead of tracing it all.
- `guard-files.sh` blocks `Grep` with `output_mode: content` over the whole workspace; listing matching files there is still allowed.

### Added
- `/qa-docs:ask <question>`: an answer from the code (existing documents first) with `repo/path:line`, at most 2 agents, no files written.
- `templates/server/ignore` for `<workspace>/.ignore` (build output, dependencies, minified files are not searched); `/qa-docs:check` reports when it is missing. `QA_DOCS_MAX_SUBFLOWS` in `config.env`; session start prints the budget.

### Fixed
- Writing the first file of a new domain was refused when the workspace path contains a symlink (`/var` -> `/private/var` on macOS, a symlinked `/srv`): `qd_realpath` resolved only an existing parent folder. It now resolves the nearest existing ancestor.

## qa-docs [0.1.0] - 2026-10-12

### Added
- New plugin `qa-docs`: domain documentation for QA on a shared server. `/qa-docs:document` runs `domain-scope`, `domain-sources`, `domain-research`, `domain-write`, `domain-verify` and writes `qa-docs/domains/<slug>/`: `00-scope`, `01-sources` (Jira/Confluence claims `D*`), `02-code` (facts `F*` with `repo/path:line` and a verdict per claim), `domain.md` (the document), `03-verification`, `history.md`, `meta.json` (status, commits, Confluence page). Also `/qa-docs:export`, `/qa-docs:refresh`, `/qa-docs:verify`, `/qa-docs:map`, `/qa-docs:check`, `/qa-docs:help`, `/qa-docs:onboarding`.
- Agents: `flow-tracer` (one sub-flow across repositories, facts with references), `source-reader` (Jira/Confluence claims verbatim), `fact-checker` (tries to refute each statement).
- Hooks: sensitive files by name plus `.qa-docs/sensitive.txt`; reads only inside the workspace; writes only documents in `qa-docs/`; per-domain and map locks, released at session end or after `QA_DOCS_LOCK_MINUTES`; read-only Bash with the plugin's own `scripts/` allowed; MCP read-only except Confluence create/update limited to the configured space, parent and pages qa-docs exported; Stop check (meta, placeholders, mermaid, sources, `check-refs.sh`, a history entry, sources moved mid-session). Session start reports stale or failed sources, domains whose code changed, locks, and the export target.
- `server/update-sources.sh` (cron: mirrors `main`/`master`, writes `.qa-docs/sources.tsv`), `server/README.md` (accounts, permissions, cron, settings), `templates/settings.json`, `templates/server/*`. `install.sh` accepts `PLUGIN=qa-docs`.
- `test-fixtures/qa-docs/test-guards.sh`: 46 acceptance cases for the hooks and scripts.

## Unreleased - ported from the `mbp-claude-plugins` fork

### Changed
- `java-team` is replaced by `java-developer` (see the 0.8.0 entry) and the `java-analyst` plugin is added, together with the improvements made in the fork: workspace and module awareness, Confluence reading in research, spec as a live checklist, attribution stripping, onboarding and help commands, `install.sh`, the features cheat sheet.
- Everything specific to the project the fork was built for is removed or made configurable: no default main project (`JAVA_TEAM_MAIN_PROJECT` / `JAVA_ANALYST_MAIN_PROJECT` must be set), `reference/modules.md` and `reference/team-workflow.md` are templates, no Java-line/branch-per-line rules, no demo-branch rules, no revert block, no hardcoded hosts or code style scheme, protected branches are `main`, `master` plus `JAVA_TEAM_PROTECTED_BRANCHES`.

## java-analyst [0.4.0] - 2026-10-07

### Changed
- The write guard is relaxed from "only `.claude/analysis/`" to "no code": inside the project, documentation (`.md .mdx .txt .rst .adoc .puml .mmd .drawio`), `CLAUDE.md`, `.gitignore`, `.mcp.json` and anything under `.claude/` can be written, so the built-in `/init` and settings work. Source code, tests, build files (`pom.xml`, `package.json`), application configs and anything outside the project are still refused. The error message now lists what is allowed.
- The Bash allowlist accepts the usual read-only tools that were refused before: `sed` without `-i`/`w`/`e`, `awk` without output or `system()`, `xargs` with a read-only command, `npm|pnpm|yarn ls|list|view|outdated|explain|why`, and a bare `--version` of `node`, `python`, `java`, and similar. Options that write or run programs stay blocked (`sort -o`, `uniq in out`, `tree -o`, `rg --pre`, `git -c`, `git grep -O`).

### Added
- Onboarding like in `java-developer`: `/java-analyst:onboarding` (3-minute tour) and a first-run hint at session start.
- `/java-analyst:setup`: checks the environment and the project (`scripts/check-env.sh`), shows which settings are missing (marketplace and `enabledPlugins`, allow/deny rules, `additionalDirectories` for sibling repositories), adds them to `.claude/settings.json` after confirmation, and lists the manual steps (Jira login via `/mcp`, DB variables, `/init`). Template: `templates/settings.json`.

## java-analyst [0.3.0] - 2026-10-06

### Added
- Read-only DB server (`.mcp.json`, `scripts/db-mcp.sh`) driven by the same variables as `java-developer`: `JAVA_TEAM_DB_URL`, `JAVA_TEAM_DB_USER`, `JAVA_TEAM_DB_PASSWORD`. `guard-mcp.sh` lets its query tool through only for a single `SELECT`/`SHOW`/`DESCRIBE`/`EXPLAIN` (no `;`, `INTO OUTFILE`, `FOR UPDATE`); an unreadable statement is refused.
- `install.sh` with `PLUGIN=java-analyst` now also checks the DB variables (it skips `JAVA_TEAM_VAULT`, which only `session-summary` in `java-developer` uses).

## [0.8.0] - 2026-10-06

### Added
- Conflict warning: `java-developer` (0.8.0) and `java-analyst` (0.2.1) check `enabledPlugins` (user, project, local settings) at session start; if the other one is enabled too, the agent tells the developer once to disable one. Running both is unsupported: the read-only guards of `java-analyst` block the implementation flow.

### Changed
- The plugin `java-team` is renamed `java-developer`, so the pair reads clearly: `java-analyst` analyses, `java-developer` takes a task through to code. Folder `plugins/java-developer/`, commands `/java-developer:*`, hook message prefix and marketplace entry follow. This is breaking for installed copies: run `claude plugin uninstall java-team@team-plugins` and `claude plugin install java-developer@team-plugins` (or `./install.sh`), and re-run `project-init` (update mode) in projects, which replaces `java-team@team-plugins` in `.claude/settings.json`.
- Kept on purpose: the `<!-- java-team:generated:start/end -->` markers in generated `CLAUDE.md` files (update mode finds sections by them) and the `JAVA_TEAM_*` environment variables (already set on developer machines). Entries below keep the old name.

## [0.7.0] and java-analyst [0.2.0] - 2026-10-06

### Fixed
- Research on big epics read hundreds of tickets but not the Confluence pages attached to them, which hold the main requirements. `task-research` (java-team) and `analysis-research` (java-analyst) now require collecting Confluence references from the epic and every child (remote issue links, URLs in descriptions and comments, a CQL search by key), reading each page in full with its child pages and comments, flagging contradictions and unreadable pages as open questions, and reporting the sources read.
- java-analyst: `01-research.md` has "Requirements and constraints from Confluence" and "Sources" sections; `verify-analysis.sh` blocks finishing when "Sources" is missing.

## java-analyst [0.1.0] - 2026-10-06

### Added
- New plugin `java-analyst`: analysis without implementation. `/java-analyst:analyze` runs `analysis-research`, `analysis-interview`, `analysis-report` and writes `00-README`, `01-research`, `02-interview`, `03-flows`, `04-findings`, `05-proposals`, `06-implementation-guide` to `.claude/analysis/<task>/`. `/java-analyst:help` is the cheat sheet.
- Hooks: read-only guards for files, Bash and MCP; session context with the workspace and module map; Jira-key reminder; Stop check for a complete analysis.
- `install.sh` accepts `PLUGIN=java-analyst`.

## [0.6.0] - 2026-10-06

### Added
- The task spec is a live checklist. `task-spec` has an "Execution" section: after each step run its tests, tick only verified criteria (`[x]`), fill the step's new `Result:` line (`templates/spec.md`), do not start the next step with open criteria, and update the spec when scope changes. `templates/CLAUDE.md` workflow step 4 says the same.
- `session-start.sh` prints the spec progress on start and resume: `N of M steps done. Next: Step K (x criteria open)`, or a hand-off to self-check and review when all steps are done (`jt_spec_progress` in `lib.sh`).
- `verify.sh`: if code changed in the session and no spec criterion was ticked since the session start, it blocks once with a reminder to tick the verified criteria and fill `Result:`. The baseline is stored by `session-start.sh`; the flag keeps it to one reminder per session.

## [0.5.1] - 2026-10-06

### Fixed
- `verify.sh` blocked finishing when a repository's build failed because of the machine, not the code: a repo targeting an older Java built with a newer JDK fails with Lombok `IllegalAccessError ... does not export`. Environment failures (Lombok/JDK mismatch, unsupported class file version, invalid release, `JAVA_HOME`) are now a stderr warning and the repo is listed as "tests not run"; real test failures still block. Multi-repo verification (0.4.0) made this show up in sibling repos whose files were touched by a branch checkout.

## [0.5.0] - 2026-10-05

### Added
- "Main project" knowledge: an optional repository with the core business logic. `reference/modules.md` describes it; `session-start.sh` tells the agent in every other repository when `JAVA_TEAM_MAIN_PROJECT` is set; `project-init` writes a "Related repositories" section (new `{{RELATED_SECTION}}` in `templates/CLAUDE.md`) into each project's `CLAUDE.md`.

## [0.4.0] - 2026-10-05

### Added
- Workspace awareness: repositories sit next to each other in one folder (the parent of the project; override with `JAVA_TEAM_WORKSPACE`). `session-start.sh` prints the workspace, the module map path and a live scan (`scripts/scan-modules.sh`: branch, artifactId, which scanned artifacts each repo mentions in its `pom.xml`).
- `reference/modules.md`: module map template (main project, how repositories connect, list of repositories). A developer can override it with `<workspace>/modules.md` or `$JAVA_TEAM_MODULES_FILE`.
- `project-init` step 6a: writes `permissions.additionalDirectories` with the sibling repositories from the map that exist locally (never the whole workspace folder).

### Changed
- `format.sh`, `verify.sh`: module and `mvnw` are resolved from the repository of the changed file, and `verify.sh` runs tests in every workspace repository with changes made in the session (before: only the repo Claude started in).
- `snapshot.sh` also lists other repositories with uncommitted changes.
- `guard-bash.sh` applies its git rules to the repository a command targets (hook `cwd`, `cd <dir>` segments, `git -C <dir>`), not only to the project repo; `git -C <dir> commit/push/merge` is now matched too (before, `-C` hid the subcommand from the rules).
- `task-research` and `code-explorer` search the sibling repositories without asking for their locations.

## [0.3.5] - 2026-09-30

### Fixed
- Commits carried `Co-Authored-By: Claude ...` because the harness injects an attribution instruction that bypassed the `commit` skill rule. `guard-bash.sh` now blocks `git commit` whose message (inline or from `-F`/`--file`/`-t`) has Claude attribution (`Co-Authored-By: Claude`, `Claude-Session:`, "Generated with ... Claude", `noreply@anthropic.com`). New PostToolUse hook `strip-attribution.sh` removes such lines from an unpushed HEAD commit and reports if the commit is already on a remote.
- `templates/settings.json` sets `attribution.commit` and `attribution.pr` to empty, so projects created by `project-init` do not get the harness attribution. `templates/CLAUDE.md` and `reference/team-workflow.md` state the rule.

## [0.3.4] - 2026-09-30

### Fixed
- `task-interview` dumped its questions as plain text and asked for permission to start. It now asks through `AskUserQuestion` (1-4 questions per call, recommended default first) and starts immediately. `task-research` hands over to it without stopping.

## [0.3.3] - 2026-09-30

### Fixed
- `mark-onboarded.sh` wrote the flag to a temp dir when `CLAUDE_PLUGIN_DATA` was not set in the Bash tool, so the onboarding hint never stopped. It now finds the plugin data dir itself.

## [0.3.2] - 2026-09-30

### Added
- `mark-onboarded.sh --reset` and a demo section in `docs/install.md`.

## [0.3.1] - 2026-09-30

### Fixed
- Marketplace URL is SSH (`git@github.com:...`).
- `install.sh` stops with an explanation when the marketplace or plugin step fails, and falls back to the local clone.

## [0.3.0] - 2026-09-29

### Added
- `install.sh`: one-command setup (tool check, marketplace, plugin, environment hints).
- Skill `team-onboarding` and command `/java-team:onboarding`: guided tour for new developers.
- Command `/java-team:help`: cheat sheet.
- `SessionStart` hint pointing to onboarding (first 3 sessions until the tour is finished); `scripts/check-env.sh` and `scripts/mark-onboarded.sh`.

### Changed
- `docs/install.md` and `README.md` start with the quick start.

## [0.2.0] - 2026-09-29

### Added
- Network hosts in the sandbox allowlist are placeholders that `permissions-setup` fills in.
- Code style section of the `CLAUDE.md` template is filled by `project-init` (`{{STYLE_SECTION}}`).
- `reference/team-workflow.md` (branches, commits, PRs, DoD, database changes) used by `project-init`, `task-spec` and `java-reviewer`; `templates/pr-description.md`.
- `guard-bash.sh` now blocks commits on and pushes to protected branches (`main`, `master` and the ones listed in `JAVA_TEAM_PROTECTED_BRANCHES`).
- Review checklist items: Java level, code style, obsolete tests, database migrations, cross-repo order, commit naming.
- `spec.md` has a Delivery section (Java line, branch, database changes, merge order).

### Changed
- Settings template: `mvn -o` allowed; `changelog/` edits go through `ask`.

## [0.1.0] - 2026-09-29

### Added
- Skeleton of the `team-plugins` marketplace and the `java-team` plugin.
- Skills: `project-init`, `permissions-setup`, `task-research`, `task-interview`, `task-spec`, `session-summary` (ported from the owner's command together with `scripts/save_session.sh`).
- Subagents: `java-reviewer`, `code-explorer`, `test-writer`.
- Commands: `/java-team:review`, `/java-team:update-claude-md`.
- Hooks: `session-start`, `prompt-submit`, `guard-bash`, `guard-files`, `format`, `verify`, `snapshot`.
- MCP: Jira (Atlassian remote server) and DB (MySQL, read-only).
- Templates: `CLAUDE.md`, `spec.md`, `review-checklist.md`, `settings.json`.
- Test project `test-fixtures/sample-maven-project`.

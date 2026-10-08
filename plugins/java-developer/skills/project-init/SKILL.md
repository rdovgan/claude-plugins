---
name: project-init
description: Set up a Maven/Java project for Claude Code or update an existing setup - generates the CLAUDE.md hierarchy, project .claude/settings.json (permissions, sandbox, team marketplace) and .gitignore entries. Use only on an explicit request such as "initialize the project", "set up Claude for this repo", "update CLAUDE.md". Do not use for regular coding tasks or questions about code.
---

# project-init

Sets up a Maven project to work with the agent. All user-facing text is in English.

## Mode

- No `CLAUDE.md` in the root: **create** mode.
- `CLAUDE.md` exists: **update** mode. Never overwrite the file wholesale. Show the diff between the existing and generated content, keep manual sections, and change only blocks between `<!-- java-team:generated:start <section> -->` and `<!-- java-team:generated:end -->`. Never touch the "Manual notes" section.

## Steps

1. Determine the mode.
2. Scan the project by names and structure only, without reading sensitive files (the list is defined by `permissions-setup`): root `pom.xml` and modules; Java version (`maven.compiler.release`, `source`/`target`); Spring Boot and its version; key dependencies; build plugins (checkstyle, spotless, surefire, failsafe, jacoco, flyway, liquibase); presence of `./mvnw`; package structure; test frameworks.
2a. Read `${CLAUDE_PLUGIN_ROOT}/reference/team-workflow.md` for the workflow rules. If the repository maintains several Java lines on different branches, note them in the project section.
3. Generate the root `CLAUDE.md` from `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.md`, at most 150 lines. Build commands must be exact: `./mvnw` if the wrapper exists, otherwise `mvn`; for the whole project and per module (`-pl <module> -am`).
3a. Fill `{{RELATED_SECTION}}` from the module map (`<workspace>/modules.md`, `$JAVA_TEAM_MODULES_FILE`, or `${CLAUDE_PLUGIN_ROOT}/reference/modules.md`), at most 12 lines: the main project if the map names one and the rule "check how the main project uses a changed public method, event or contract"; the repositories this one uses or is used by (from its `pom.xml` and the live scan `${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh`), with the bottom-up order if relevant. If the map is empty and there are no sibling repositories, remove the section.
4. For a module with its own specifics (separate DB, integration, unusual structure) create a nested `CLAUDE.md` of at most 40 lines. Other modules get no file.
5. Invoke the `permissions-setup` skill.
6. Write the project's `.claude/settings.json`: add (without removing existing entries) `extraKnownMarketplaces` with the git URL of the `claude-plugins` repository and `enabledPlugins` with `java-developer@team-plugins`. The default URL is `git@github.com:rdovgan/claude-plugins.git`; ask the user to confirm it (decision D-07). The plugin was called `java-team` before 0.8.0: if `enabledPlugins` has `java-team@team-plugins`, replace it with `java-developer@team-plugins` and tell the user.
6a. Let the agent reach sibling repositories: set `permissions.additionalDirectories` in `.claude/settings.json` to `../<repo>` for every repository named in `${CLAUDE_PLUGIN_ROOT}/reference/modules.md` that exists next to the project (check with `ls ..`; never add the workspace folder `..` itself, it holds unrelated files such as tokens and exports). The `deny` rules and plugin hooks apply to these directories too, but their own `.claude/settings.json` and `CLAUDE.md` are not loaded.
7. Add to `.gitignore` (no duplicates): `.claude/settings.local.json`, `.claude/specs/`, `CLAUDE.local.md`.
8. **Before writing**, show a summary of changes (files, diff) and wait for confirmation.

Fill `{{STYLE_SECTION}}` with the team's code style: take it from the module map or the user if given, otherwise from the project's checkstyle/spotless/`.editorconfig` rules (names and settings only); if none exist, write that no formatter is configured and ask the user for the conventions to record. Do not infer style from sampling code.

## Idempotence

Re-running without project changes must not modify any file: compare generated content with existing and skip identical parts.

## Prohibitions

- Do not read or print the contents of files that `permissions-setup` classifies as sensitive.
- Do not create `AGENTS.md`.
- Do not modify `~/.claude/settings.json`.

# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/), versions follow semver. Every behavior change bumps the version in `plugin.json`.

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

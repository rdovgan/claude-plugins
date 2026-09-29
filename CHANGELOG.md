# Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/), версії за semver. Кожна зміна поведінки плагіна піднімає версію в `plugin.json`.

## [0.1.0] - 2026-09-29

### Added
- Каркас маркетплейсу `team-plugins` і плагіна `java-team`.
- Скіли: `project-init`, `permissions-setup`, `task-research`, `task-interview`, `task-spec`, `session-summary` (заглушка, чекає на файли власника).
- Сабагенти: `java-reviewer`, `code-explorer`, `test-writer`.
- Команди: `/java-team:review`, `/java-team:update-claude-md`.
- Хуки: `session-start`, `prompt-submit`, `guard-bash`, `guard-files`, `format`, `verify`, `snapshot`.
- MCP: Jira (віддалений сервер Atlassian) і БД (лише читання).
- Шаблони: `CLAUDE.md`, `spec.md`, `review-checklist.md`, `settings.json`.
- Тестовий проєкт `test-fixtures/sample-maven-project`.

---
name: project-init
description: Set up a Maven/Java project for Claude Code or update an existing setup - generates the CLAUDE.md hierarchy, project .claude/settings.json (permissions, sandbox, team marketplace) and .gitignore entries. Use only on an explicit request such as "initialize the project", "set up Claude for this repo", "update CLAUDE.md". Do not use for regular coding tasks or questions about code.
---

# project-init

Налаштовує Maven-проєкт для роботи з агентом. Усі тексти для команди — українською.

## Режим

- Немає `CLAUDE.md` у корені — **створення**.
- Є — **оновлення**: не перезаписуй файл цілком. Покажи різницю між наявним і згенерованим, збережи ручні розділи, змінюй лише блоки між `<!-- java-team:generated:start <розділ> -->` і `<!-- java-team:generated:end -->`. Розділ «Ручні нотатки» не чіпай ніколи.

## Кроки

1. Визнач режим.
2. Просканувати проєкт лише за іменами й структурою, без читання чутливих файлів (перелік визначає `permissions-setup`): кореневий `pom.xml` і модулі; версія Java (`maven.compiler.release`, `source`/`target`); Spring Boot і версія; ключові залежності; плагіни збірки (checkstyle, spotless, surefire, failsafe, jacoco, flyway, liquibase); наявність `./mvnw`; структура пакетів; тестові фреймворки.
3. Згенеруй кореневий `CLAUDE.md` за `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.md`. Файл — до 150 рядків. Команди збірки — точні: `./mvnw`, якщо wrapper є, інакше `mvn`; для всього проєкту і для модуля (`-pl <модуль> -am`).
4. Для модуля зі своєю специфікою (окрема БД, інтеграція, нетипова структура) створи вкладений `CLAUDE.md` до 40 рядків. Решта модулів файлу не отримують.
5. Виклич скіл `permissions-setup`.
6. Запиши `.claude/settings.json` проєкту: додай (не видаляючи наявного) `extraKnownMarketplaces` з git-адресою репозиторію `claude-plugins` і `enabledPlugins` з `java-team@team-plugins`. Git-адресу запитай у користувача, якщо її не відомо.
7. Додай у `.gitignore` (без дублікатів): `.claude/settings.local.json`, `.claude/specs/`, `CLAUDE.local.md`.
8. **До запису** покажи підсумок змін (файли, різниця) і чекай підтвердження.

## Ідемпотентність

Повторний запуск без змін у проєкті не має змінювати жодного файлу: порівнюй згенероване з наявним і пропускай однакове.

## Заборони

- Не читай і не виводь вміст файлів, які `permissions-setup` визначає як чутливі.
- Не створюй `AGENTS.md`.
- Не змінюй `~/.claude/settings.json`.

# claude-plugins

Командний маркетплейс Claude Code для Java-команди (`team-plugins`) із плагіном `java-team`.

Плагін: ініціалізація Maven-проєкту (`CLAUDE.md`, дозволи, пісочниця), захист секретів, хуки перевірок, процес задачі (дослідження → інтерв'ю → специфікація → реалізація → рев'ю), сабагенти, MCP для Jira і БД.

- Встановлення: [docs/install.md](docs/install.md)
- Рішення й розбіжності: [docs/decisions.md](docs/decisions.md)
- Історія змін: [CHANGELOG.md](CHANGELOG.md)
- Вимоги: `Вимоги до командного плагіна Claude Code для Java-команди.md`

Зміни плагіна — лише через PR із рев'ю техліда. Кожна зміна поведінки піднімає `version` у `plugins/java-team/.claude-plugin/plugin.json` і додає запис у CHANGELOG. Перед релізом: `claude plugin validate .` і `claude plugin validate plugins/java-team`, `shellcheck plugins/java-team/hooks/scripts/*.sh`.

## Структура

```
.claude-plugin/marketplace.json
plugins/java-team/   skills, agents, commands, hooks, templates, .mcp.json
test-fixtures/       sample-maven-project для перевірки приймання
docs/
```

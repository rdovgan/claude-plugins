# claude-plugins

Командний маркетплейс Claude Code для Java-команди (`team-plugins`) із плагіном `java-team`.

Плагін: ініціалізація Maven-проєкту (`CLAUDE.md`, дозволи, пісочниця), захист секретів, хуки перевірок, процес задачі (дослідження → інтерв'ю → специфікація → реалізація → рев'ю), сабагенти, MCP для Jira і БД.

- Встановлення: [docs/install.md](docs/install.md)
- Рішення й розбіжності: [docs/decisions.md](docs/decisions.md)
- Історія змін: [CHANGELOG.md](CHANGELOG.md)
- Вимоги: `Вимоги до командного плагіна Claude Code для Java-команди.md`

Зміни плагіна — лише через PR із рев'ю техліда. Кожна зміна поведінки піднімає `version` у `plugins/java-team/.claude-plugin/plugin.json` і додає запис у CHANGELOG. Перед релізом: `claude plugin validate .` і `claude plugin validate plugins/java-team`, `shellcheck plugins/java-team/hooks/scripts/*.sh`.

## Як користуватись

### Одноразово на машині розробника

1. Встанови `jq`, `git`, `mvn` (або використовуй `./mvnw` проєкту).
2. Підключи маркетплейс і плагін:
   ```
   /plugin marketplace add <git-адреса цього репозиторію>
   /plugin install java-team@team-plugins
   ```
3. Задай змінні середовища (деталі в [docs/install.md](docs/install.md)):
   - `JAVA_TEAM_VAULT` — тека Obsidian-сховища для `session-summary`;
   - `JAVA_TEAM_DB_URL` (`mysql://host:3306/db`), `JAVA_TEAM_DB_USER`, `JAVA_TEAM_DB_PASSWORD` — лише для доступу до БД; без них сервер БД просто не стартує.
4. У Claude Code виконай `/mcp` і пройди OAuth для `jira`.

### У кожному проєкті

1. Відкрий проєкт у `claude` і скажи: «ініціалізуй проєкт».
2. `project-init` просканує Maven-проєкт, покаже підсумок і після підтвердження створить `CLAUDE.md` (кореневий і модульні), `.claude/settings.json` і записи в `.gitignore`. Хости Nexus, git і Jira він запитає під час ініціалізації.
3. Закоміть `CLAUDE.md` і `.claude/settings.json`; колеги отримають плагін автоматично.

### Щоденна робота

Просто дай задачу: ключ Jira (`ABC-123`), посилання або опис. Агент сам веде фази:

| Фаза | Що відбувається |
| --- | --- |
| Дослідження (`task-research`) | Читає задачу з Jira, шукає код через `code-explorer`, код не змінює |
| Інтерв'ю (`task-interview`) | Ставить конкретні питання групами до 5 |
| Специфікація (`task-spec`) | Пише `.claude/specs/<ключ>.md` (не комітиться), чекає вашого підтвердження |
| Реалізація | Крок за кроком у режимі plan; `test-writer` пише тести |
| Самоперевірка й рев'ю | `/java-team:review` запускає `java-reviewer` на змінах гілки |

Що працює автоматично:

- **Захист:** секрети, `.env*`, прод-конфіги й ключі недоступні для читання; `git push --force`, push у `main`/`master`, `mvn deploy`, `rm -rf` поза `target/` блокуються з поясненням.
- **Форматування:** після правки `.java` запускається форматер і checkstyle, якщо вони є в `pom.xml`.
- **Перевірка при завершенні:** тести змінених модулів; при падінні агент не завершує роботу. Потім один раз нагадає про `session-summary`.
- **Відновлення:** при старті сесії агент бачить гілку, ключ Jira, специфікацію і останній знімок стану.

### Команди

| Команда | Дія |
| --- | --- |
| `/java-team:review` | Рев'ю змін поточної гілки |
| `/java-team:update-claude-md` | Оновити `CLAUDE.md` і налаштування, зберігши ручні розділи |

Скіли `session-summary` і `permissions-setup` можна викликати і напряму («збережи сесію», «налаштуй дозволи»).

### Корисне

- `JAVA_TEAM_SKIP_VERIFY=1 claude` — вимкнути тести при завершенні (дослідження без змін коду).
- Особисті винятки дозволів — у `.claude/settings.local.json` (у `.gitignore`).
- Ручні нотатки в `CLAUDE.md` пиши під «Ручні нотатки»: `project-init` їх не чіпає.

## Розробка плагіна

## Структура

```
.claude-plugin/marketplace.json
plugins/java-team/   skills, agents, commands, hooks, templates, .mcp.json
test-fixtures/       sample-maven-project для перевірки приймання
docs/
```

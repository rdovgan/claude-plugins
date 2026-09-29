---
name: permissions-setup
description: Find sensitive files by name in a Maven project and configure permissions and sandbox in the project's .claude/settings.json. Use when called from project-init or on an explicit request such as "set up permissions". Do not use for regular coding tasks.
---

# permissions-setup

Знаходить чутливі файли й налаштовує дозволи та пісочницю. **Вміст чутливих файлів не читати і не виводити ніколи.**

## Кроки

1. Знайди за іменами (`find`/Glob, без читання вмісту): `.env*`; `application-*.yml`, `application-*.yaml` і `application-*.properties`, крім `application-test*` і `application-local*`; `*.pem`, `*.key`, `*.p12`, `*.jks`, `*.keystore`; `secrets/`; `credentials*`; дампи `*.sql.gz`, `*.dump`.
2. Для `application.yml` і `application.properties` перевір `grep -c -i -E 'password|secret|token|api-key'` (лише кількість збігів, без виводу рядків і значень). Якщо є збіги — запропонуй `deny` для файлу.
3. Об'єднай знайдене з базовим набором `${CLAUDE_PLUGIN_ROOT}/templates/settings.json`. Заміни плейсхолдери мережі `<NEXUS_HOST>`, `<GIT_HOST>`, `<JIRA_HOST>` реальними хостами (запитай у користувача, що невідомо; невідомі рядки прибери, не залишай плейсхолдерів).
4. Покажи користувачу список правил із поясненням кожного й чекай підтвердження.
5. Запиши в `.claude/settings.json`, не видаляючи наявних правил (злиття масивів без дублікатів).

## Рівні файлів

- `.claude/settings.json` — генерується, комітиться.
- `.claude/settings.local.json` — особисті винятки, у `.gitignore`.
- `~/.claude/settings.json` не змінюй.

## Вивід

Показуй лише шляхи й імена файлів та правила. Ніколи не показуй значення з файлів.

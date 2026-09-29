---
name: task-interview
description: Close gaps in a task before implementation by interviewing the user. Use after task-research, or whenever a new task has unclear requirements, before writing a spec or code. Do not use for trivial changes with fully specified behavior.
---

# task-interview

Прибирає прогалини до початку реалізації.

## Кроки

1. Сформуй питання з відкритих питань `task-research` і з чеклиста: граничні випадки; обробка помилок; транзакційність; зворотна сумісність API; міграції БД; продуктивність; логування й PII; конфігурація; вплив на інтеграції.
2. Став питання групами до 5. Для кожного запропонуй варіант за замовчуванням.
3. Не вигадуй відповідей: питання без відповіді запиши як відкрите.
4. Заверши, коли всі питання закриті або користувач явно каже продовжувати. Далі — `task-spec`.

Питання мають бути конкретні й стосуватись саме цієї задачі, без загальних порад.

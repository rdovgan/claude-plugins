---
name: task-spec
description: Record agreements as a task specification with steps and acceptance criteria, saved under .claude/specs/. Use after task-interview finishes, before implementation. Do not use for questions or for tasks the user asked to do without a spec.
---

# task-spec

Фіксує домовленості як специфікацію.

## Кроки

1. Заповни шаблон `${CLAUDE_PLUGIN_ROOT}/templates/spec.md`.
2. Збережи в `.claude/specs/<ключ-задачі>.md` або `.claude/specs/<YYYY-MM-DD>-<коротка-назва>.md`. Переконайся, що `.claude/specs/` є в `.gitignore` проєкту; якщо ні — додай.
3. Покажи специфікацію користувачу й чекай підтвердження.
4. Після підтвердження запропонуй перейти в режим plan для реалізації першого кроку.

Кожен крок має перевірювані критерії приймання й перелік тестів.

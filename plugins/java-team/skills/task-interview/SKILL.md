---
name: task-interview
description: Close gaps in a task before implementation by interviewing the user. Use after task-research, or whenever a new task has unclear requirements, before writing a spec or code. Do not use for trivial changes with fully specified behavior.
---

# task-interview

Removes gaps in the task before implementation starts.

## Steps

1. Build questions from the open questions of `task-research` and from the checklist: edge cases; error handling; transactionality; API backward compatibility; DB migrations; performance; logging and PII; configuration; impact on integrations.
2. Ask in groups of up to 5 questions. Offer a default answer for each.
3. Do not invent answers: an unanswered question is recorded as open.
4. Finish when all questions are closed or the user explicitly says to continue. Then go to `task-spec`.

Each question must be concrete and specific to this task, not generic advice.

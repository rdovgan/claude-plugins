---
name: task-interview
description: Close gaps in a task before implementation by interviewing the user. Use after task-research, or whenever a new task has unclear requirements, before writing a spec or code. Do not use for trivial changes with fully specified behavior.
allowed-tools: AskUserQuestion
---

# task-interview

Removes gaps in the task before implementation starts. The interview is **interactive**: every question is asked with the `AskUserQuestion` tool, never as a list in plain text.

## Steps

1. Build questions from the open questions of `task-research` and from the checklist: edge cases; error handling; transactionality; API backward compatibility; DB migrations; performance; logging and PII; configuration; impact on integrations. Drop the ones the code or the ticket already answers.
2. Load `AskUserQuestion` with `ToolSearch("select:AskUserQuestion")` if its schema is not available, then call it right away. Do not print the questions in text first and do not ask "shall I start?". Invoking this skill is the go-ahead.
3. Ask 1-4 questions per call, ordered so that the answer to one can change the next: first questions that decide where the change lives, then the details. Ask dependent questions in a later call.
4. Every question has 2-4 options with a short description. Put the recommended default first and mark it `(Recommended)`. The user can always pick "Other" for free text.
5. Something only the user can provide (a log, a response body, a header dump) cannot be an option. Ask for it as a plain-text request after the choice questions, and record it as open if the user skips it.
6. Do not invent answers: an unanswered or skipped question is recorded as open.
7. If the user declines the tool call, stop and wait for their instruction. Do not fall back to a text list of questions.
8. Finish when all questions are closed or the user explicitly says to continue. Then go to `task-spec`.

Each question must be concrete and specific to this task, not generic advice.

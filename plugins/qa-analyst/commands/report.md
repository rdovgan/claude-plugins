---
description: Write the report of a task in the selected formats - summary, tests, impact, decision, logs, regression, confluence, visual - from what the conversation established. Run when the questions are settled; the REPORT button in the formats row runs it too.
argument-hint: [Jira key | task folder] [--summary] [--tests] [--impact] [--decision] [--logs] [--regression] [--visual] [--confluence]
---

Write the report: $ARGUMENTS

Until now this was a conversation: questions, clarifications, answers in chat. Now the user wants the result as documents. Do not change any code.

1. **Task.** A Jira key or a folder name in `$ARGUMENTS`; otherwise the task this conversation is about; otherwise the most recently changed folder in `.claude/qa-analysis/`. If none of these is clear, ask with `AskUserQuestion`. Say which task you took.
2. **Formats.** The flags in `$ARGUMENTS` (`--summary`, `--tests`, ...) when there are any; otherwise the formats selected now (the line "formats selected now" in the context, else the session start list). If no format is selected, ask with `AskUserQuestion` (multi-select) which ones to write.
3. Run the `analysis-report` skill for that task with exactly those formats. It writes nothing else.
4. Finish with one short message in plain language: the folder path, the answer in one or two sentences, the files written, the artifact link if `visual` ran, and the open questions. Do not paste the documents.

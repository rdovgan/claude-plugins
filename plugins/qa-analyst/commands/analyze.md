---
description: QA analysis of a task end to end - research (ticket, requirements, logs, DB, code), interview, then plain-language documents with the answer, flows, findings, test scenarios and ticket notes. Does not change code.
argument-hint: <Jira key | ticket link | description | path to a log file>
---

Analyse this task for QA: $ARGUMENTS

This is an analysis-only run for a QA engineer. You never change code, tests, configs or the build in any repository. The only files you write are the documents in `.claude/qa-analysis/<task>/`.

The reader is a QA engineer, possibly not technical. The documents say what happens, whether it is a bug, why, what to test and what to write in the ticket, in plain language. They carry no code examples and no instructions on how to implement or fix anything; code is evidence you read, and file names appear only in the technical references for developers.

1. Pick the task folder name: the Jira key (`ABC-123`) if there is one, otherwise `<YYYY-MM-DD>-<short-name>`. If `.claude/qa-analysis/<name>/` already exists, read it and continue from where it stops instead of starting over.
2. Run the three phases in order, each through its skill, without asking "shall I continue" between them. The one stop is at the start of the interview, where the user confirms your understanding of the task before the report is written. Take the time research needs: a correct answer is the goal, not a fast one.
   - `analysis-research` -> writes `01-research.md`
   - `analysis-interview` -> writes `02-interview.md`
   - `analysis-report` -> writes `03-flows.md`, `04-findings.md`, `05-test-scenarios.md`, `06-ticket-notes.md` and `00-README.md`
3. Finish with one short message in plain language: the folder path, the answer in one or two sentences (the verdict), what QA should do next, and the open questions that still need an answer. Do not paste the documents.

If `$ARGUMENTS` is empty, ask the user for the task with `AskUserQuestion`.

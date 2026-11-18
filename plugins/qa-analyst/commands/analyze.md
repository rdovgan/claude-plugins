---
description: Full QA analysis in one go - research (ticket, requirements, logs, DB, code), interview, then the report in the selected formats. For questions and clarifications just ask in chat; for a report of what the conversation settled use /qa-analyst:report. Does not change code.
argument-hint: <Jira key | ticket link | description | path to a log file> [--summary] [--tests] [--impact] [--decision] [--logs] [--regression] [--visual] [--confluence]
---

Analyse this task for QA: $ARGUMENTS

This is an analysis-only run for a QA engineer. You never change code, tests, configs or the build in any repository. The only files you write are the documents in `.claude/qa-analysis/<task>/`.

The reader is a QA engineer, possibly not technical. The documents say what happens, whether it is a bug, why, what to test and what to write in the ticket, in plain language. They carry no code examples and no instructions on how to implement or fix anything; code is evidence you read, and file names appear only in the technical references for developers.

1. Pick the task folder name: the Jira key (`ABC-123`) if there is one, otherwise `<YYYY-MM-DD>-<short-name>`. If `.claude/qa-analysis/<name>/` already exists, read it and continue from where it stops instead of starting over.
2. Run the three phases in order, each through its skill, without asking "shall I continue" between them. The one stop is at the start of the interview, where the user confirms your understanding of the task before the report is written. Take the time research needs: a correct answer is the goal, not a fast one.
   - `analysis-research` -> writes `01-research.md`
   - `analysis-interview` -> writes `02-interview.md`
   - `analysis-report` -> writes the report in the formats of this run (step 3)
3. **Formats of this run.** The flags `--summary`, `--tests`, `--impact`, `--decision`, `--logs`, `--regression`, `--visual`, `--confluence` in `$ARGUMENTS` when there are any (strip them from the task text); otherwise the formats selected now (the line "formats selected now" in the context, else the session start list). Any combination can be on at once. `analysis-report` writes exactly those and nothing else.
4. Finish with one short message in plain language: the folder path, the answer in one or two sentences (the verdict), what QA should do next, the open questions that still need an answer, the files written, and the artifact link if `visual` ran. Do not paste the documents.

If `$ARGUMENTS` is empty, ask the user for the task with `AskUserQuestion`.

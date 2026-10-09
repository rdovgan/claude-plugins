---
description: Analyse a task end to end - research, interview, flow charts, findings, proposed solutions - as local documents. Does not change code.
argument-hint: <Jira key | ticket link | task description>
---

Analyse this task: $ARGUMENTS

This is an analysis-only run. You never change code, tests, configs or the build in any repository. The only files you write are the documents in `.claude/analysis/<task>/`.

1. Pick the task folder name: the Jira key (`ABC-123`) if there is one, otherwise `<YYYY-MM-DD>-<short-name>`. If `.claude/analysis/<name>/` already exists, read it and continue from where it stops instead of starting over.
2. Run the three phases in order, each through its skill, without asking "shall I continue" between them. The one stop is at the start of the interview, where the developer confirms your understanding of the task before the report is written. Take the time research needs: a thorough analysis is the goal, not a fast one.
   - `analysis-research` -> writes `01-research.md`
   - `analysis-interview` -> writes `02-interview.md`
   - `analysis-report` -> writes `03-flows.md`, `04-findings.md`, `05-proposals.md`, `06-implementation-guide.md` and `00-README.md`
3. Finish with one short message: the folder path, the recommended solution in one sentence, and the open questions that still need an answer. Do not paste the documents.

If `$ARGUMENTS` is empty, ask the developer for the task with `AskUserQuestion`.

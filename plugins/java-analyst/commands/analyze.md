---
description: Full analysis in one go - research, interview, then the report in the selected formats. For questions and clarifications just ask in chat; for a report of what the conversation settled use /java-analyst:report. Does not change code.
argument-hint: <Jira key | ticket link | task description> [--summary] [--dev] [--visual] [--confluence]
---

Analyse this task: $ARGUMENTS

This is an analysis-only run. You never change code, tests, configs or the build in any repository. The only files you write are the documents in `.claude/analysis/<task>/`.

1. Pick the task folder name: the Jira key (`ABC-123`) if there is one, otherwise `<YYYY-MM-DD>-<short-name>`. If `.claude/analysis/<name>/` already exists, read it and continue from where it stops instead of starting over.
2. Run the three phases in order, each through its skill, without asking "shall I continue" between them. The one stop is at the start of the interview, where the developer confirms your understanding of the task before the report is written. Take the time research needs: a thorough analysis is the goal, not a fast one.
   - `analysis-research` -> writes `01-research.md`
   - `analysis-interview` -> writes `02-interview.md`
   - `analysis-report` -> writes the report in the formats of this run (step 3)
3. **Formats of this run.** The flags `--summary`, `--dev`, `--visual`, `--confluence` in `$ARGUMENTS` when there are any (strip them from the task text); otherwise the formats selected now (the line "formats selected now" in the context, else the session start list). `analysis-report` writes exactly those and nothing else.
4. Finish with one short message: the folder path, the recommended solution in one sentence, the open questions that still need an answer, and the files written (and the artifact link if `visual` ran). Do not paste the documents.

If `$ARGUMENTS` is empty, ask the developer for the task with `AskUserQuestion`.

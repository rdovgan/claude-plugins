---
description: Write the report of a task in the selected formats - pr (PR description), qa (QA handoff), review (self-review), summary (session note) - when the work is done. The REPORT button in the formats row runs it too.
argument-hint: [Jira key] [--pr] [--qa] [--review] [--summary]
---

Write the report: $ARGUMENTS

1. **Task.** A Jira key in `$ARGUMENTS`; otherwise the key from the branch name; otherwise the task this conversation is about. If none is clear, ask with `AskUserQuestion`.
2. **Formats.** The flags in `$ARGUMENTS` when there are any; otherwise the formats selected now (the line "formats selected now" in the context, else the session start list). If none is selected, ask with `AskUserQuestion` (multi-select) which ones to write.
3. Run the `task-report` skill for that task with exactly those formats.
4. Finish with one short message: the folder `.claude/reports/<KEY>/`, the files written (and the vault note for `summary`), the review verdict if `review` ran, and anything not done yet (failing tests, open criteria). Do not paste the documents.

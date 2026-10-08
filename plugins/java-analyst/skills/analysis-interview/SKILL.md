---
name: analysis-interview
description: Phase 2 of an analysis - close the gaps in a task by interviewing the developer, and write 02-interview.md. Run by /java-analyst:analyze after analysis-research; also use whenever a task has unclear requirements.
allowed-tools: AskUserQuestion, Read, Write
---

# analysis-interview

Phase 2. **No code changes.** The interview is **interactive**: every question is asked with the `AskUserQuestion` tool, never as a list in plain text. The only file you write is `.claude/analysis/<task>/02-interview.md`.

## Steps

1. Build questions from the open questions of `01-research.md` and from this checklist: edge cases; error handling; transactionality; API backward compatibility; DB changes and migrations; performance; logging and PII; configuration; impact on integrations and on the main project (if the module map names one); which Java version and branch. Drop what the code or the ticket already answers.
2. Load `AskUserQuestion` with `ToolSearch("select:AskUserQuestion")` if its schema is not available, then call it right away. Invoking this skill is the go-ahead; do not print the questions first and do not ask "shall I start?".
3. Ask 1-4 questions per call, ordered so an answer can change the next: first what decides where the change lives, then details. Dependent questions go in a later call.
4. Every question has 2-4 options with a short description, the recommended default first, marked `(Recommended)`. "Other" for free text is always available. Put the reason behind the recommendation in the option description.
5. Something only the developer can provide (a log, a response body) cannot be an option: ask for it as a plain-text request after the choice questions and record it as open if skipped.
6. Never invent answers. An unanswered or skipped question is recorded as open.
7. If the developer declines the tool call, stop and wait. Do not fall back to a text list.
8. Finish when all questions are closed or the developer says to continue. Fill `${CLAUDE_PLUGIN_ROOT}/templates/analysis/02-interview.md` and save it to `.claude/analysis/<task>/02-interview.md`: each question, the options offered, the decision and its reason, then the open questions.

Questions must be concrete and specific to this task, not generic advice. Then continue with `analysis-report` in the same turn.

---
description: Cheat sheet - what the qa-analyst plugin does and how to use it
---

Output exactly this cheat sheet, then stop:

**What it is** - an analysis assistant for QA. Ask it about a ticket, a requirement or a log; it reads the Jira ticket and the Confluence pages with the requirements, the logs, the database (read-only) and the code, and answers in plain language: what happens, is it a bug, what to test, what to write in the ticket. **No code examples and no fix instructions**, and it **never changes code**. Documentation (`.md`, `.txt`, ...), `CLAUDE.md` and `.claude/` files it can write, so `/init` works.

**First time:** `/qa-analyst:setup` (shows which project settings are missing and adds them after you confirm), then `/qa-analyst:onboarding` (3-minute tour).

**Talk first.** Just ask: "what does ABC-123 change for partners?", "is this a bug or expected?", "why did booking 4711 fail at 14:05?". Answers come in chat, no documents, so a quick question costs little. What is settled is kept in a few lines in `.claude/qa-analysis/<task>/notes.md`, so the next session goes on from there.

**Report when you are done.** Pick the formats in the `formats` row above the prompt (violet = on; a click switches), then press the yellow **▶ REPORT** button, run `/qa-analyst:report [task]`, or just say "make the report". Only the selected formats are written, and only they are checked. For one run, flags replace the selection: `/qa-analyst:report ABC-123 --impact`. `/qa-analyst:present <format> [task]` adds one more format later. `/qa-analyst:analyze ABC-123` is the full run in one go: research, interview (answers with the keyboard), report.

**Formats** (switch on for good: click in the `formats` row or `/plugin configure qa-analyst@team-plugins`; any combination; files land in `.claude/qa-analysis/<task>/`, local, not committed):

| Format | Flag | For whom | Result |
| --- | --- | --- | --- |
| summary | `--summary` | QA, facts first | `00-README.md` (the answer, next steps, open questions), `03-flows.md` (flow charts: now and as required), `04-findings.md` (evidence, cause, impact, requirements coverage, technical references), `06-ticket-notes.md` (bug report or ticket comment to paste); on by default |
| tests | `--tests` | QA who run the checks | `05-test-cases.md`: test cases `TC-*` with requirements, type, priority, preconditions, test data, steps with an expected result on each step; on by default |
| impact | `--impact` | QA, PM, lead deciding priority | `07-impact.md`: affected records in numbers by status, partner and day, a `SELECT` behind each number, conclusions on size, trend and severity |
| decision | `--decision` | QA testing logic with many conditions | `08-decision-table.md`: combinations of conditions with the expected result (`R*`) and today's, status transitions, gaps in the requirements |
| logs | `--logs` | QA on incidents | `09-log-stats.md`: errors by type and hour, first and last time, lined up with deploys and commits, conclusions |
| regression | `--regression` | QA on a fix check or a release | `10-regression.md`: what changed in the code, areas to retest by priority, a checklist |
| visual | `--visual` | those who read visually | interactive page: verdict, diagrams, timeline, requirements chart, checklist of test cases, ticket text with a copy button; details open on hover. Published as a private Artifact on claude.ai; personal data is masked |
| confluence | `--confluence` | BA, PM, the whole team | `confluence-page.md`: a plain overview with the main cases, impact, decisions and open questions, ready to paste into Confluence |

Working files, never checked: `notes.md` (the conversation's record), `01-research.md` and `02-interview.md` (written by `/qa-analyst:analyze`).

**Logs:** give a path (`~/Downloads/app.log, why did booking 4711 fail?`), paste a fragment, or attach it to the Jira ticket (downloaded with your Jira API token). Big logs are read by the `log-reader` agent; personal data is masked in the documents.

**Rules that will stop the agent:** no writes to source code, tests, build files (`pom.xml`, `package.json`) or application configs; writes only inside the project; only read-only shell commands (`ls`, `grep`, `zgrep`, `sed -n`, `git log/diff/show`, ...); no reading `.env`/prod configs; Jira, Confluence and the DB are read-only (DB: one `SELECT` per call); the documents must not contain program code.

**Tips:** in `/qa-analyst:analyze` the interview starts by showing how the task was understood: correct it there, it is the cheapest moment; it does not ask what the ticket or Confluence already answer, so a short interview is normal; requirements get ids (`R1`, `R2`, ...) and test cases (`TC-1`, `TC-2`, ...) that every document refers to; documents are written in the language you use. To continue a task, mention its key: the notes are read first. `QA_ANALYST_OFF=1 claude` switches the guards off for work outside this plugin's purpose.

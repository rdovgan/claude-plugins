---
description: Cheat sheet - what the qa-analyst plugin does and how to use it
---

Output exactly this cheat sheet, then stop:

**What it is** - an analysis assistant for QA. You give it a ticket, a question or a log; it reads the Jira ticket and the Confluence pages with the requirements, the logs, the database (read-only) and the code, asks you what the sources do not answer, and writes plain-language documents: what happens, is it a bug, what to test, what to write in the ticket. **No code examples and no fix instructions**, and it **never changes code**. Documentation (`.md`, `.txt`, ...), `CLAUDE.md` and `.claude/` files it can write, so `/init` works.

**First time:** `/qa-analyst:setup` (shows which project settings are missing and adds them after you confirm), then `/qa-analyst:onboarding` (3-minute tour).

**Start:** `/qa-analyst:analyze ABC-123` (or a ticket link, a description, or a path to a log file). Good inputs: "is this a bug or expected?", "why did booking 4711 fail at 14:05?", "what must I test for ABC-123?", "check the fix for ABC-123".

**What you get** in `.claude/qa-analysis/<task>/` (local, not committed):

| File | Content |
| --- | --- |
| `00-README.md` | the answer (verdict), what to do next, reading order, open questions |
| `01-research.md` | the task, requirements `R*`, sources read, evidence from logs and the DB |
| `02-interview.md` | questions asked and decisions made |
| `03-flows.md` | business flow charts: how it works now and how it should work |
| `04-findings.md` | conclusions with evidence: cause, impact, what to retest, requirements coverage; technical references for developers at the end |
| `05-test-cases.md` | test cases `TC-*`, always: requirements, type, priority, preconditions, test data, steps with an expected result on each step |
| `06-ticket-notes.md` | ready-to-paste texts: bug report or ticket comment, questions to the developer or analyst |

**Output formats** (switch on for good: `/plugin configure qa-analyst@team-plugins` or click a format in the `formats` row above the prompt; for one run: add the flag; for a finished analysis: `/qa-analyst:present <format> [task]`):

| Format | Flag | For whom | Result |
| --- | --- | --- | --- |
| documents | always | QA, facts first | the seven files above |
| visual | `--visual` | those who read visually | interactive page: verdict, diagrams, timeline, requirements chart, checklist of test cases, ticket text with a copy button; details open on hover. Published as a private Artifact on claude.ai; personal data is masked |
| confluence | `--confluence` | BA, PM, the whole team | `confluence-page.md`: a plain overview with the main cases, impact, decisions and open questions, ready to paste into Confluence |

**Logs:** give a path (`/qa-analyst:analyze ~/Downloads/app.log booking 4711`), paste a fragment, or attach it to the Jira ticket (downloaded with your Jira API token). Big logs are read by the `log-reader` agent; personal data is masked in the documents.

**Rules that will stop the agent:** no writes to source code, tests, build files (`pom.xml`, `package.json`) or application configs; writes only inside the project; only read-only shell commands (`ls`, `grep`, `zgrep`, `sed -n`, `git log/diff/show`, ...); no reading `.env`/prod configs; Jira, Confluence and the DB are read-only (DB: one `SELECT` per call); the documents must not contain program code.

**Tips:** the interview starts by showing how the task was understood: correct it there, it is the cheapest moment; it does not ask what the ticket or Confluence already answer, so a short interview is normal; requirements get ids (`R1`, `R2`, ...) and test cases (`TC-1`, `TC-2`, ...) that every document refers to; documents are written in the language you use. To continue an analysis, run the command again with the same key. `QA_ANALYST_OFF=1 claude` switches the guards off for work outside this plugin's purpose.

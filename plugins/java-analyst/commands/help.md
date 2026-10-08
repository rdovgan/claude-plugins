---
description: Cheat sheet - what the java-analyst plugin does and how to use it
---

Output exactly this cheat sheet, then stop:

**What it is** - an analysis-only assistant. You give it a task; it researches the code, interviews you, and writes documents. It **never changes code**: you implement, using the documents as a guide. Documentation (`.md`, `.txt`, ...), `CLAUDE.md` and `.claude/` files it can write, so `/init` works.

**First time:** `/java-analyst:setup` (shows which project settings are missing and adds them after you confirm), then `/java-analyst:onboarding` (3-minute tour).

**Start:** `/java-analyst:analyze ABC-123` (or a ticket link, or a plain description).

**What you get** in `.claude/analysis/<task>/` (local, not committed):

| File | Content |
| --- | --- |
| `00-README.md` | summary, recommended solution, reading order, open questions |
| `01-research.md` | the task and where it lives in the code |
| `02-interview.md` | questions asked and decisions made |
| `03-flows.md` | flow charts (current and proposed) |
| `04-findings.md` | conclusions about the code: risks, pitfalls, legacy, impact on other repos |
| `05-proposals.md` | solution options with trade-offs, a recommendation, code examples |
| `06-implementation-guide.md` | step-by-step plan with acceptance criteria and tests, for you to implement |

**Rules that will stop the agent:** no writes to source code, tests, build files (`pom.xml`, `package.json`) or application configs; writes only inside the project; only read-only shell commands (`ls`, `grep`, `sed -n`, `git log/diff/show`, `npm ls`, ...); no reading `.env`/prod configs; Jira and the DB are read-only.

**Tips:** answer the interview questions honestly, since the proposals depend on them; documents are written in the language you use. To continue an analysis, run the command again with the same key. `JAVA_ANALYST_OFF=1 claude` switches the guards off for work outside this plugin's purpose.

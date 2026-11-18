---
description: Cheat sheet - what the java-analyst plugin does and how to use it
---

Output exactly this cheat sheet, then stop:

**What it is** - an analysis-only assistant. Ask it about a task, a requirement or the code; it reads the ticket, Confluence and the code and answers in chat. When you are done, it writes the report in the formats you pick. It **never changes code**: you implement, using the documents as a guide. Documentation (`.md`, `.txt`, ...), `CLAUDE.md` and `.claude/` files it can write, so `/init` works.

**First time:** `/java-analyst:setup` (shows which project settings are missing and adds them after you confirm), then `/java-analyst:onboarding` (3-minute tour).

**Talk first.** Just ask: "where is ABC-123 handled in the code?", "what breaks if we change X?". Answers come in chat, no documents, so a quick question costs little. What is settled is kept in a few lines in `.claude/analysis/<task>/notes.md`, so the next session goes on from there.

**Report when you are done.** Pick the formats in the `formats` row above the prompt (violet = on; a click switches), then press the yellow **▶ REPORT** button, run `/java-analyst:report [task]`, or just say "make the report". Only the selected formats are written, and only they are checked. For one run, flags replace the selection: `/java-analyst:report ABC-123 --dev`. `/java-analyst:present <format> [task]` adds one more format later. `/java-analyst:analyze ABC-123` is the full run in one go: research, interview (answers with the keyboard), report.

**Formats** (switch on for good: click in the `formats` row or `/plugin configure java-analyst@team-plugins`; files land in `.claude/analysis/<task>/`, local, not committed):

| Format | Default | Flag | For whom | Result |
| --- | --- | --- | --- | --- |
| summary | on | `--summary` | everyone | `00-README.md` (recommended solution, reading order, open questions), `03-flows.md` (current and proposed flows), `04-findings.md` (risks, pitfalls, legacy, impact on other repos), `05-proposals.md` (options with trade-offs and code examples), `06-implementation-guide.md` (steps with acceptance criteria and tests) |
| dev | on | `--dev` | a developer who codes it alone and wants it explained | `07-dev-guide.md`: UML and sequence diagrams, the patterns to follow with real reference code, templates with TODOs for the new classes and tests; explains, does not write the solution |
| visual | off | `--visual` | those who read visually | interactive page: recommendation, diagrams, requirements chart, options with effort and risk, the plan; details open on hover. Published as a private Artifact on claude.ai |
| confluence | off | `--confluence` | BA, PM, QA, the whole team | `confluence-page.md`: a plain overview with the main cases, the proposed solution, decisions and open questions, ready to paste into Confluence |

Working files, never checked: `notes.md` (the conversation's record), `01-research.md` and `02-interview.md` (written by `/java-analyst:analyze`).

**Rules that will stop the agent:** no writes to source code, tests, build files (`pom.xml`, `package.json`) or application configs; writes only inside the project; only read-only shell commands (`ls`, `grep`, `sed -n`, `git log/diff/show`, `npm ls`, ...); no reading `.env`/prod configs; Jira and the DB are read-only.

**Tips:** in `/java-analyst:analyze` the interview starts by showing how the task was understood: correct it there, it is the cheapest moment; it does not ask what the ticket or Confluence already answer, so a short interview is normal; requirements get ids (`R1`, `R2`, ...) that every document refers to; documents are written in the language you use. To continue a task, mention its key: the notes are read first. `JAVA_ANALYST_OFF=1 claude` switches the guards off for work outside this plugin's purpose.

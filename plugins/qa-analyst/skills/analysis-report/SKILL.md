---
name: analysis-report
description: Write the report of a QA task in the formats asked for, and only those - summary (answer, flows, findings, ticket notes), tests, impact, decision, logs, regression, confluence, visual - from the notes, the research and the conversation. Run by /qa-analyst:report (the REPORT button), /qa-analyst:present and /qa-analyst:analyze, or when the user asks for the report in words. Not for answering questions: those are answered in chat. No code examples, never changes code.
---

# analysis-report

**No code changes.** You write documents in `.claude/qa-analysis/<task>/` and nothing else. A report is the end of a conversation: the user has settled the questions and now wants the result in the formats they picked. Write those formats and nothing more; every document costs the user time and tokens.

## Who reads this

A QA engineer, possibly not technical, who will test, file or update a ticket, and talk to developers and analysts. They need to know: what happens, whether it is a bug, why (in words), who and what is affected, what to test, and what to write. Write for them:

- Plain language, short sentences, the words of the product (screens, statuses, users, partners, fields), not of the code. Explain a necessary technical term once, in brackets.
- **No program code** in any document: no snippets, no "how to fix", no implementation options. Code is evidence you read. The Stop hook rejects code blocks in Java, JS, Python and similar languages.
- Allowed blocks: mermaid diagrams, SQL check queries (QA re-runs them; say what the result means), verbatim log lines (masked), request or response bodies, a shell or `curl` command to reproduce.
- Class, method and file names appear only in the **technical references** at the end of `04-findings.md` and in the research table of `01-research.md`, so the QA engineer can hand them to a developer.
- Separate facts (seen in logs, data, code or documents) from assumptions, and say which is which. Never present a guess as the cause.
- Mask personal and secret data everywhere.
- Write in the language the user uses. Keep each document focused; link between them instead of repeating.

## Steps

1. **Formats.** Take the list the caller gives (the flags of the command, or the formats selected now). Write it, space separated, to `.claude/qa-analysis/<task>/.formats` before anything else, for example `summary tests impact`. The Stop hook checks exactly these formats and nothing else.
2. **Sources.** Read `notes.md`, and `01-research.md` and `02-interview.md` when they exist, and use what this conversation established. Re-open the key sources you cite (log lines, query results, pages, code): do not write from memory of a summary. Research only what the formats need and the conversation did not cover; do not redo it.
3. **Requirements.** The requirements `R*` are the backbone of `tests`, `decision` and the summary's findings. If neither `notes.md` nor `01-research.md` numbers them and one of those formats is in the report, add `## Requirements` with `- **R1** ...` (each with its source) to `notes.md` first, from the ticket and the pages already read.
4. **Write the formats, in this order**, skipping those not in the list:
   1. `tests` -> the `present-tests` skill (`05-test-cases.md`);
   2. `impact`, `decision`, `logs`, `regression` -> `present-impact` (`07-impact.md`), `present-decision` (`08-decision-table.md`), `present-logs` (`09-log-stats.md`, only when the task has logs), `present-regression` (`10-regression.md`);
   3. `summary` -> the four documents below, `00-README.md` last;
   4. `confluence` -> `present-confluence` (`confluence-page.md`);
   5. `visual` -> `present-visual` (`visual.json`, `visual.html`, published as a private Artifact).

## The summary format

1. **`03-flows.md`** (`templates/analysis/03-flows.md`): mermaid diagrams in business terms (steps the user and the systems go through, decisions, statuses), never class names. At least: how it works now (from the real path in the code and the logs) and how it should work according to the requirements, with the point where they differ marked. For an investigation, add the timeline of the case. Add a status diagram when statuses matter. Each diagram is followed by a short walk-through in plain words. Keep diagrams small (under about 15 nodes); split if larger.
2. **`04-findings.md`** (`templates/analysis/04-findings.md`): the verdict for each question of the task (bug / works as designed / requirement gap or contradiction / data or configuration problem / environment or integration problem / cannot tell yet), each with evidence and a plain explanation of the cause; who and what is affected and how often; related areas to retest; the requirements coverage table (every `R*`: how the system behaves today, matches / does not match / unclear); assumptions and how to confirm them; and at the end the technical references for developers (`repo/path/File.java`, method, log source, tables) without code.
3. **`06-ticket-notes.md`** (`templates/analysis/06-ticket-notes.md`): texts the QA engineer can paste as they are: a bug report when the verdict is a bug (title, environment, preconditions, steps, expected, actual, evidence, severity and priority suggestion with the reason), or a ticket comment with the conclusion when it is not; and the questions for the developer, analyst or product owner that remain open. Keep them short and factual; the technical references may be quoted for the developer.
4. **`00-README.md`** (`templates/analysis/00-README.md`), last: the task in one sentence, the **Answer** (verdict in one or two plain sentences, with confidence and what it rests on), what QA should do next, the reading order with one line per document in the folder, the open questions, and the status.

## Rules

- Every document is filled from its template with nothing left in `{{...}}`; delete a section that does not apply instead of leaving it empty.
- Every file, log line, query result and page you cite must exist; check with Grep/Read or the tool that produced it.
- Do not propose changes to code, configs, secrets or data. If a fix is obvious, say only what is wrong and where to look, in the technical references.
- If research shows the task is wrong, already fixed, a duplicate, or cannot be answered with the access you have, say so plainly and shorten the documents.

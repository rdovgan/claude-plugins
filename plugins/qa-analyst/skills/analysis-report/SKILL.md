---
name: analysis-report
description: Phase 3 of a QA analysis - write the plain-language answer, business flow charts, findings with evidence, test cases and ready-to-paste ticket notes, as local documents. Run by /qa-analyst:analyze after analysis-interview. No code examples, never changes code.
---

# analysis-report

Phase 3. **No code changes.** You write documents in `.claude/qa-analysis/<task>/` and nothing else.

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

Re-read `01-research.md` and `02-interview.md`, and re-open the key sources you cite (log lines, query results, pages, code): do not write from memory of the summary. The requirements `R*` are the backbone of the report: cite their ids wherever a finding or test case serves one.

1. **`03-flows.md`** (`templates/analysis/03-flows.md`): mermaid diagrams in business terms (steps the user and the systems go through, decisions, statuses), never class names. At least: how it works now (from the real path in the code and the logs) and how it should work according to the requirements, with the point where they differ marked. For an investigation, add the timeline of the case. Add a status diagram when statuses matter. Each diagram is followed by a short walk-through in plain words. Keep diagrams small (under about 15 nodes); split if larger.
2. **`04-findings.md`** (`templates/analysis/04-findings.md`): the verdict for each question of the task (bug / works as designed / requirement gap or contradiction / data or configuration problem / environment or integration problem / cannot tell yet), each with evidence and a plain explanation of the cause; who and what is affected and how often; related areas to retest; the requirements coverage table (every `R*`: how the system behaves today, matches / does not match / unclear); assumptions and how to confirm them; and at the end the technical references for developers (`repo/path/File.java`, method, log source, tables) without code.
3. **`05-test-cases.md`** (`templates/analysis/05-test-cases.md`), **always, for every type of task** (for an investigation the first case reproduces the incident; for a fix check the cases retest the fix and its neighbours). Test cases `### TC-1`, `### TC-2`, ..., each with the field table (requirements `R*`, type: positive / negative / edge / regression, priority, preconditions, test data) and the steps table `| # | Step | Expected result |` with an expected result on every step, taken from the requirements, not from the current behaviour. Steps are concrete actions on screens or API calls with real values, so anyone can run the case as written and move it into a test management tool. Add the SQL check query to find or verify the data when useful. Cover the main path, the case from the ticket, negative and edge cases, and the regression areas from the findings. The coverage table lists every `R*` with its cases, or "not testable" with the reason.
4. **`06-ticket-notes.md`** (`templates/analysis/06-ticket-notes.md`): texts the QA engineer can paste as they are: a bug report when the verdict is a bug (title, environment, preconditions, steps, expected, actual, evidence, severity and priority suggestion with the reason), or a ticket comment with the conclusion when it is not; and the questions for the developer, analyst or product owner that remain open. Keep them short and factual; the technical references may be quoted for the developer.
5. **`00-README.md`** (`templates/analysis/00-README.md`), last: the task in one sentence, the **Answer** (verdict in one or two plain sentences, with confidence and what it rests on), what QA should do next, the reading order with one line per document, the open questions, and the status.

## Rules

- Every document is filled from its template with nothing left in `{{...}}`; delete a section that does not apply instead of leaving it empty.
- Every file, log line, query result and page you cite must exist; check with Grep/Read or the tool that produced it.
- Do not propose changes to code, configs, secrets or data. If a fix is obvious, say only what is wrong and where to look, in the technical references.
- If research shows the task is wrong, already fixed, a duplicate, or cannot be answered with the access you have, say so plainly in `00-README.md` and shorten the other documents.

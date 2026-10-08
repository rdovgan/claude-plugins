---
name: analysis-report
description: Phase 3 of an analysis - write the flow charts, code findings, proposed solutions with code examples, and the implementation guide, as local documents. Run by /java-analyst:analyze after analysis-interview. Never changes code.
---

# analysis-report

Phase 3. **No code changes.** You write documents in `.claude/analysis/<task>/` and nothing else. Code in the documents is illustration inside markdown code blocks; it is never applied.

The reader is a developer who will implement this alone, who may not know the legacy code. Explain the why, name the exact files, and prefer a concrete example over an abstract rule. Write in the language the developer uses. Keep each document focused; link between them instead of repeating.

## Steps

Re-read `01-research.md` and `02-interview.md`, and re-open the key source files you cite: do not write from memory of the summary.

1. **`03-flows.md`** (`templates/analysis/03-flows.md`): mermaid diagrams. At least: the current flow of the area (flowchart or sequence, from the real call path) and the proposed flow. Add a data/state diagram or a repository interaction diagram when it helps. Each diagram is followed by a short walk-through naming the classes. Keep diagrams small (under about 15 nodes); split if larger.
2. **`04-findings.md`** (`templates/analysis/04-findings.md`): conclusions about the code, each with evidence (`repo/path/File.java`, method, what it does) and a "so what" for this task: how it works now, constraints, legacy and style to follow, impact on other repositories, risks, and non-obvious traps. Separate facts (seen in code) from assumptions.
3. **`05-proposals.md`** (`templates/analysis/05-proposals.md`): two or three realistic options (one may be "minimal"). For each: idea, what changes where, code example (a sketch against the real classes, marked "illustration, not applied", with the target file), pros, cons, risks, effort (S/M/L). Then a comparison table, a recommendation and why, and what would change the recommendation. Honour the interview decisions.
4. **`06-implementation-guide.md`** (`templates/analysis/06-implementation-guide.md`) for the recommended option: prerequisites (branch name `<fix|feature|epic>/<TICKET>/<Short-description>`, base branch, Java version if several are maintained, a DB change that must deploy first, merge order across repositories); ordered steps, each with the files to change, what to do, acceptance criteria as `- [ ]`, and the tests to write or run; where to start reading; common mistakes; a final self-check list. The developer ticks the boxes themselves.
5. **`00-README.md`** (`templates/analysis/00-README.md`), last: the task in one sentence, a TL;DR with the recommended solution, the reading order with one line per document, the open questions, and the status.

## Rules

- Every document is filled from its template with nothing left in `{{...}}`; delete a section that does not apply instead of leaving it empty.
- Every file or class you cite must exist; check with Grep/Read.
- Do not propose changes to secrets, prod configs or credentials.
- If research shows the task is wrong, impossible or already done, say so plainly in `00-README.md` and shorten the other documents.

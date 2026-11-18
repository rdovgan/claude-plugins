---
name: present-regression
description: Output format "regression" - write 10-regression.md, what changed in the code between two releases or commits (git, read-only), which business areas it touches, a prioritised list of areas to retest and a checklist, with conclusions on the overall risk. Run by analysis-report when the regression format is in the report.
---

# present-regression

For a fix check or a release: what to retest besides the ticket itself, and in what order.

**Input:** the task folder `.claude/qa-analysis/<task>/` (`notes.md`, and `01-research.md` and `02-interview.md` when written) and what this conversation established: the code path and the technical references, the test cases if written. The range to compare: the release tags, the fix branch or the commits named in the ticket; if none is known, ask the user once with `AskUserQuestion` (offer the last tag and the default branch).

## Steps

1. Read the changes with read-only git: `git log --oneline <from>..<to>`, `git diff --stat`, `git show` for the commits that matter, in each repository involved. Group commits into changes in product words; never paste the diff.
2. For each change: the business area (screen, process, report, integration), the requirement it serves if any, the risk and why (shared code, the same table, the same partner call, no tests around it).
3. Areas to retest: also the neighbours of the change (other callers of the changed code, other screens on the same data), found with Grep in the code. Priority by risk; link the test case when one exists, otherwise "manual check".
4. Fill `${CLAUDE_PLUGIN_ROOT}/templates/analysis/10-regression.md` as `10-regression.md`, with the checklist highest priority first.
5. Conclusions: the overall risk, which areas need a full retest and which a smoke check, what can be skipped and why, what is not covered.

## Rules for every data format

- Numbers come from the sources you ran in this session (queries, log reads, `git log`), never from memory or estimates. Say where each number comes from; when something cannot be counted, write it under the limits instead of guessing.
- The **Conclusions** section is the point of the document: explain in plain text what the numbers mean for the user, the priority and the testing, and separate what they prove from what they only suggest. Write it in the language the user uses; keep the headings of the template.
- No program code. SQL check queries, masked log lines and shell commands to reproduce are allowed.
- Mask personal and secret data in every table and line.
- The summary (when it is in the report) lists this document in its reading order and uses its conclusions. If `00-README.md` exists and the summary is not part of this report, add the line `- [<file>](<file>) - <one line>` to its reading order. Change nothing else in the other documents.

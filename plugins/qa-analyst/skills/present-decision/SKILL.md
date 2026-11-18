---
name: present-decision
description: Output format "decision" - write 08-decision-table.md, the decision table of the business rule (combinations of conditions -> expected result from R*, today's result) and the status transition table, with conclusions on wrong combinations and gaps in the requirements. Run after analysis-report when the decision format is on, when the user adds --decision, or by /qa-analyst:present decision.
---

# present-decision

For logic with many conditions: roles, statuses, types, flags, partner settings. The table shows every combination, so the cases that are easy to miss become visible, and the gaps in the requirements become questions.

**Input:** a finished analysis in `.claude/qa-analysis/<task>/`: the requirements `R*` (`01-research.md`), the real conditions in the code path (`04-findings.md`, technical references), the test cases if written (`05-test-cases.md`).

## Steps

1. List the conditions that change the result (C1, C2, ...) and their values, each with where it comes from: a requirement, a screen, a field. Take them from the requirements and from the conditions the code really checks; a condition the code checks but the requirements do not mention is a finding.
2. Build the table: one row per combination that gives a different result. Merge rows with "any" where a condition does not matter; keep it under about 20 rows, split by a main condition if larger. For each row: the expected result with its `R*`, today's result from the code, logs or data (matches / differs: how / unknown), and the test case that covers it.
3. When statuses matter, add the transition table: from, event, to, allowed or not, requirement, today. Include the forbidden transitions that the system must refuse.
4. Fill `${CLAUDE_PLUGIN_ROOT}/templates/analysis/08-decision-table.md` as `08-decision-table.md`.
5. Conclusions: which combinations are wrong and what they have in common, which ones the requirements do not define (each becomes a question under "Gaps in the requirements" and in `06-ticket-notes.md` if it is not there yet), which are impossible and why, which rows matter most to test.

## Rules for every data format

- Numbers come from the sources you ran in this session (queries, log reads, `git log`), never from memory or estimates. Say where each number comes from; when something cannot be counted, write it under the limits instead of guessing.
- The **Conclusions** section is the point of the document: explain in plain text what the numbers mean for the user, the priority and the testing, and separate what they prove from what they only suggest. Write it in the language the user uses; keep the headings of the template.
- No program code. SQL check queries, masked log lines and shell commands to reproduce are allowed.
- Mask personal and secret data in every table and line.
- When the document is done, add it to the reading order of `00-README.md` (`- [<file>](<file>) - <one line>`) and, if it changes the answer or the next steps, say so there too. Change nothing else in the other documents.

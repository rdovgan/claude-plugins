---
name: present-impact
description: Output format "impact" - write 07-impact.md, how many and which records, users and partners the problem touches, counted in the database with a re-runnable SELECT behind every number, broken down by status, partner, period, with a conclusion on size, trend and priority. Run after analysis-report when the impact format is on, when the user adds --impact, or by /qa-analyst:present impact.
---

# present-impact

For the question "how big is this?": a QA engineer, a PM or a lead deciding priority, a hotfix or a data correction.

**Input:** a finished analysis in `.claude/qa-analysis/<task>/`: what the problem is and how to recognise an affected record (`04-findings.md`), the tables and fields found in research (`01-research.md`).

## Steps

1. Define in one sentence which record counts as affected, and the condition that finds it in the data. If no field or combination of fields marks the case, say so under "Limits" and count what can be counted (for example all records that went through the same path).
2. Count with the `db` MCP server, one `SELECT` per call, read-only: the affected records and their share of all, the first and last case, then breakdowns by the dimensions that matter for this task (status, partner, channel, environment, day). Two or three breakdowns are enough; choose the ones that explain the problem. Aggregate in the query (`COUNT`, `GROUP BY`), do not pull rows.
3. Fill `${CLAUDE_PLUGIN_ROOT}/templates/analysis/07-impact.md` as `07-impact.md`. Every number in the tables refers to its query (`Q1`, `Q2`) under "How to check".
4. Conclusions: size, trend (growing, stable, stopped, and since when), who suffers most and why, what it means for the severity and the fix (hotfix or not, data correction needed or not), what the numbers do not show.

If there is no database access, write only what the logs or the ticket allow and say under "Limits" that the data was not counted.

## Rules for every data format

- Numbers come from the sources you ran in this session (queries, log reads, `git log`), never from memory or estimates. Say where each number comes from; when something cannot be counted, write it under the limits instead of guessing.
- The **Conclusions** section is the point of the document: explain in plain text what the numbers mean for the user, the priority and the testing, and separate what they prove from what they only suggest. Write it in the language the user uses; keep the headings of the template.
- No program code. SQL check queries, masked log lines and shell commands to reproduce are allowed.
- Mask personal and secret data in every table and line.
- When the document is done, add it to the reading order of `00-README.md` (`- [<file>](<file>) - <one line>`) and, if it changes the answer or the next steps, say so there too. Change nothing else in the other documents.

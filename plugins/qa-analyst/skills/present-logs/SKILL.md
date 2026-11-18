---
name: present-logs
description: Output format "logs" - write 09-log-stats.md, statistics from the logs (errors by type and hour, first and last time, share of requests) correlated with deploys, commits and partner events, with conclusions on what the main error is and since when. Run by analysis-report when the logs format is in the report.
---

# present-logs

For incidents and "since when does this happen": the numbers behind the timeline of the case.

**Input:** the logs named in the task folder `.claude/qa-analysis/<task>/` (`notes.md`, and `01-research.md` and `02-interview.md` when written) and what this conversation established (files, services, period). If the task has no logs, say so in one line to the user and write nothing.

## Steps

1. Count, do not read line by line: `grep -c`, `zgrep -c` and `grep | sort | uniq -c` over the files, by message pattern (strip ids, numbers and personal data from the pattern so the same error groups together). For big or many files use the `log-reader` agent and ask it for counts by pattern and hour. Commands stay read-only.
2. Errors by type: count, first and last time, service, and the share of requests when the logs show the requests too. Keep the 5 to 10 patterns that matter; put the rest as one "other" row.
3. By hour (or by day for long periods) around the incident.
4. Correlation: line the changes up with deploys and commits (`git log --since --until` in the repositories of the services), configuration changes and partner events known from the ticket. Say "lines up with", not "caused by", unless the evidence shows the cause.
5. Fill `${CLAUDE_PLUGIN_ROOT}/templates/analysis/09-log-stats.md` as `09-log-stats.md`, with up to 5 masked key lines (file:line) and the commands that give the counts.
6. Conclusions: the main error and what it means for the user, when it started and what it lines up with, whether it is still happening, which errors are noise.

## Rules for every data format

- Numbers come from the sources you ran in this session (queries, log reads, `git log`), never from memory or estimates. Say where each number comes from; when something cannot be counted, write it under the limits instead of guessing.
- The **Conclusions** section is the point of the document: explain in plain text what the numbers mean for the user, the priority and the testing, and separate what they prove from what they only suggest. Write it in the language the user uses; keep the headings of the template.
- No program code. SQL check queries, masked log lines and shell commands to reproduce are allowed.
- Mask personal and secret data in every table and line.
- The summary (when it is in the report) lists this document in its reading order and uses its conclusions. If `00-README.md` exists and the summary is not part of this report, add the line `- [<file>](<file>) - <one line>` to its reading order. Change nothing else in the other documents.

---
description: Write one more format for a task, on top of what is there - summary (the answer, flows, findings, ticket notes), tests, impact, decision, logs, regression (data documents with conclusions), visual (interactive page published as a private Artifact) or confluence (a Confluence-style page to paste)
argument-hint: <summary | tests | impact | decision | logs | regression | visual | confluence> [task folder or Jira key]
---

Write one format for a task (the same as `/qa-analyst:report <task> --<format>`): $ARGUMENTS

1. The first word is the format: `summary`, `tests`, `impact`, `decision`, `logs`, `regression`, `visual` or `confluence`. If it is missing or something else, ask with `AskUserQuestion` (summary: the answer, flows, findings and ticket notes; tests: test cases with steps and expected results; impact: affected records in numbers; decision: decision and transition tables; logs: error statistics from the logs; regression: what changed and what to retest; visual: an interactive page with the verdict, diagrams, timeline and a checklist, published as a private Artifact; confluence: one plain page for the whole team, ready to paste into Confluence).
2. The rest names the task: a Jira key or a folder name in `.claude/qa-analysis/`. If it is empty, take the most recently changed folder there and say which one you took.
3. Run the `analysis-report` skill for that task with this one format. It works from the notes, the research and this conversation; no finished analysis is needed. Do not change the other documents, except the reading order in `00-README.md` when it exists.
4. Finish with one line: the file path, and the artifact link for `visual`.

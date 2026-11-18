---
description: Present a finished QA analysis in another format - tests, impact, decision, logs, regression (data documents with conclusions), visual (interactive page published as a private Artifact) or confluence (a Confluence-style page to paste)
argument-hint: <tests | impact | decision | logs | regression | visual | confluence> [task folder or Jira key]
---

Present an existing analysis: $ARGUMENTS

1. The first word is the format: `tests`, `impact`, `decision`, `logs`, `regression`, `visual` or `confluence`. If it is missing or something else, ask with `AskUserQuestion` (tests: test cases with steps and expected results; impact: affected records in numbers; decision: decision and transition tables; logs: error statistics from the logs; regression: what changed and what to retest; visual: an interactive page with the verdict, diagrams, timeline and a checklist, published as a private Artifact; confluence: one plain page for the whole team, ready to paste into Confluence).
2. The rest names the task: a Jira key or a folder name in `.claude/qa-analysis/`. If it is empty, take the most recently changed folder there and say which one you took.
3. The analysis must be finished (`00-README.md` with an `## Answer`). If it is not, say so and offer `/qa-analyst:analyze <task>` instead.
4. Run the skill of the format: `present-<format>`. Do not change the analysis documents, except the `- Visual:` line and the reading order and next steps in `00-README.md`.
5. Finish with one line: the file path, and the artifact link for `visual`.

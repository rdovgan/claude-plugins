---
description: Write one more format for a task, on top of what is there - summary (flows, findings, proposals, implementation guide), dev (teaching guide with UML, patterns and code templates), visual (interactive page published as a private Artifact) or confluence (a Confluence-style page to paste)
argument-hint: <summary | dev | visual | confluence> [task folder or Jira key]
---

Write one format for a task (the same as `/java-analyst:report <task> --<format>`): $ARGUMENTS

1. The first word is the format: `summary`, `dev`, `visual` or `confluence`. If it is missing or something else, ask with `AskUserQuestion` (summary: flows, findings, solution options and the implementation guide; dev: `07-dev-guide.md`, how to build it in this codebase with diagrams, reference code and templates; visual: an interactive page with the recommendation, diagrams, options and the plan, published as a private Artifact; confluence: one plain page for the whole team, ready to paste into Confluence).
2. The rest names the task: a Jira key or a folder name in `.claude/analysis/`. If it is empty, take the most recently changed folder there and say which one you took.
3. Run the `analysis-report` skill for that task with this one format. It works from the notes, the research and this conversation; no finished analysis is needed. Do not change the other documents, except the reading order and the `- Visual:` line in `00-README.md` when it exists.
4. Finish with one line: the file path, and the artifact link for `visual`.

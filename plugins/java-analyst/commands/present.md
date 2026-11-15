---
description: Present a finished analysis in another format - dev (teaching guide with UML, patterns and code templates), visual (interactive page published as a private Artifact) or confluence (a Confluence-style page to paste)
argument-hint: <dev | visual | confluence> [task folder or Jira key]
---

Present an existing analysis: $ARGUMENTS

1. The first word is the format: `dev`, `visual` or `confluence`. If it is missing or something else, ask with `AskUserQuestion` (dev: `07-dev-guide.md`, how to build it in this codebase with diagrams, reference code and templates; visual: an interactive page with the recommendation, diagrams, options and the plan, published as a private Artifact; confluence: one plain page for the whole team, ready to paste into Confluence).
2. The rest names the task: a Jira key or a folder name in `.claude/analysis/`. If it is empty, take the most recently changed folder there and say which one you took.
3. The analysis must be finished (`00-README.md` and `06-implementation-guide.md` exist). If it is not, say so and offer `/java-analyst:analyze <task>` instead.
4. Run the skill of the format: `present-dev-guide`, `present-visual` or `present-confluence`. Do not change the other analysis documents, except the reading order and the `- Visual:` line in `00-README.md`.
5. Finish with one line: the file path, and the artifact link for `visual`.

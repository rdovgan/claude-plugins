---
description: Present a finished QA analysis in another format - visual (interactive page published as a private Artifact) or confluence (a Confluence-style page to paste)
argument-hint: <visual | confluence> [task folder or Jira key]
---

Present an existing analysis: $ARGUMENTS

1. The first word is the format: `visual` or `confluence`. If it is missing or something else, ask with `AskUserQuestion` (visual: an interactive page with the verdict, diagrams, timeline and a checklist, published as a private Artifact; confluence: one plain page for the whole team, ready to paste into Confluence).
2. The rest names the task: a Jira key or a folder name in `.claude/qa-analysis/`. If it is empty, take the most recently changed folder there and say which one you took.
3. The analysis must be finished (`00-README.md` with an `## Answer`). If it is not, say so and offer `/qa-analyst:analyze <task>` instead.
4. Run the skill of the format: `present-visual` or `present-confluence`. Do not change the analysis documents, except the `- Visual:` line in `00-README.md`.
5. Finish with one line: the file path, and the artifact link for `visual`.

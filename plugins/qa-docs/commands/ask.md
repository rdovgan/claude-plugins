---
description: Answer one question about how the system behaves, from the current code (and Jira/Confluence if named), with file:line references. Quick and cheap; writes no documents. Never changes code.
argument-hint: <question, optionally with a Jira key or page>
---

Answer this question from the code: $ARGUMENTS

This is the light mode: no scope, no phases, no files written. Sources are read-only. The code is the source of truth.

1. **Existing documents first.** Check `qa-docs/domains.md` and the domain folders. If a document covers the question, answer from `domain.md`, open the cited lines that decide the answer, and say which document and commits it is based on (and whether the session context says its code changed since).
2. **Jira or Confluence**, only if the question names a ticket or page: read that one (read-only), not a search across the project.
3. **Find the code.** Pick the repositories from `qa-docs/modules.md` and the question's terms. Search with `Grep` in those repositories (`path`); to find which repository has something, search the workspace root with the default `files_with_matches` output, then search the hits. Read files in parts around the hits (`offset`/`limit`).
4. **Agents only when needed.** Narrow question: read the code yourself. A question that spans several repositories or flows: at most 2 `flow-tracer` agents in parallel, each with an entry point, a boundary and its repositories. No second round without asking the user.
5. **Answer** in the team's document language, short, in business words:
   - the answer in one or two sentences;
   - how it works: steps or conditions, each with `repo/path:line`, marked seen or inferred;
   - exact values (limits, statuses, amounts, messages) where they matter;
   - where Jira/Confluence say otherwise, if you read them;
   - what you did not check and where to look.
6. Do not write files. If the answer shows a domain that is not documented, or a document that is wrong, say so and suggest `/qa-docs:document <domain>` or `/qa-docs:refresh <slug>`.

If `$ARGUMENTS` is empty, ask what the question is.

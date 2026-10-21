---
description: Document one business domain end to end - scope, Jira/Confluence sources, deep code research, the document with flow charts, verification. Never changes code.
argument-hint: <domain | flow | Jira key | Confluence link | description>
---

Document this domain: $ARGUMENTS

Sources are read-only. Everything you write goes to `qa-docs/domains/<slug>/` and the shared maps in `qa-docs/`.

1. If a domain in `qa-docs/domains.md` or in the session context matches, continue it: read its folder and pick up from the first missing or unfinished file (`work/plan.md` shows where research stopped). Do not create a duplicate.
2. Run the phases in order, each through its skill, without asking "shall I continue" between them. The stops are the scope confirmation, the go-ahead after research, and the approval in verification. Research stays within its budget (`domain-research`); a plain question about the code does not need this command: suggest `/qa-docs:ask` instead.
   - `domain-scope` -> `00-scope.md`, `meta.json`
   - `domain-sources` -> `01-sources.md`
   - `domain-research` -> `02-code.md` (+ `work/`)
   - `domain-write` -> `domain.md`, `domains.md` row, `history.md`
   - `domain-verify` -> `03-verification.md`, status `verified`
3. Finish with one short message: the folder, what the document covers, the main differences from Jira/Confluence, open questions, and `/qa-docs:export <slug>` if it was approved. Do not paste the document.

If `$ARGUMENTS` is empty, ask with `AskUserQuestion` which domain to document, offering the "not documented" rows of `qa-docs/domains.md`.

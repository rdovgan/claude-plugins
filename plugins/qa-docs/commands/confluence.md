---
description: Build or rebuild the Confluence pages of a domain (confluence/) from its document, with a local preview; publishes nothing
argument-hint: <domain slug>
---

Run the `domain-confluence` skill for `qa-docs/domains/$ARGUMENTS/`. It needs `doc/`; a domain without it: suggest `/qa-docs:document` (or `/qa-docs:rewrite $ARGUMENTS` for the old single-file format). The pages may be built for a draft too, to see how they will look; `/qa-docs:export` still publishes only a verified document.

If `$ARGUMENTS` is empty, ask which domain with `AskUserQuestion`, offering the folders that have `doc/`.

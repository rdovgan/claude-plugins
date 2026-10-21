---
description: Publish a verified domain document to Confluence (creates or updates the qa-docs page, keeps manual edits)
argument-hint: <domain slug>
---

Run the `domain-export` skill for `qa-docs/domains/$ARGUMENTS/`. If `$ARGUMENTS` is empty, ask which domain with `AskUserQuestion`, offering the folders whose `meta.json` status is `verified` or `exported`.

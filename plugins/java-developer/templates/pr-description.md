# PR description template

Paste this into the PR description and fill each section. Delete a section only if
it does not apply.

---

## What

One or two sentences on what this PR changes.

## Why

The problem, bug, or goal. Link the Jira ticket.

Ticket: ABC-XXX

## How it was tested

- `mvn -o test` passes locally for the whole module: yes / no
- New tests added for: ...
- Obsolete tests updated or removed: ...
- Manual check in a test environment: ... (or: cannot be tested there because ...)

## Notes for reviewers

Anything non-obvious: a design trade-off, a follow-up ticket, a risky area, or
something the AI reviewer will flag that is intentional.

## Scope of change

Which repos and modules. If this is part of a multi-repo change, list the other
PRs and the required merge order.

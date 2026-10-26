---
description: Rewrite a domain documented in the old single-file format (domain.md) into the page set of doc/ with diagrams rendered to PNG, from the existing research; no new code research
argument-hint: <domain slug>
---

Rewrite the domain `$ARGUMENTS` into the current document format.

This is cheap: the facts are already in `02-code.md` and `domain.md`; nothing is traced again.

1. Read `qa-docs/domains/$ARGUMENTS/meta.json`, `domain.md`, `02-code.md` and `work/plan.md`. If `doc/` already exists and `domain.md` does not, say the domain is already in the new format and stop. If the code changed since `modules` (session context), say so: after the rewrite, `/qa-docs:refresh $ARGUMENTS` brings it up to date.
2. Run `domain-write` (layout `domain`) with `domain.md` as the main input: split it into `doc/README.md`, one page per process (the sub-flows of `work/plan.md`, or the main and alternative flows of `domain.md`), the reference pages, `differences.md` and `open-questions.md`. Keep every statement and its reference; move, do not drop. Add the diagrams the new format requires (overview, a sequence or flow diagram per process) from the facts in `02-code.md` and the existing references only; a diagram that needs facts nobody traced is listed in `open-questions.md` instead.
3. Check that nothing was lost: every business rule, step, transition, setting, integration, edge case and difference of `domain.md` is somewhere in `doc/`. List what you could not place.
4. Run `check-refs.sh` and `render-diagrams.sh` for the domain. No fact-checker: the statements were checked before. Ask the user with `AskUserQuestion` to look through `doc/README.md` and approve: "Approve" (keeps the previous status) / "Not yet". The new diagrams are new statements: name them in the question.
5. Replace the content of `domain.md` with one line: "Moved to [doc/README.md](doc/README.md) on <date>." (in the document language). Update the row in `qa-docs/domains.md`, `meta.json` (`layout` `domain`, `updatedAt`, `updatedBy`) and append to `history.md`.
6. If the domain was exported, say that `/qa-docs:export $ARGUMENTS` turns the existing Confluence page into the overview page and adds the child pages.

If `$ARGUMENTS` is empty, ask which domain with `AskUserQuestion`, offering the folders that have `domain.md` and no `doc/`.

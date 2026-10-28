---
name: domain-scope
description: Phase 1 of qa-docs - define the business domain to document (name, slug, in and out of scope, actors, entry points, repositories, starting sources) with the user, and write 00-scope.md and meta.json. Run by /qa-docs:document; use it directly when a QA wants to start documenting a domain, flow or process.
allowed-tools: AskUserQuestion, Read, Grep, Glob, Write, Edit, Bash
---

# domain-scope

Phase 1. Sources are read-only; you write only in `qa-docs/domains/<slug>/`.

A good scope makes the rest cheap: the research agents trace exactly what is in scope and nothing else. The input can be a domain name ("refunds"), a flow ("guest cancels a booking"), a Jira key or epic, a Confluence page, or a mix.

## Steps

1. Read `qa-docs/domains.md` and `qa-docs/modules.md` (paths are in the session context). If the domain or an overlapping one is already documented, say so and offer to continue or refresh it (`/qa-docs:refresh <slug>`) instead of starting a duplicate.
2. If the input has a Jira key or page, read it now (read-only) just enough to understand what the domain is; the full source collection is phase 2.
3. Find the entry points yourself before asking anything: grep for the domain's terms, endpoints, jobs, listeners, UI routes, enums and tables across the repositories named in the maps. Delegate a broad search to `flow-tracer` only if the domain is unclear; a quick look is enough here.
4. Draft the scope: what the domain is in business words, in scope, out of scope, actors and entry points with references, repositories, starting sources. Propose a slug (lowercase latin, digits, `-`: `booking-cancellation`). Keep the repositories to those the flow really passes through (seen in code, not guessed): research reads only them, and every extra one costs the user's usage limit. If the domain splits into more than `QA_DOCS_MAX_SUBFLOWS` sub-flows (default 6), say so and offer to split it into two documents or to trace in two runs.
5. **Confirm with the user** through `AskUserQuestion` (load it with `ToolSearch("select:AskUserQuestion")` if needed). Print the draft (10-15 lines) as text first, then ask: "Correct" (Recommended) / "Partly - I will correct it" / "Wrong". Add, in the same call, up to three questions about real ambiguities, for example: which sub-flows to include, which actors matter most, how deep to go into a neighbouring domain. Each question has 2-4 options, the recommended one first. Do not ask what the code or the ticket already answers.
6. Write `00-scope.md` from `${CLAUDE_PLUGIN_ROOT}/templates/domain/00-scope.md`, recording the confirmation and corrections.
7. Write `meta.json` from `${CLAUDE_PLUGIN_ROOT}/templates/domain/meta.json`: slug, title, `layout` `domain` (drop the `source` block) or `mirror` when started by `/qa-docs:update-page`, status `draft`, language, `modules` with the current commit of each repository in scope (`git -C <repo> rev-parse --short=12 HEAD`), `updatedAt`, `updatedBy` (the user from the session context).
8. Start `history.md` from its template if it does not exist (date format `YYYY-MM-DD`).

**Mirror of an old page** (`/qa-docs:update-page`): the old page in `source/original.md` defines the scope. In the draft, list its sections with what each one becomes: a sub-flow to trace, part of another sub-flow, or "not code" (contacts, manual procedures, history), which is kept as written. Name a documented domain that covers the same area: research reuses its facts.

Then continue with `domain-sources` in the same turn.

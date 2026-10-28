---
name: domain-research
description: Phase 3 of qa-docs - research of the domain in the code of the involved repositories with parallel flow-tracer agents, within a budget; records facts with file:line references, checks every Jira/Confluence claim against the code, writes 02-code.md and stops for the user's go-ahead before the document is written. Run by /qa-docs:document after domain-sources.
---

# domain-research

Phase 3, the core. Sources are read-only. You write `qa-docs/domains/<slug>/02-code.md` and working notes in `qa-docs/domains/<slug>/work/`.

The document will be the team's source of truth, so a missed branch or a wrong limit matters. But every file read costs the user's usage limit, and a workspace with dozens of repositories has no natural end. Research within the budget below; when the domain needs more, say so and let the user decide.

## Budget

- **Sub-flows: at most 6 per run** (`QA_DOCS_MAX_SUBFLOWS` in the session context overrides it). One wave of agents, no second wave without asking.
- **Repositories: only those in `00-scope.md`.** Follow a call into another repository only to name where it lands; tracing it is a new sub-flow and counts against the budget.
- When the plan needs more sub-flows than the budget, trace the most important ones (the main flow first, then what the scope marked as most important) and list the rest in `work/plan.md` as "not traced yet". A later `/qa-docs:document <slug>` continues from there.

## Plan the research

1. Re-read `00-scope.md` (entry points, repositories) and `01-sources.md` (claims `D*`).
2. Split the domain into **sub-flows** that can be traced independently: one per entry point or per stage (for example: create, modify, cancel, scheduled clean-up, partner notification). Name them as business processes: each one becomes a page of the document (`doc/flows/<flow>.md`) with its own diagram, so note the components it crosses (UI, repositories, database, queue, partner) for the sequence diagram. Each sub-flow gets: the entry point, the boundary where it stops, the repositories it crosses, and the claims `D*` that concern it. Merge small ones so the count fits the budget.
   If `00-scope.md` names a documented domain that covers part of this one (usual for `/qa-docs:update-page`), take its facts from that domain's `02-code.md` for the sub-flows it traced, check their commits against the current ones, and trace only the rest.
3. Write the plan to `work/plan.md` (sub-flows, which agent traces what, what is left for later). This also lets a later session continue.

## Trace

4. Run one `flow-tracer` agent per sub-flow, in parallel, in a single message. Give each agent: the domain in two lines, its entry point and boundary, the repositories with their folders (so it searches there, not in the whole workspace), the claims to check with their ids and verbatim text, and the instruction to return facts with `repo/path:line`.
5. Save each agent's answer as `work/trace-<sub-flow>.md` as it arrives, so nothing is lost if the session breaks.
6. **Spot-check, do not re-trace.** The agents already read the code; reading it all again doubles the cost. Open the code yourself (with `offset`/`limit` around the cited line) only where it matters most: facts marked "inferred", facts two agents describe differently, claims with the verdict "differs", and the exact values (limits, statuses, amounts, formulas). The fact-checker in phase 5 checks the rest.
7. Close the gaps that fit the budget: claims nobody checked, an open end on the main flow. Everything else goes to "Open questions" in `02-code.md`, with where to look.
8. Also check, by targeted search in the repositories in scope: enums and constants that define states and limits; config properties and feature flags that change the flow (by name only, never secret values); the tables the flow writes (and where their migrations live); scheduled jobs that touch the same data; whether the main project (`QA_DOCS_MAIN_PROJECT`, if set) takes part when the flow starts elsewhere.

## Record

9. Fill `${CLAUDE_PLUGIN_ROOT}/templates/domain/02-code.md`: entry points, facts `F1`, `F2`, ... (business wording, kind, reference, seen/inferred), and the verdict for every claim `D*`: confirmed, differs (what the code does), partly, or not found in code.
10. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-refs.sh qa-docs/domains/<slug>/02-code.md` and fix every broken reference.
11. Update `meta.json` `modules` with the commit of every repository the facts cite.

## Stop for the user

12. Print a short summary (up to 15 lines): sub-flows traced, number of facts, claims confirmed / differ / not found, the main findings, what is left untraced. Then ask with `AskUserQuestion` (load it with `ToolSearch("select:AskUserQuestion")` if needed):
    - "Write the document" (Recommended when the main flow is traced) - continue with `domain-write` and `domain-verify`;
    - "Trace the rest first" - one more wave for the untraced sub-flows from `work/plan.md`, within the same budget, then ask again;
    - "Stop here" - keep `02-code.md` and `work/`, append a `history.md` entry (what was traced, what is left); `/qa-docs:document <slug>` continues later.

   If the user started the run with "without stops" or similar, skip the question and continue with `domain-write`.

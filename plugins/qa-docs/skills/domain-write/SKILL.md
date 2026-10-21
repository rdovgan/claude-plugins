---
name: domain-write
description: Phase 4 of qa-docs - write the domain document domain.md (business flow with mermaid diagrams, rules, states, data, configuration, integrations, edge cases, notes for testing, differences from Jira/Confluence) from the research, and update the shared domain map. Run by /qa-docs:document after domain-research.
---

# domain-write

Phase 4. You write `qa-docs/domains/<slug>/domain.md`, update `qa-docs/domains.md`, and append to `history.md`.

## Who reads it

QA writing test cases, analysts checking new requirements against current behaviour, developers planning features. They need **what the system does**, in business language, with the exact values and the nuances, and a way to check every statement. They do not need class-by-class code tours.

## Steps

1. Re-read `00-scope.md`, `01-sources.md`, `02-code.md`. Write from the facts `F*`, not from memory.
2. Fill `${CLAUDE_PLUGIN_ROOT}/templates/domain/domain.md` in the document language (session context; translate the headings, but keep a heading named "Sources" or "Джерела" last). Rules:
   - Every flow step, rule, transition, setting, integration and edge case has a reference `` `repo/path/File.ext:line` ``. Classes may be named for orientation; the text explains behaviour.
   - Exact values: numbers, limits, statuses, messages, formats, time zones, rounding.
   - **Diagrams in mermaid**: the main flow (flowchart; sequenceDiagram when several systems talk), a state diagram when the domain has statuses, an extra diagram per complex alternative flow. Keep each under about 15 nodes; split larger ones. Node labels in business words; put labels with spaces or symbols in quotes. Each diagram is followed by a numbered walk-through.
   - "Differences from Jira and Confluence": every claim `D*` that differs or was not found in code. This section is one of the most valuable for QA; do not soften it.
   - "Notes for testing": the branches worth covering, test data that triggers each one, where the result is visible (screen, table, log, event, email).
   - Separate what was seen from what was inferred ("inferred from ..."). Unknowns go to "Open questions", never filled with guesses.
   - Delete a section that does not apply instead of leaving it empty. No `{{...}}` left.
3. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-refs.sh qa-docs/domains/<slug>/domain.md` and fix every broken reference.
4. Update the domain row in `qa-docs/domains.md` (create it from `${CLAUDE_PLUGIN_ROOT}/templates/domains.md` if missing): name, slug, one line, repositories, main entry points, link to the document. Correct neighbouring rows only when the research proved them wrong. If you learned something general about repositories (a connection, a role), add it to `qa-docs/modules.md` too.
5. Update `meta.json` (`updatedAt`, `updatedBy`, `modules`) and append a `history.md` entry: date `YYYY-MM-DD`, user, what was done, the commits used, what is still open.

Then continue with `domain-verify` in the same turn.

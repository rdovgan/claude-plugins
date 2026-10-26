---
name: domain-write
description: Phase 4 of qa-docs - write the domain document as a set of short pages in doc/ (an overview README with the overall diagram, one page per process with a sequence or flow diagram, reference pages for rules, states, data, configuration and integrations, differences from Jira/Confluence, open questions), render the diagrams to PNG, and update the shared domain map. For a domain started from an old Confluence page (layout mirror) it writes the updated page in the old page's structure instead. Run by /qa-docs:document, /qa-docs:update-page and /qa-docs:rewrite.
---

# domain-write

Phase 4. You write `qa-docs/domains/<slug>/doc/`, update `qa-docs/domains.md`, and append to `history.md`. The files `00`-`03`, `work/` and `history.md` are the research trail; `doc/` is what people read.

## Who reads it

QA writing test cases, analysts checking new requirements against current behaviour, developers planning features. They need **what the system does**, in business language, with the exact values and the nuances, and a way to check every statement. They do not need class-by-class code tours, and they do not read a 1000-line page: one page answers one question.

## Steps

1. Re-read `00-scope.md`, `01-sources.md`, `02-code.md`, `work/plan.md`. Write from the facts `F*`, not from memory. `meta.json` `layout` decides the shape: `domain` (default) below, `mirror` in the section "Mirror of an old page".
2. Write the pages from `${CLAUDE_PLUGIN_ROOT}/templates/domain/doc/` in the document language (session context; translate the headings and the link texts, keep the file names):
   - `doc/README.md`: the overview. Summary, the overview diagram, the list of processes with links, links to the reference pages, the glossary, the 5 most important differences, and a section named "Sources" or "Джерела" last. It must fit on about two screens.
   - `doc/flows/<flow>.md`: **one page per process**, usually one per sub-flow of `work/plan.md` (create, modify, cancel, scheduled clean-up, partner notification, ...). File names in lowercase latin with `-`. Summary, diagram, steps, the rules it applies (links to `rules.md`, not copies), alternative and error paths, edge cases, what to test.
   - `doc/reference/`: `rules.md` (every rule `BR*` once, grouped, with an anchor `<a id="brN"></a>`), `states.md`, `data.md`, `config.md`, `integrations.md`.
   - `doc/differences.md`: every claim `D*` that differs or was not found in code. One of the most valuable pages for QA; do not soften it.
   - `doc/open-questions.md`: everything not answered, including sub-flows "not traced yet".
   - Leave out a reference page that has nothing in it, and remove its link from the README.
3. Rules for every page:
   - It starts with the line "Part of ..." linking the README, and a short summary. Aim for under about 200 lines; split a process page that grows past that into two processes.
   - Every flow step, rule, transition, setting, integration and edge case has a reference `` `repo/path/File.ext:line` ``. Classes may be named for orientation; the text explains behaviour.
   - Exact values: numbers, limits, statuses, messages, formats, time zones, rounding.
   - Links between pages are relative markdown links (`../reference/rules.md#br3`); the export turns them into Confluence links.
   - Separate what was seen from what was inferred ("inferred from ..."). Unknowns go to `open-questions.md`, never filled with guesses.
   - No `{{...}}` left.
4. **Diagrams.** Required:
   - README: an overview `flowchart LR` of actors, entry points, systems (repositories, services, partners) and data stores, named `overview`.
   - each process page: a `sequenceDiagram` when the process crosses more than one component (UI, repositories, services, database, queue, partner); a `flowchart TD` when it runs inside one component. Add a second `flowchart` for decision-heavy logic (validations, price calculation, eligibility).
   - `states.md`: a `stateDiagram-v2` per entity with statuses.

   Each diagram: under about 15 nodes or 8 participants (split larger ones); labels in business words, with quotes around labels that have spaces or symbols; real steps only, matching the walk-through below it. The line right before each ```` ```mermaid ```` block is its picture: `![Title](../diagrams/<name>.png)` (`diagrams/<name>.png` from the README); names are lowercase latin with `-` and unique within the domain (`overview`, `create-booking`, `create-booking-validation`, `states-booking`).
5. Run `${CLAUDE_PLUGIN_ROOT}/scripts/render-diagrams.sh qa-docs/domains/<slug>`. It saves each block as `doc/diagrams/<name>.mmd` and renders `<name>.png` next to it. Fix every diagram it reports as broken and run it again. If mermaid-cli is not installed it says so: keep going (the mermaid code stays in the pages) and tell the user at the end that the admin needs to install it.
6. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-refs.sh qa-docs/domains/<slug>` and fix every broken reference.
7. Update the domain row in `qa-docs/domains.md` (create it from `${CLAUDE_PLUGIN_ROOT}/templates/domains.md` if missing): name, slug, one line, repositories, main entry points, link to `domains/<slug>/doc/README.md`. Correct neighbouring rows only when the research proved them wrong. If you learned something general about repositories (a connection, a role), add it to `qa-docs/modules.md` too.
8. Update `meta.json` (`updatedAt`, `updatedBy`, `modules`) and append a `history.md` entry: date `YYYY-MM-DD`, user, what was done, the commits used, what is still open.

Then continue with `domain-verify` in the same turn.

## Mirror of an old page (layout `mirror`)

The user gave an old Confluence page and wants a current version of it **in the same structure**; the old page stays as it is. `source/original.md` holds the old page as it was read, `00-scope.md` maps its sections to sub-flows, `01-sources.md` holds its statements as claims with the section each one came from.

1. Write `doc/page.md` with the old page's skeleton: the same headings in the same order and at the same levels, the same tables with the same columns, the same lists, the same terms. Change only the content:
   - a statement the code confirms stays as it was written;
   - a statement the code contradicts is rewritten to what the code does;
   - a statement with no trace in the code is removed from its place and listed in `changes.md` as "no longer in code";
   - new behaviour the old page did not mention goes into the section where it belongs, as text in the same style, not as a new section.
   - Where the old page had a picture or a draw.io diagram of a process, put a mermaid diagram of the current process in the same place (picture line plus block, as in step 4). Add no diagrams elsewhere: the structure stays the same.
2. Two additions only: a first line under the title, "Updated version of [<old title>](<url>) (version N) from the code at <repo@commit, ...>, <date>. What changed: [What changed](changes.md)." (in the document language), and a last section "Code references" / "Посилання на код": a table `section | statement | reference` with a reference for every statement that has one. The body keeps the old page's style, so references go there and not into the text.
3. Write `doc/changes.md` from `${CLAUDE_PLUGIN_ROOT}/templates/domain/mirror/changes.md`: every changed, new and removed statement, with the old wording, the current behaviour and the reference; what was confirmed; what could not be checked (pictures, external systems, manual procedures).
4. Then steps 5, 6 and 8 above. In `qa-docs/domains.md` the row links `domains/<slug>/doc/page.md` and names the old page.

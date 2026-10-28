---
name: domain-verify
description: Phase 5 of qa-docs - verify a domain document in three layers (automatic checks of references, pages and diagrams, a skeptical fact-checker agent against the code, review and approval by a person) and write 03-verification.md. Run by /qa-docs:document, /qa-docs:update-page and /qa-docs:verify.
allowed-tools: AskUserQuestion, Read, Grep, Glob, Write, Edit, Bash, Agent
---

# domain-verify

Phase 5. A document becomes the source of truth only after this phase. You write `03-verification.md` and correct the pages in `doc/`.

## Steps

1. **Automatic.**
   - `${CLAUDE_PLUGIN_ROOT}/scripts/check-refs.sh qa-docs/domains/<slug>`: fix broken references.
   - `${CLAUDE_PLUGIN_ROOT}/scripts/render-diagrams.sh qa-docs/domains/<slug> --check`: every diagram has its picture line and a current PNG; render again if not.
   - Required pages: layout `domain`: `doc/README.md` with the overview diagram and a "Sources" section, at least one page in `doc/flows/`, each with a diagram, `doc/reference/rules.md`, `doc/differences.md` when any claim differs; every relative link between pages points to an existing file. Layout `mirror`: `doc/page.md` has the same headings in the same order as `source/original.md` (compare the `#` lines), plus the two allowed additions; `doc/changes.md` exists.
   - The commits in `meta.json` match the current ones (session context); if the code moved, re-check the facts in the changed repositories first (`git -C <repo> diff <old>..<new> --stat`).
2. **Fact check.** Run `fact-checker` agents, **at most 3**, in parallel, each on a group of pages: layout `domain`: (a) `flows/*.md` with their diagrams, (b) `reference/rules.md` and `reference/states.md`, (c) `reference/config.md`, `reference/integrations.md`, `reference/data.md` and the edge cases of the process pages; layout `mirror`: split `page.md` by sections into up to 3 groups, and include `changes.md`. Merge groups for a small document. Tell each agent what to check: every business rule, exact value (limits, amounts, statuses, formulas, messages), state transition and flow step; not the glossary, the actors or the prose around them; skip statements you already checked against the code in phase 3 (list their ids). Give each agent the repositories its pages cite, so it searches there. Then for every verdict other than "confirmed", open the code yourself and decide: correct the statement, remove it, or move it to the open questions. The agent can be wrong too. After corrections to a diagram, run `render-diagrams.sh` again.
3. Re-run `check-refs.sh` after the corrections.
4. **Review by a person.** Print a short summary: the pages and what they cover, how many statements were checked and corrected, the main differences from Jira/Confluence (for `mirror`: the main changes against the old page), the open questions, where the PNGs are (`qa-docs/domains/<slug>/doc/diagrams/`). Then ask with `AskUserQuestion` (load it with `ToolSearch("select:AskUserQuestion")` if needed): "Approve" (Recommended only if nothing important is open) / "Approve with corrections - I will list them" / "Not yet - needs more work". Corrections are applied, re-checked against the code, and recorded. The user is responsible for the approval; tell them that a developer of the domain is the best second reviewer.
5. Fill `${CLAUDE_PLUGIN_ROOT}/templates/domain/03-verification.md` with the results of all three layers.
6. On approval: `meta.json` `status` = `verified`, `verifiedBy`, `verifiedAt`; update the status line at the top of `doc/README.md` (for `mirror`, the first line of `doc/page.md`). Append a `history.md` entry.

Then, if export is configured and the user approved, offer `/qa-docs:export <slug>`. Do not export without that.

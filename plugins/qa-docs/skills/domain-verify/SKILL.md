---
name: domain-verify
description: Phase 5 of qa-docs - verify a domain document in three layers (automatic reference check, a skeptical fact-checker agent against the code, review and approval by a person) and write 03-verification.md. Run by /qa-docs:document after domain-write and by /qa-docs:verify.
allowed-tools: AskUserQuestion, Read, Grep, Glob, Write, Edit, Bash, Agent
---

# domain-verify

Phase 5. A document becomes the source of truth only after this phase. You write `03-verification.md` and correct `domain.md`.

## Steps

1. **Automatic.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-refs.sh qa-docs/domains/<slug>` and fix broken references. Check that the required sections exist and that the commits in `meta.json` match the current ones (session context); if the code moved, re-check the facts in the changed repositories first (`git -C <repo> diff <old>..<new> --stat`).
2. **Fact check.** Run `fact-checker` agents on `domain.md`, **at most 3**, in parallel: (a) main and alternative flows with the diagrams, (b) business rules and states, (c) integrations, configuration and edge cases. Merge the groups for a short document. Tell each agent what to check: every business rule, exact value (limits, amounts, statuses, formulas, messages), state transition and flow step; not the glossary, the actors or the prose around them; skip statements you already checked against the code in phase 3 (list their ids). Give each agent the repositories the section cites, so it searches there. Then for every verdict other than "confirmed", open the code yourself and decide: correct the statement, remove it, or move it to "Open questions". The agent can be wrong too.
3. Re-run `check-refs.sh` after the corrections.
4. **Review by a person.** Print a short summary: what the document covers, how many statements were checked and corrected, the main differences from Jira/Confluence, the open questions. Then ask with `AskUserQuestion` (load it with `ToolSearch("select:AskUserQuestion")` if needed): "Approve" (Recommended only if nothing important is open) / "Approve with corrections - I will list them" / "Not yet - needs more work". Corrections are applied, re-checked against the code, and recorded. The user is responsible for the approval; tell them that a developer of the domain is the best second reviewer.
5. Fill `${CLAUDE_PLUGIN_ROOT}/templates/domain/03-verification.md` with the results of all three layers.
6. On approval: `meta.json` `status` = `verified`, `verifiedBy`, `verifiedAt`; update the status line at the top of `domain.md`. Append a `history.md` entry.

Then, if export is configured and the user approved, offer `/qa-docs:export <slug>`. Do not export without that.

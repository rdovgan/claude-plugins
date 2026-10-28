---
name: task-triage
description: Size a new task as trivial, standard or complex and pick how much of the workflow it gets, so a one-line fix does not run the full research-interview-spec-review cycle. Use inside task-research right after the ticket is read, or when the user says "quick" or "full" about a task. Do not use for questions about code with no intent to change it.
---

# task-triage

Decides how much process a task needs. The full cycle (Confluence sweep, `code-explorer`, interview, spec, `java-reviewer`) is right for features and risky changes and wasteful for a typo or a one-line fix. Triage takes one quick look, not a research phase: the ticket text plus at most a few `Grep`/`Read` calls to locate the code. No subagents here.

## Levels

Pick the **lowest** level whose conditions all hold.

**trivial** - all of:
- one repository, one module, about 1-2 files and a small diff (a condition, a constant, a message, a mapping, a null check, a log line, a config value);
- the expected behavior is fully stated by the ticket or the user, and you found the exact place in the code;
- no change to a public API (REST contract, event, public method used by other repositories), no DB schema or migration change, no new dependency, no security, payment or PII logic;
- no open questions and no linked Confluence requirements to reconcile.

**standard** - a change inside one repository that touches several classes, or has 1-2 open questions, or needs a new test class; no cross-repository contract changes.

**complex** - anything else: an epic or a ticket with children, several repositories, a public API, event or schema change, conflicting or missing requirements, Confluence pages that hold the requirements, payment/security logic.

When unsure between two levels, take the higher one.

## Output

Say the level in one line with the reason, and how to override:

> Triage: **trivial** - one null check in `RateService.applyDiscount`, behavior stated in the ticket. Say "full" for the full workflow.

The user's word wins: "quick" forces trivial (unless the change touches a schema or a public API; then say why it cannot be quick), "full" forces complex. Do not ask for confirmation otherwise; continue in the same turn.

## What each level runs

| Phase | trivial | standard | complex |
| --- | --- | --- | --- |
| Confluence | only pages linked from the ticket | linked pages + CQL search by key | full sweep (`task-research` step 2) |
| `code-explorer` | no; `Grep`/`Read` directly | one call | as needed, several repositories |
| `task-interview` | no (ask one plain question only if blocked) | only the open questions | full checklist |
| `task-spec` | no file; a plan of up to 3 lines in chat | short spec: 1-3 steps | full spec |
| `spec-reviewer` | no | only if the spec changes a public contract, a DB table or more than one repository | yes |
| Implementation | directly, no plan mode | step by step | step by step in plan mode |
| Tests | run the module's existing tests; add or update a test when the change is in logic covered by a test class | per step | per step |
| Self-check | 3 lines: what changed, which tests ran, the result | against the spec | against the spec |
| `java-reviewer` | no; mention `/java-developer:review` is available | yes | yes |

Branch naming, commit format, protected branches and the Definition of done tests (`mvn -o test` for the module passes) apply at every level.

## Escalation

If the trivial or standard path turns out bigger than triaged (a second repository, a contract change, an unclear rule, more than a few files), stop, say in one line what was found and the new level, and continue with the matching phases. Never downgrade silently.

---
name: task-report
description: Write the report of a finished (or paused) task in the formats asked for, and only those - pr (PR description), qa (QA handoff with checks and a Jira comment), review (self-review by java-reviewer), summary (session note in Obsidian) - into .claude/reports/<KEY>/. Run by /java-developer:report (the REPORT button) or when the developer asks for the PR description, the QA handoff or the report in words. Never unasked.
---

# task-report

The developer has done the work and wants the texts around it. Write the formats asked for and nothing more. Do not change code here; if the report shows a gap (failing tests, an open criterion), say so instead of fixing it silently.

## Steps

1. **Formats.** Take the list the caller gives. Write it, space separated, to `.claude/reports/<KEY>/.formats` before anything else (for example `pr qa`). The Stop hook checks exactly these formats.
2. **Sources.** The spec `.claude/specs/<KEY>.md` (steps, acceptance criteria and which are ticked), the diff of the branch against its base (`git diff <base>...HEAD --stat`, then the files that matter), `git log <base>..HEAD`, the result of the last test run in this session, the ticket, and this conversation. Every statement must come from them.
3. **Write the formats, in this order**, skipping those not in the list:
   1. `review` -> run the `java-reviewer` subagent on the branch against the base branch, and save its report as `review.md` with a `## Verdict` section on top (ready for a PR / needs changes, and the blocking findings). Its findings feed the PR notes.
   2. `pr` -> `pr.md` from `${CLAUDE_PLUGIN_ROOT}/templates/pr-description.md` (without the instructions above the `---`): first line the PR title `<TICKET> <summary>`; What, Why with the ticket, How it was tested with the real test result (say plainly if `mvn -o test` was not run or failed), Notes for reviewers (trade-offs, intentional review findings), Scope of change with the other repositories and the merge order. No AI attribution.
   3. `qa` -> `qa-handoff.md` from `${CLAUDE_PLUGIN_ROOT}/templates/qa-handoff.md`: what changed in product words; the checks, one row per acceptance criterion of the spec (and the bug's reproduction for a fix), with concrete masked test data; the areas to retest that share the changed code or data; what was not done; a Jira comment ready to paste. Write it for a QA engineer who does not read code.
   4. `summary` -> run the `session-summary` skill (the note goes to the Obsidian vault, not to this folder).
4. Delete template sections that do not apply instead of leaving `{{...}}`. Write in the language the developer uses; PR title and branch names follow the team naming.

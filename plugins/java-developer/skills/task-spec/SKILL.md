---
name: task-spec
description: Record agreements as a task specification with steps and acceptance criteria, saved under .claude/specs/. Use after task-interview finishes, before implementation. Do not use for questions or for tasks the user asked to do without a spec.
---

# task-spec

Records the agreements as a specification.

## Steps

1. Fill in the template `${CLAUDE_PLUGIN_ROOT}/templates/spec.md`.
2. Save to `.claude/specs/<task-key>.md` or `.claude/specs/<YYYY-MM-DD>-<short-name>.md`. Make sure `.claude/specs/` is in the project's `.gitignore`; add it if not.
3. Show the specification to the user and wait for confirmation.
4. After confirmation, suggest switching to plan mode to implement the first step.

Also record in the spec: the target Java version if several are maintained, the branch name `<fix|feature|epic>/<TICKET>/<Short-description>`, any DB change (it must deploy before the dependent code) and the merge order for multi-repo changes (low-level repos first, see the module map and `${CLAUDE_PLUGIN_ROOT}/reference/team-workflow.md`).

Every step must have verifiable acceptance criteria and a list of tests, and `- Result: pending`.

## Execution: the spec is the checklist

The spec is the working checklist; keep it current while implementing:

1. Work one step at a time, in order. Before starting a step, re-read it.
2. When the step is implemented, run its tests. Only then tick (`- [x]`) the criteria that are verified; leave a criterion open if it is not (do not tick on belief).
3. Replace `Result: pending` with one line: which tests ran and the outcome, plus any deviation from the step.
4. Do not start the next step while the current one has open criteria, unless the user agrees; say what is left open.
5. If the work changes scope (a new step, a dropped criterion, a new risk), edit the spec and tell the user in one line; do not let the code and the spec drift apart.

The `session-start` hook prints the progress (`N of M steps done`, next step) when a session starts or resumes; the `Stop` hook reminds you once if code changed and nothing was ticked.

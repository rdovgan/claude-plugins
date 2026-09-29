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

Every step must have verifiable acceptance criteria and a list of tests.

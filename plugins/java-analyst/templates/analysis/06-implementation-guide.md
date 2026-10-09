# Implementation guide: {{KEY or name}}

For the recommended option: {{name}}. You implement this yourself; tick the boxes as you verify each one.

## Before you start

- Java line and base branch: {{base branch; Java version if several are maintained}}
- Branch: {{type/TICKET/Short-description}}
- Database changes: {{migration file, deployed first, or none}}
- Merge order across repositories: {{order or n/a}}
- Read first, in this order: {{path/File.java or Confluence page - why}}

## Steps

### Step 1. {{name}}

- Implements: {{R-ids}}
- Files: {{repo/path/File.java}}
- What to do: {{description}}
- Acceptance criteria:
  - [ ] {{verifiable criterion}}
- Tests: {{test class/method: what it verifies; command to run}}

## Common mistakes

- {{mistake and how to avoid it}}

## Final self-check

- [ ] The tests of every touched module pass
- [ ] Behavior used by other repositories is unchanged, or they are updated in the agreed order
- [ ] Every requirement `R*` from 01-research.md is implemented or agreed out of scope
- [ ] No secrets, prod configs or debug output are committed
- [ ] {{task-specific check}}

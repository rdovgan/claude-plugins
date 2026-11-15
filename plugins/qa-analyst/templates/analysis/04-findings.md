# Findings: {{KEY or name}}

## Verdict

| Question | Verdict | Evidence |
| --- | --- | --- |
| {{question from the task}} | {{bug / works as designed / requirement gap / data or configuration / environment or integration / cannot tell yet}} | {{log line, data, R-id}} |

## Why it happens

{{the cause in plain words: which condition, which data, which step. Facts first, then assumptions, each marked}}

- Fact: {{statement}} - evidence: {{log line `file:line` / query result / R-id / page}}
- Assumption: {{statement}} - how to confirm: {{check}}

## Who and what is affected

- {{users, partners, channels, how often, since when}}

## Related areas to retest

- {{area or feature that shares the same rule or data, and why}}

## Requirements coverage

| Requirement | How the system behaves today | Status |
| --- | --- | --- |
| {{R1}} | {{plain words}} | {{matches / does not match / unclear}} |

## Risks and traps for testing

- {{non-obvious thing: caching, delays, time zones, feature flags, test data that hides the bug, ...}}

## Technical references (for developers)

No code here: the places a developer should look at.

- `{{repo/path/File.java}}` `{{method}}` - {{what it decides}}
- Log source: {{message text}} - `{{repo/path/File.java}}`
- Tables: {{names}}

# Findings: {{KEY or name}}

## How it works now

- {{statement}} - evidence: `{{repo/path/File.java}}` `{{method}}`; so what: {{consequence for the task}}

## Constraints and conventions to follow

- {{legacy style, Java line, naming, transaction boundaries, Confluence requirements, ...}} - evidence: `{{path}}` or page `{{title}}`

## Impact on other repositories

| Repository | What uses the touched code | Impact |
| --- | --- | --- |
| {{repo}} | {{class.method}} | {{none / must change / must be re-tested}} |

## Risks

| Risk | Likelihood | Effect | Mitigation |
| --- | --- | --- | --- |
| {{risk}} | {{low/med/high}} | {{effect}} | {{how}} |

## Non-obvious traps

- {{non-obvious thing that goes wrong, and where}}

## Requirements coverage

| Requirement | Handled in code today | So what for the task |
| --- | --- | --- |
| {{R1}} | {{repo/path/File.java: method, or "not handled"}} | {{what must change, or nothing}} |

## Assumptions (not verified in code)

- {{assumption and how to verify it}}

## Existing technical debt worth knowing (do not fix as a side effect)

- {{item or "none"}}

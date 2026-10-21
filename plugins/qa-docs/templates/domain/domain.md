# {{title}}

> Source of truth for this business area, built from the code. Code version: {{repo@commit, ...}} ({{YYYY-MM-DD}}). Status: {{draft / verified by NAME on DATE}}.

## Summary

{{what the domain does, for whom, the main outcome; 5-8 lines a new QA can read in a minute}}

## Glossary

| Term | Meaning | In code |
| --- | --- | --- |
| {{business term}} | {{meaning}} | `{{ClassOrEnum}}` |

## Actors and entry points

| Actor / trigger | How it starts | Reference |
| --- | --- | --- |
| {{actor}} | {{UI action, API call, schedule, event}} | `{{repo/path/File.java:120}}` |

## Main flow

```mermaid
flowchart TD
  A[{{start}}] --> B{"{{decision}}"}
```

{{numbered walk-through of the flow in business language; each step names the rule it applies and its reference}}

## Alternative and error flows

### {{name of the alternative flow}}

{{when it happens, what the user sees, what the system stores; reference}}

## Business rules

| Id | Rule | Where | Reference |
| --- | --- | --- | --- |
| BR1 | {{rule as a tester would check it, with exact values and limits}} | {{step of the flow}} | `{{repo/path/File.java:120}}` |

## States and transitions

```mermaid
stateDiagram-v2
  [*] --> {{State}}
```

| From | To | Trigger | Reference |
| --- | --- | --- | --- |
| {{state}} | {{state}} | {{event or action}} | `{{repo/path/File.java:120}}` |

## Data

{{the entities that matter, the fields that drive behaviour, their allowed values; tables and enums with references}}

## Configuration and flags

| Setting | Effect | Reference |
| --- | --- | --- |
| {{property / DB setting / feature flag}} | {{what changes when it is on/off}} | `{{repo/path:line}}` |

## Integrations

| System | Direction | When | What is sent / received | Reference |
| --- | --- | --- | --- | --- |
| {{partner, channel, payment provider, internal service}} | {{in / out}} | {{step}} | {{payload, essentials}} | `{{repo/path:line}}` |

## Edge cases and nuances

- {{non-obvious behaviour a tester must know: rounding, time zones, retries, partial failures, legacy branches}} (`{{ref}}`)

## Notes for testing

- {{what to cover, test data that triggers each branch, where results are visible (UI, DB table, log, event)}}

## Differences from Jira and Confluence

| Documented as | The code does | Source | Reference |
| --- | --- | --- | --- |
| {{claim D*}} | {{actual behaviour}} | {{page / ticket}} | `{{repo/path:line}}` |

## Open questions

- {{what neither the code nor the sources answer; who could}}

## Sources

- Code: {{repo@commit for every repository used}}
- Jira: {{keys}}
- Confluence: {{page titles with links}}

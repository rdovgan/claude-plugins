# Research: {{KEY or name}}

## Task

- Source: {{Jira key / link / description / log file}}
- Type: {{investigation / expected or bug / test design / fix check}}
- Essence: {{what must be found out and why}}
- Acceptance criteria from the ticket: {{list or "none given"}}
- Comments and linked tickets that matter: {{list or "none"}}

## Understanding

{{the question in plain words: what happened or must happen, for whom, what the result must be}}

## Requirements and expected behaviour

<!-- Every requirement, rule, limit, example and decision from the ticket and the Confluence pages, verbatim or nearly so. Later documents refer to these ids. Behaviour taken only from the code is marked "from code, not confirmed". -->

- **R1** {{requirement, quoted or nearly verbatim}} - source: {{page title + link, or ticket}}

### Conflicts between sources

- {{R-id: what the ticket says vs what the page says, which one is more recent; or "none"}}

## Sources

- Jira tickets read: {{N tickets: epic, children, linked, earlier similar; or the key list}}
- Confluence pages read in full: {{N: titles}}; with comments: {{yes/no per page}}
- Logs: {{files, time range covered; or "none given"}}
- Database: {{checked / not available and why}}
- Not read and why: {{page - no access / not found / out of scope, or "none"}}

## Evidence

### Logs (timeline)

| Time | What happened | Key line (masked) | Where |
| --- | --- | --- | --- |
| {{hh:mm:ss}} | {{plain words}} | `{{verbatim line}}` | {{file:line}} |

### Data

- {{what was checked}}: {{result in plain words}}

```sql
{{query that proved it}}
```

## Where it lives

| Step of the flow | Repository | Class.method | What it decides |
| --- | --- | --- | --- |
| {{screen / API call / job / message}} | {{repo}} | {{path/File.java: method}} | {{rule, status, message, in plain words}} |

## Other repositories and systems involved

- {{repo or external system - its part in the flow, or "none"}}

## Risks seen so far

- {{risk}}

## Open questions (for the interview)

Only what the code, the DB, the logs, Jira and Confluence do not answer.

- {{question}} - looked in: {{pages, tickets, logs, files checked}}

# Research: {{KEY or name}}

## Task

- Source: {{Jira key / link / description}}
- Essence: {{what must be achieved and why}}
- Acceptance criteria from the ticket: {{list or "none given"}}
- Comments and linked tickets that matter: {{list or "none"}}

## Understanding

{{the problem in your own words: what is wrong or missing today, for whom, what the result must be}}

## Requirements

<!-- Every requirement, rule, limit, example and decision from the ticket and the Confluence pages, verbatim or nearly so. Later documents refer to these ids. -->

- **R1** {{requirement, quoted or nearly verbatim}} - source: {{page title + link, or ticket key}}; in code: {{repo/path/File.java: method, or "new"}}

### Conflicts between sources

- {{R-id: what the ticket says vs what the page says, which one is more recent; or "none"}}

## Sources

- Jira tickets read: {{N tickets: epic, children, linked; or the key list}}
- Confluence pages read in full: {{N: titles}}; with comments: {{yes/no per page}}
- Not read and why: {{page - no access / not found / out of scope, or "none"}}

## Where it lives

Entry points and call path, top to bottom:

| Layer | Repository | Class.method | Role |
| --- | --- | --- | --- |
| {{controller / listener / job}} | {{repo}} | {{path/File.java: method}} | {{what it does}} |

## Related code

- Similar existing implementations: {{path/File.java - how it resembles the task}}
- Tests that cover the area: {{path/FileTest.java - what they cover, or "none"}}
- Configuration and constants: {{where}}
- Database tables and migration files: {{names or "none"}}

## Other repositories

- {{repo - how it uses the touched code, or "no usages found"}}

## Risks seen so far

- {{risk}}

## Open questions (for the interview)

Only what the code, the DB, Jira and Confluence do not answer.

- {{question}} - looked in: {{pages, tickets, files checked}}

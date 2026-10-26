# {{title}}

> Status: {{draft / verified by NAME on DATE}}. Code: {{repo@commit, ...}} ({{YYYY-MM-DD}}). Built by qa-docs from the code: every statement links to the line that does it.

## Summary

{{what the domain does, for whom, the main outcome; 5-8 lines a new QA can read in a minute}}

## Overview

![{{title}}: overview](diagrams/overview.png)

```mermaid
flowchart LR
  {{actor}} --> {{entry point}} --> {{system / repository}} --> {{storage or partner}}
```

{{numbered walk-through: who starts which process, which systems and data stores take part}}

## Processes

| Process | When it happens | Page |
| --- | --- | --- |
| {{name}} | {{trigger and actor, one line}} | [{{name}}](flows/{{flow}}.md) |

## Reference

- [Business rules](reference/rules.md): {{N}} rules
- [States](reference/states.md): {{entities with statuses}}
- [Data](reference/data.md): {{main entities and tables}}
- [Configuration](reference/config.md): {{N}} settings and flags
- [Integrations](reference/integrations.md): {{systems}}
- [Differences from Jira and Confluence](differences.md): {{N}}
- [Open questions](open-questions.md): {{N}}

## Glossary

| Term | Meaning | In code |
| --- | --- | --- |
| {{business term}} | {{meaning}} | `{{ClassOrEnum}}` |

## Most important differences from Jira and Confluence

- {{up to 5, one line each, with the link to the row in differences.md}}

## Sources

- Code: {{repo@commit for every repository used}}
- Jira: {{keys}}
- Confluence: {{page titles with links}}

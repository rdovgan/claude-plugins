# Module map

Source repositories of the workspace and how they connect. Built by `/qa-docs:map` from build files and code, edited by people; keep it short and factual. Domain-specific detail belongs in `domains.md` and the domain documents.

Updated: {{YYYY-MM-DD}} by {{user}}

## Repositories

| Repository | Kind | Role in the product | Talks to |
| --- | --- | --- | --- |
| `{{repo}}` | {{maven / php / js}} | {{one line}} | {{repos, external systems; how: library, REST, queue, DB}} |

## How they connect

```mermaid
flowchart LR
  {{repo}} --> {{repo}}
```

{{shared libraries, bundled artifacts, shared DB, queues, HTTP calls between services}}

## Notes

- {{facts a researcher must know: main project, legacy areas, where the schema lives}}

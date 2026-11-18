# Log statistics: {{KEY or name}}

What the logs say in numbers: which errors, how often, since when, and what they line up with. Log lines are masked.

- Sources: {{files, services, environment}}
- Period: {{from - to}}
- Lines read: {{n}}

## Errors by type

| Error (short, masked) | Service | Count | First | Last | Share of requests |
| --- | --- | --- | --- | --- | --- |
| {{message pattern}} | {{service}} | {{n}} | {{time}} | {{time}} | {{% or "-"}} |

## By hour

| Hour | Errors | Requests | Note |
| --- | --- | --- | --- |
| {{YYYY-MM-DD HH}} | {{n}} | {{n or "-"}} | {{deploy, partner call, peak, or "-"}} |

## Correlation

| Time | Event | Source | Effect on errors |
| --- | --- | --- | --- |
| {{time}} | {{deploy, config change, commit, partner outage}} | {{git log, release note, ticket}} | {{started / grew / stopped / none}} |

## Conclusions

{{plain text: what the main error is and what it means for the user, when it started and what it lines up with, whether it is still happening, which errors are noise, what the numbers prove and what they only suggest}}

## Key lines

```
{{up to 5 masked log lines that prove the conclusions, each with file:line}}
```

## How to check

- {{the grep / zgrep command or log query that gives the counts above}}

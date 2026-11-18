# Impact: {{KEY or name}}

How many and which records, users and partners the problem touches, from the data, with a conclusion. Every number has the query that produced it, so QA can run it again.

- Environment and database: {{prod replica / stage / ...}}
- Period: {{from - to, and why this period}}
- Taken at: {{YYYY-MM-DD HH:MM}}

## Summary

| Measure | Value | Query |
| --- | --- | --- |
| {{affected records, e.g. bookings with the wrong price}} | {{number, and the share of all}} | {{Q1}} |
| {{first and last case}} | {{dates}} | {{Q2}} |

## Breakdown

### By {{status / partner / channel / environment}}

| {{Dimension}} | Affected | Of all | Share |
| --- | --- | --- | --- |
| {{value}} | {{n}} | {{n}} | {{%}} |

### By day

| Day | Affected | Note |
| --- | --- | --- |
| {{YYYY-MM-DD}} | {{n}} | {{release, partner change, peak, or "-"}} |

## Conclusions

{{plain text, several paragraphs if needed: how big the problem is, whether it grows, stops or is constant, who suffers most and why, what it means for priority and for the fix (hotfix or not, data correction needed or not), what the numbers do not show}}

- Severity suggestion: {{critical / major / minor}} - because {{numbers}}
- Facts and assumptions: {{what is measured, what is inferred}}

## How to check

Q1. {{what it counts}}

```sql
{{SELECT ...}}
```

## Limits

- {{what could not be counted and why: no access, no field that marks the case, data older than the retention, or "none"}}

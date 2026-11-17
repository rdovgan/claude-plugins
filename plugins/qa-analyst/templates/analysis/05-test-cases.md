# Test cases: {{KEY or name}}

Expected results come from the requirements `R*`, not from how the system behaves today. Every case can be run as written, by someone who did not read the rest of the analysis, and moved into a test management tool as it is.

- Environment: {{stage / demo / ...}}
- General preconditions: {{accounts, roles, settings, feature flags}}

## Test cases

### TC-1. {{title: what is checked, in product words}}

| Field | Value |
| --- | --- |
| Requirements | {{R-ids}} |
| Type | {{positive / negative / edge / regression}} |
| Priority | {{high / medium / low}} |
| Preconditions | {{state before the test}} |
| Test data | {{which records, how to get them}} |

| # | Step | Expected result |
| --- | --- | --- |
| 1 | {{action}} | {{what the user sees, what is stored, what is sent}} |

- How to verify beyond the screen: {{log line to look for, query, status, or "-"}}

```sql
{{optional: query to find or verify the test data or the result}}
```

## Coverage

| Requirement | Test cases |
| --- | --- |
| R1 | {{TC-ids, or "not testable: reason"}} |

## Regression

- [ ] {{area to retest and why}}

## Not covered

- {{R-id or case - why it cannot be tested here (no environment, no data, needs a partner), or "none"}}

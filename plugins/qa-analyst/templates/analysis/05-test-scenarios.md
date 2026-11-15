# Test scenarios: {{KEY or name}}

Expected results come from the requirements `R*`, not from how the system behaves today.

- Environment: {{stage / demo / ...}}
- General preconditions: {{accounts, roles, settings, feature flags}}

## Scenarios

### T1. {{name}}

- Checks: {{R-ids}}
- Priority: {{high / medium / low}}
- Preconditions: {{state before the test}}
- Test data: {{which records, how to get them}}

```sql
{{optional: query to find or verify the test data}}
```

- Steps:
  1. {{action}}
- Expected result: {{what the user sees, what is stored, what is sent}}
- How to verify beyond the screen: {{log line to look for, query, status}}

## Regression

- [ ] {{area to retest and why}}

## Not covered

- {{R-id or case - why it cannot be tested here (no environment, no data, needs a partner), or "none"}}

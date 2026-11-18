# {{KEY}}: {{short title}} - for QA

- Branch: {{branch}} | PR: {{link or "not opened yet"}}
- Build / environment to test on: {{where and from when, or "after merge to ..."}}

## What changed

{{two to five sentences in product words: screens, statuses, users, partners, fields; what a user sees differently now. No class names.}}

## How to test

Preconditions and test data: {{accounts, partners, settings, records; masked}}

| # | Check | Expected result | Criterion |
| --- | --- | --- | --- |
| 1 | {{action}} | {{what must happen}} | {{acceptance criterion from the spec}} |

## Retest nearby

- [ ] {{area that shares the changed code or data, and why}}

## Not covered / known limits

- {{what was not done or not tested, or "none"}}

## Comment for the Jira ticket

```text
{{ready to paste: what changed, where to test, how, what to watch; 5-10 lines}}
```

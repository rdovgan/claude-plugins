# Regression: {{KEY or name}}

What changed in the code, which business areas it touches, and what to retest, in order.

- Compared: {{tag, release or commit}} -> {{tag, branch or commit}}
- Repositories: {{names}}

## Changes

| Change | Commits | Business area | Requirement | Risk |
| --- | --- | --- | --- | --- |
| {{what changed, in product words}} | {{short hashes}} | {{screen, process, report, integration}} | {{R-id or "-"}} | {{high / medium / low}} - {{why}} |

## Areas to retest

| # | Area | Why it can break | Priority | Test case |
| --- | --- | --- | --- | --- |
| 1 | {{area}} | {{shared code, same table, same partner call}} | {{high / medium / low}} | {{TC-id or "manual check"}} |

## Checklist

- [ ] {{check, in product words, highest priority first}}

## Conclusions

{{plain text: how risky the change is overall, which areas need a full retest and which a smoke check, what can be skipped and why, what nobody has tested yet}}

## Not checked

- {{area or change that was not analysed and why, or "none"}}

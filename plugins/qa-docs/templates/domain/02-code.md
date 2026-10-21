# Code: {{title}}

Facts seen in the code at the commits in `meta.json`. Every fact cites `repo/path/File.ext:line`.

## Entry points

| Entry point | Reference | Notes |
| --- | --- | --- |
| {{POST /api/... , SomeJob, SomeListener}} | `{{repo/path/File.java:120}}` | {{who calls it}} |

## Facts

| Id | Fact | Kind | Reference | Confidence |
| --- | --- | --- | --- | --- |
| F1 | {{what the code does, in business terms}} | {{rule / validation / state / calculation / config / integration / error / permission}} | `{{repo/path/File.java:120}}` | {{seen / inferred}} |

## Claims checked

| Claim | Verdict | Facts |
| --- | --- | --- |
| D1 | {{confirmed / differs / not found in code / partly}} | {{F3, F4}} |

## Not covered

- {{area not traced, and why (time, code generated at runtime, external system)}}

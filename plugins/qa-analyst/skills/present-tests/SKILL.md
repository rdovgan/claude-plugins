---
name: present-tests
description: Output format "tests" (on by default) - write 05-test-cases.md, test cases TC-1, TC-2, ... with requirements, type, priority, preconditions, test data and a steps table with an expected result on every step, plus the coverage of every R*. Run by analysis-report when the tests format is on or the task is a test design, when the user adds --tests, or by /qa-analyst:present tests. No code.
---

# present-tests

Test cases a QA engineer can run as written and move into a test management tool. Same rules as the other documents: plain language, no program code, personal data masked.

**Input:** `.claude/qa-analysis/<task>/` with `01-research.md`, `02-interview.md`, `03-flows.md` and `04-findings.md`. Take the expected results from the requirements `R*`, not from the current behaviour.

## Steps

1. Fill `${CLAUDE_PLUGIN_ROOT}/templates/analysis/05-test-cases.md` and save it as `.claude/qa-analysis/<task>/05-test-cases.md`:
   - test cases `### TC-1`, `### TC-2`, ..., each with the field table (requirements `R*`, type: positive / negative / edge / regression, priority, preconditions, test data) and the steps table `| # | Step | Expected result |`, an expected result on every step;
   - steps are concrete actions on screens or API calls with real (masked) values, so anyone can run the case as written; add the SQL check query to find or verify the data when useful;
   - cover the main path, the case from the ticket, negative and edge cases, and the regression areas from `04-findings.md`; for an investigation the first case reproduces the incident, for a fix check the cases retest the fix and its neighbours;
   - the coverage table lists every `R*` with its cases, or "not testable" with the reason.
2. When run on a finished analysis (`/qa-analyst:present tests`), also add the line `5. [05-test-cases.md](05-test-cases.md) - <one line>` to the reading order of `00-README.md` and name the cases to run under "What to do next". Change nothing else.

The Stop hook requires at least one `### TC-N`, a steps table for each case and `R*` references when the format is on.

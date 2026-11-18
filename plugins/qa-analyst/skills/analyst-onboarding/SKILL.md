---
name: analyst-onboarding
description: Guided interactive tour of the qa-analyst plugin - what it does and does not do, environment check, Jira login and database access, talking about a task, the report and its formats, the cheat sheet. Use only when the user runs /qa-analyst:onboarding or asks "how do I use this plugin", "I am new", "what can this plugin do".
---

# analyst-onboarding

A short guided tour (about 3 minutes) for a QA engineer. One step at a time: say what the step is for, do or show it, then ask "next?". Keep each step to a few lines, in plain language. Never print values of environment variables or file contents.

## Steps

1. **What it is.** Three lines: an analysis assistant for QA that reads the Jira ticket and the Confluence pages, the logs, the database and the code, answers in plain language in chat, and writes documents in the formats you pick (the answer, flows, findings, test cases, ticket notes, data tables, a visual or Confluence page) only when you ask for a report; no code examples and no fix instructions; it never changes code, tests, build files or application configs. Documentation (`.md` etc.), `CLAUDE.md` and `.claude/` files it can write.
2. **Environment and project.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-env.sh`, summarize works / missing / exact fix. If settings are missing, offer `/qa-analyst:setup` (it shows precisely what it adds and asks first). Do not block the tour on optional items (DB).
3. **Jira and data.** Tell the user to run `/mcp`, choose `jira`, finish OAuth with their own Atlassian account (you cannot do it for them). Confluence pages attached to tickets are read too. Screenshots and logs attached to tickets need a personal API token (`JAVA_TEAM_JIRA_URL`, `JAVA_TEAM_JIRA_EMAIL`, `JAVA_TEAM_JIRA_TOKEN`, see `docs/install.md`): the MCP server cannot download them. The `db` server is optional, read-only and takes one `SELECT` per call; the queries that prove something land in the documents so QA can re-run them. Offer to verify with a ticket key, or skip.
4. **Logs.** Logs can be a path (`~/Downloads/app.log`, `.gz` too), a pasted fragment or a Jira attachment. Big logs go to the `log-reader` agent; personal data is masked in the documents.
5. **Safety demo.** Show it live with harmless attempts: try to write a throwaway `Demo.java` in the project and let the hook block it, then point out that the message says what is allowed. Do not touch real secret files.
6. **Talk, then report.** Most of the work is a conversation: ask about a ticket, a requirement or a log, and the answer comes in chat without documents; what is settled goes into `.claude/qa-analysis/<task>/notes.md` (excluded from git automatically). When the questions are settled, pick the formats in the `formats` row above the prompt (violet = on) and press the yellow **▶ REPORT** button, or run `/qa-analyst:report`, or say "make the report": only the selected formats are written. Show the formats table from `${CLAUDE_PLUGIN_ROOT}/commands/help.md`. `/qa-analyst:analyze ABC-123` is the full run in one go (research, interview, report).
7. **Cheat sheet.** Show the table from `/qa-analyst:help`.
8. **Finish.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh` so the start-up hint stops. (To reset for a demo: `--reset`.) The tour can be repeated any time.

If the user says "skip" or "stop", jump to step 7 and finish.

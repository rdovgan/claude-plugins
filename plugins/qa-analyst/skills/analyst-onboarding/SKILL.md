---
name: analyst-onboarding
description: Guided interactive tour of the qa-analyst plugin - what it does and does not do, environment check, Jira login and database access, a first QA analysis, the documents, the cheat sheet. Use only when the user runs /qa-analyst:onboarding or asks "how do I use this plugin", "I am new", "what can this plugin do".
---

# analyst-onboarding

A short guided tour (about 3 minutes) for a QA engineer. One step at a time: say what the step is for, do or show it, then ask "next?". Keep each step to a few lines, in plain language. Never print values of environment variables or file contents.

## Steps

1. **What it is.** Three lines: an analysis assistant for QA that reads the Jira ticket and the Confluence pages, the logs, the database and the code, asks only what the sources do not answer, and writes plain-language documents (the answer, flows, findings, test scenarios, ticket notes); no code examples and no fix instructions; it never changes code, tests, build files or application configs. Documentation (`.md` etc.), `CLAUDE.md` and `.claude/` files it can write.
2. **Environment and project.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-env.sh`, summarize works / missing / exact fix. If settings are missing, offer `/qa-analyst:setup` (it shows precisely what it adds and asks first). Do not block the tour on optional items (DB).
3. **Jira and data.** Tell the user to run `/mcp`, choose `jira`, finish OAuth with their own Atlassian account (you cannot do it for them). Confluence pages attached to tickets are read too. Screenshots and logs attached to tickets need a personal API token (`JAVA_TEAM_JIRA_URL`, `JAVA_TEAM_JIRA_EMAIL`, `JAVA_TEAM_JIRA_TOKEN`, see `docs/install.md`): the MCP server cannot download them. The `db` server is optional, read-only and takes one `SELECT` per call; the queries that prove something land in the documents so QA can re-run them. Offer to verify with a ticket key, or skip.
4. **Logs.** Logs can be a path (`~/Downloads/app.log`, `.gz` too), a pasted fragment or a Jira attachment. Big logs go to the `log-reader` agent; personal data is masked in the documents.
5. **Safety demo.** Show it live with harmless attempts: try to write a throwaway `Demo.java` in the project and let the hook block it, then point out that the message says what is allowed. Do not touch real secret files.
6. **First analysis.** Explain `/qa-analyst:analyze ABC-123` (or a link, a description, a log path, or a question like "is this a bug?"): research, then an interview (answers with the keyboard), then the report. Show the seven documents with one line each (read `${CLAUDE_PLUGIN_ROOT}/commands/help.md`). Where they go: `.claude/qa-analysis/<task>/`, excluded from git automatically. `06-ticket-notes.md` holds texts to paste into the ticket.
7. **Cheat sheet.** Show the table from `/qa-analyst:help`.
8. **Finish.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh` so the start-up hint stops. (To reset for a demo: `--reset`.) The tour can be repeated any time.

If the user says "skip" or "stop", jump to step 7 and finish.

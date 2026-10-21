---
name: qa-onboarding
description: Guided tour of the qa-docs plugin for a QA engineer - what it does, the workspace check, Jira login, how a domain is documented, verified and exported, the cheat sheet. Use only when the user runs /qa-docs:onboarding or asks "how do I use this plugin", "I am new", "what can qa-docs do".
---

# qa-onboarding

A short guided tour (about 3 minutes). One step at a time: say what the step is for, do or show it, then ask "next?". A few lines per step, in the user's language. Never print secret values.

## Steps

1. **What it is.** It documents one business area at a time from the real code of all repositories, plus Jira and Confluence, and produces a verified document with flow charts that becomes the source of truth. It never changes code. Results are shared: everyone sees `qa-docs/`; sessions are personal.
2. **Workspace check.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-env.sh` and summarise: works / missing / who fixes it (most fixes are the admin's).
3. **Jira and Confluence.** The user runs `/mcp`, picks `jira` (plugin qa-docs) and logs in with their own Atlassian account. Reading is free; publishing to Confluence always asks for their approval.
4. **The flow.** `/qa-docs:document <domain, flow, Jira key or page>` runs: scope (the user confirms what is in and out) -> sources (Jira/Confluence claims) -> code research (parallel agents) -> the document -> verification (reference check, fact-check agent, the user's approval). After research it stops and asks whether to write the document. Then `/qa-docs:export <slug>` publishes it. It takes a while and spends a lot of the usage limit, so for a single question use `/qa-docs:ask <question>`: an answer from the code with references, nothing written.
5. **Where things are.** Show `qa-docs/domains.md` (or say it does not exist yet and `/qa-docs:map` builds it), and one domain folder if any exists: `domain.md` is the result; `00-scope`, `01-sources`, `02-code`, `03-verification`, `history.md` show how it was made.
6. **Rules.** One person writes a domain at a time (others see it as busy); sources are master/main, refreshed by cron; when the code changes, the session start says which domains to `/qa-docs:refresh`.
7. **Cheat sheet.** Show `/qa-docs:help`.
8. **Finish.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh` so the start-up hint stops.

If the user says "skip" or "stop", jump to step 7 and finish.

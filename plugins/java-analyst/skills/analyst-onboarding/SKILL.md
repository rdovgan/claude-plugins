---
name: analyst-onboarding
description: Guided interactive tour of the java-analyst plugin - what it does and does not do, environment check, Jira login, talking about a task, the report and its formats, the cheat sheet. Use only when the user runs /java-analyst:onboarding or asks "how do I use this plugin", "I am new", "what can this plugin do".
---

# analyst-onboarding

A short guided tour (about 3 minutes). One step at a time: say what the step is for, do or show it, then ask "next?". Keep each step to a few lines. Never print values of environment variables or file contents.

## Steps

1. **What it is.** Three lines: an analysis assistant that answers questions about a task (Jira, Confluence and the code) in chat, and writes documents in the formats the developer picks only when asked for a report; it never changes code, tests, build files or application configs; the developer implements, the documents are the guide. Documentation (`.md` etc.), `CLAUDE.md` and `.claude/` files it can write.
2. **Environment and project.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-env.sh`, summarize works / missing / exact fix. If settings are missing, offer `/java-analyst:setup` (it shows precisely what it adds and asks first). Do not block the tour on optional items (DB).
3. **Jira.** Tell the developer to run `/mcp`, choose `jira`, finish OAuth with their own Atlassian account (you cannot do it for them). Mention that Confluence pages attached to tickets are read too, and that screenshots and logs attached to tickets need a personal API token (`JAVA_TEAM_JIRA_EMAIL`, `JAVA_TEAM_JIRA_TOKEN`, see `docs/install.md`): the MCP server cannot download them. Offer to verify with a ticket key, or skip.
4. **Safety demo.** Show it live with harmless attempts: try to write a throwaway `Demo.java` in the project and let the hook block it, then point out that the message says what is allowed. Do not touch real secret files.
5. **Talk, then report.** Most of the work is a conversation: ask about a ticket, a requirement or the code, and the answer comes in chat without documents; what is settled goes into `.claude/analysis/<task>/notes.md` (excluded from git automatically). When the questions are settled, pick the formats in the `formats` row above the prompt (violet = on) and press the yellow **▶ REPORT** button, or run `/java-analyst:report`, or say "make the report": only the selected formats are written. Show the formats table from `${CLAUDE_PLUGIN_ROOT}/commands/help.md`. `/java-analyst:analyze ABC-123` is the full run in one go (research, interview, report).
6. **Cheat sheet.** Show the table from `/java-analyst:help`.
7. **Finish.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh` so the start-up hint stops. (To reset for a demo: `--reset`.) The tour can be repeated any time.

If the developer says "skip" or "stop", jump to step 6 and finish.

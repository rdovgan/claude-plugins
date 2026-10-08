---
name: analyst-onboarding
description: Guided interactive tour of the java-analyst plugin - what it does and does not do, environment check, Jira login, a first analysis, the documents, the cheat sheet. Use only when the user runs /java-analyst:onboarding or asks "how do I use this plugin", "I am new", "what can this plugin do".
---

# analyst-onboarding

A short guided tour (about 3 minutes). One step at a time: say what the step is for, do or show it, then ask "next?". Keep each step to a few lines. Never print values of environment variables or file contents.

## Steps

1. **What it is.** Three lines: an analysis assistant that researches the task (Jira and Confluence included), interviews the developer, and writes documents; it never changes code, tests, build files or application configs; the developer implements, the documents are the guide. Documentation (`.md` etc.), `CLAUDE.md` and `.claude/` files it can write.
2. **Environment and project.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-env.sh`, summarize works / missing / exact fix. If settings are missing, offer `/java-analyst:setup` (it shows precisely what it adds and asks first). Do not block the tour on optional items (DB).
3. **Jira.** Tell the developer to run `/mcp`, choose `jira`, finish OAuth with their own Atlassian account (you cannot do it for them). Mention that Confluence pages attached to tickets are read too. Offer to verify with a ticket key, or skip.
4. **Safety demo.** Show it live with harmless attempts: try to write a throwaway `Demo.java` in the project and let the hook block it, then point out that the message says what is allowed. Do not touch real secret files.
5. **First analysis.** Explain `/java-analyst:analyze ABC-123` (or a link, or a description): research, then an interview with questions (the developer answers with the keyboard), then the report. Show the seven documents with one line each (read `${CLAUDE_PLUGIN_ROOT}/commands/help.md`). Where they go: `.claude/analysis/<task>/`, excluded from git automatically.
6. **Cheat sheet.** Show the table from `/java-analyst:help`.
7. **Finish.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh` so the start-up hint stops. (To reset for a demo: `--reset`.) The tour can be repeated any time.

If the developer says "skip" or "stop", jump to step 6 and finish.

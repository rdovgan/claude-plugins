---
name: team-onboarding
description: Guided interactive tour of the java-developer plugin for a new developer - environment check, safety demo, Jira connection, task workflow, project setup, cheat sheet. Use only when the user asks for onboarding, a tour, "how do I use this plugin", "I am new", or runs /java-developer:onboarding. Do not use for regular coding tasks.
---

# team-onboarding

A short guided tour (about 5 minutes). Go one step at a time: say what the step is for, do or show it, then ask "next?" before moving on. Keep each step to a few lines. Never change project files without asking. Never print values of environment variables or file contents.

## Steps

1. **Environment.** Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-env.sh` and summarize: what works, what is missing, the exact command to fix each gap. `JAVA_TEAM_DB_*` are optional (DB access only). Do not block the tour on missing optional items.
2. **Safety net (demo).** Explain in three lines: secrets and prod configs are unreadable, dangerous git/maven commands are blocked, commits and pushes on `master`/`main` (and any branch in `JAVA_TEAM_PROTECTED_BRANCHES`) are blocked. Then show it live with harmless commands: try `git push --force` and let the hook block it, and point out that the message names a safe alternative. Do not touch real secret files; if the user wants to see `.env` blocked, do it only when a `.env` exists in the current directory.
3. **Jira.** Tell the user to run `/mcp`, choose `jira`, and finish OAuth in the browser with their own Atlassian account (you cannot do this for them). Offer to verify by reading a ticket key they give you, or skip if they have none.
4. **How a task flows.** Explain: just give a task (a Jira key like `ABC-123`, a link, or a description) and the agent runs research -> interview -> spec (`.claude/specs/`, not committed) -> implementation -> self-check -> `/java-developer:review`. Show naming: branch `<fix|feature|epic>/<TICKET>/<Short-description>`, commit `<TICKET> <imperative summary>`. Details: `${CLAUDE_PLUGIN_ROOT}/reference/team-workflow.md` (read it, do not paste it whole).
5. **Project.** If the current directory is a Maven project without `CLAUDE.md`, offer to run `project-init`. If `CLAUDE.md` exists, mention `/java-developer:update-claude-md`. If it is not a project, skip.
6. **Cheat sheet.** Show the same table as `/java-developer:help` (read `${CLAUDE_PLUGIN_ROOT}/commands/help.md` for it).
7. **Finish.** (If the user asks to reset onboarding for a demo, run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh --reset`.) Run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh` so the start-up hint stops, and say the tour can be repeated any time with `/java-developer:onboarding`.

If the user says "skip" or "stop", jump to step 6 and finish.

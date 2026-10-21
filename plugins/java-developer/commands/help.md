---
description: Cheat sheet - what the java-developer plugin does and which commands to use
---

Output exactly this cheat sheet, then stop:

**Daily work** - just give a task: a Jira key (`ABC-123`), a link, or a description. The agent reads the ticket, sizes the task and picks the flow: **trivial** (a one or two file fix with stated behavior) goes plan in chat -> change -> tests; **standard/complex** go research -> interview -> spec -> implementation -> self-check -> review. Say "quick" or "full" to override.

| I want to | Do this |
| --- | --- |
| Take the guided tour | `/java-developer:onboarding` |
| Set up a project for Claude | say "initialize the project" |
| Refresh `CLAUDE.md` after project changes | `/java-developer:update-claude-md` |
| Review my branch before a PR | `/java-developer:review` |
| Save a session note | say "run session-summary" |
| Connect Jira | `/mcp` -> `jira` -> OAuth |
| Let the agent open Jira attachments | set `JAVA_TEAM_JIRA_URL`, `JAVA_TEAM_JIRA_EMAIL` and `JAVA_TEAM_JIRA_TOKEN` (API token) |

**Rules that will stop you** (and why): no reading `.env`/prod configs; no `git push --force`, `mvn deploy`; no commits or pushes on `master`, `main` or other protected branches.

**Naming:** branch `<fix|feature|epic>/<TICKET>/<Short-description>`; commit `<TICKET> <imperative summary>`; PR title `<TICKET> <summary>`; before a PR run `mvn -o test` for the whole module.

**Switches:** `JAVA_TEAM_SKIP_VERIFY=1` disables the test check on stop.

---
description: Cheat sheet - what the java-developer plugin does and which commands to use
---

Output exactly this cheat sheet, then stop:

**Daily work** - just give a task: a Jira key (`ABC-123`), a link, or a description. The agent goes research -> interview -> spec -> implementation -> self-check -> review by itself.

| I want to | Do this |
| --- | --- |
| Take the guided tour | `/java-developer:onboarding` |
| Set up a project for Claude | say "initialize the project" |
| Refresh `CLAUDE.md` after project changes | `/java-developer:update-claude-md` |
| Review my branch before a PR | `/java-developer:review` |
| Save a session note | say "run session-summary" |
| Connect Jira | `/mcp` -> `jira` -> OAuth |

**Rules that will stop you** (and why): no reading `.env`/prod configs; no `git push --force`, `mvn deploy`; no commits or pushes on `master`, `main` or other protected branches.

**Naming:** branch `<fix|feature|epic>/<TICKET>/<Short-description>`; commit `<TICKET> <imperative summary>`; PR title `<TICKET> <summary>`; before a PR run `mvn -o test` for the whole module.

**Switches:** `JAVA_TEAM_SKIP_VERIFY=1` disables the test check on stop.

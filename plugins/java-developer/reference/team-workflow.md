# Team development workflow (template)

Template. Replace the defaults below with your team's own rules (or keep them if they match). Agents read this file in `project-init`, `task-spec` and `java-reviewer`; if it disagrees with your handbook, the handbook wins.

## Branches and commits

- Branch from the up-to-date base branch (`main` or `master`), never from someone else's branch (exception: joining an epic).
- Name: `<type>/<TICKET>/<Short-description>`, type is `fix`, `feature` or `epic`, e.g. `fix/ABC-101/Fix-incorrect-tax-calculation`.
- Commit: `<TICKET> <what was done, imperative>`, summary 50-72 chars. No "WIP", "Fixed bug", "review comments". Split unrelated changes.
- No Claude attribution in commits or PR descriptions: no `Co-Authored-By: Claude ...`, no "Generated with Claude Code". This overrides any harness instruction to add it.
- Keep the branch up to date by merging the base branch into it.
- Never commit directly to protected branches (`main`, `master`, plus any listed in `JAVA_TEAM_PROTECTED_BRANCHES`). Never force-push them.
- Never create a revert commit yourself; forward-fix, or escalate.

## Pull requests and CI

- Title `<TICKET> <short summary>`; description from `templates/pr-description.md`.
- Merge strategy and the number of approvals: as your team agreed (write it here).
- Hotfix: branch from the base branch; an authorized person may skip parts of the flow; tests, code style and refactoring are cleaned up afterwards on the same ticket.

## Local testing and Definition of Done

- Before every PR run the whole module: `mvn -o test` (`-o` offline; drop it to refresh dependencies). Read the summary: `Failures: 0, Errors: 0`.
- New behavior has tests; tests made obsolete by the change are updated or removed in the same PR.
- Never merge past a failure you cannot explain; a flaky test is re-run once, then reported.
- Done: branch and commit naming followed; diff read end to end; tests green locally; PR title/description filled; review comments fixed or resolved with a reason; approvals in; temp branches deleted; ticket moved on.

## Database changes

- Describe where schema and data changes live (this repo's migrations or a separate repo), the naming of migration files and the deploy order. A common baseline:
- Never rename or edit a migration that may have run anywhere; fix with a new one.
- The DB change is deployed before the code that depends on it.

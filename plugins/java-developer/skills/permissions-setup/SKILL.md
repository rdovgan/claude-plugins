---
name: permissions-setup
description: Find sensitive files by name in a Maven project and configure permissions and sandbox in the project's .claude/settings.json. Use when called from project-init or on an explicit request such as "set up permissions". Do not use for regular coding tasks.
---

# permissions-setup

Finds sensitive files and configures permissions and sandbox. **Never read or print the contents of sensitive files.**

## Steps

1. Find by name only (`find`/Glob, no content reads): `.env*`; `application-*.yml`, `application-*.yaml` and `application-*.properties` except `application-test*` and `application-local*`; `*.pem`, `*.key`, `*.p12`, `*.jks`, `*.keystore`; `secrets/`; `credentials*`; dumps `*.sql.gz`, `*.dump`.
2. For `application.yml` and `application.properties` run `grep -c -i -E 'password|secret|token|api-key'` (match count only, never matching lines or values). If there are matches, propose a `deny` rule for the file.
3. Merge the findings with the base set in `${CLAUDE_PLUGIN_ROOT}/templates/settings.json`. Replace the network placeholders `<NEXUS_HOST>`, `<GIT_HOST>`, `<JIRA_HOST>` with real hosts (ask the user for unknown ones; remove entries you cannot fill, never leave placeholders). Treat any `changelog/` or `db/migration/` directory found as `ask` for edits.
4. Show the user the list of rules with an explanation of each and wait for confirmation.
5. Write to `.claude/settings.json` without removing existing rules (merge arrays without duplicates).

## File levels

- `.claude/settings.json` - generated, committed.
- `.claude/settings.local.json` - personal exceptions, in `.gitignore`.
- Do not modify `~/.claude/settings.json`.

## Output

Show only paths, file names and rules. Never show values from files.

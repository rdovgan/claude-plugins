---
name: analyst-setup
description: Set up the current project for the java-analyst plugin - check the environment, show which project settings are missing, add them to .claude/settings.json after confirmation, and list the manual steps (Jira login, DB variables). Use when the user runs /java-analyst:setup, or asks "how do I set up / configure this plugin", "what settings do I need".
---

# analyst-setup

Makes the project ready for `java-analyst` and tells the developer exactly what is missing, so nothing has to be guessed. All output is short and concrete. Never print values of environment variables or the contents of sensitive files.

## Steps

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/check-env.sh` and show the result as three groups: **works**, **missing (with the exact fix)**, **manual steps**.
2. Compute the project settings to add. Read the existing `.claude/settings.json` if there is one (it is not sensitive). Take `${CLAUDE_PLUGIN_ROOT}/templates/settings.json` as the target and merge it **without removing or changing existing entries**:
   - `extraKnownMarketplaces` + `enabledPlugins` (`java-analyst@team-plugins`): teammates get the plugin automatically. Ask the developer to confirm the marketplace URL (default in the template).
   - `permissions.allow`: reading, writing the analysis folder and read-only git commands, so there are fewer permission prompts.
   - `permissions.deny`: the secret files (`.env*`, prod/stage configs, keys, `~/.ssh`, `~/.aws`). The plugin guard also blocks them by name, this is the second layer and it covers Read and Grep.
   - `permissions.additionalDirectories`: `../<repo>` for every repository named in `${CLAUDE_PLUGIN_ROOT}/reference/modules.md` that exists next to the project (check with `ls ..`). Never add `..` itself: it holds unrelated files. Without this the agent cannot read other repositories.
   - If `enabledPlugins` also has `java-developer@...`, warn: the two plugins must not be enabled together (D-26).
3. **Before writing**, show a table: setting, what it does, status (`add` / `already there`), and wait for the developer's confirmation. Then write `.claude/settings.json` (the plugin guard allows files under `.claude/`). If nothing is missing, say so and write nothing.
4. List the **manual steps**, the ones only the developer can do:
   - Jira: run `/mcp`, pick `jira`, finish OAuth in the browser. Read-only in this plugin.
   - Database (optional): put `JAVA_TEAM_DB_URL`, `JAVA_TEAM_DB_USER`, `JAVA_TEAM_DB_PASSWORD` in `~/.zshrc` (read-only DEMO user, never commit), restart `claude`. Until then the `db` server shows **failed** in `/mcp`; this is expected, everything else works.
   - Project description for the agent: run the built-in `/init` to create `CLAUDE.md` (the plugin allows it). Documentation and `.claude/` files are writable; code, tests, build files and application configs are not.
5. Run `${CLAUDE_PLUGIN_ROOT}/scripts/mark-onboarded.sh` only if the developer has finished onboarding; otherwise suggest `/java-analyst:onboarding` for a short tour.

Do not modify `~/.claude/settings.json` or shell profiles. Do not create `AGENTS.md`.

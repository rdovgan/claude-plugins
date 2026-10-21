# qa-docs server setup (admin)

One shared workspace on the server; every QA engineer works in their own Unix account and their own Claude Code login, and the results in `qa-docs/` are shared.

```
/srv/projects/                 workspace root, owner admin, group qa
  repo-a/ repo-b/ web/ ...     source repositories: admin rw, qa read-only, updated by cron
  .qa-docs/                    admin files: config.env, sensitive.txt, branches.conf, sources.tsv, update.log
  .claude/settings.json        project settings for every session started here (admin-owned)
  .ignore                      paths searches skip: build output, dependencies (admin-owned)
  qa-docs/                     shared results: modules.md, domains.md, domains/<slug>/  (group qa, writable)
```

The real boundary is the file system: the sources are not writable for the `qa` group, whatever the agent does. The plugin hooks keep the agent within its purpose (no secrets, writes only in `qa-docs/`, read-only Jira, Confluence only under the qa-docs page) and give clear messages; they are not a substitute for permissions.

## 1. Accounts and folders

```bash
sudo groupadd qa
sudo useradd -m -G qa <qa-user>                      # one account per QA engineer
sudo mkdir -p /srv/projects/{.qa-docs,.claude,qa-docs}
sudo chown -R admin:qa /srv/projects
sudo chmod 750 /srv/projects /srv/projects/.qa-docs /srv/projects/.claude
sudo chmod 2775 /srv/projects/qa-docs                # setgid: new files stay in group qa
sudo setfacl -R -d -m g:qa:rwX /srv/projects/qa-docs # new files are group-writable whatever the user's umask
sudo setfacl -R -m g:qa:rwX /srv/projects/qa-docs
```

Install `git`, `jq` and Claude Code. Without `jq` the plugin blocks every tool call (fails closed).

## 2. Sources

As `admin`, with a **read-only** access key (deploy key or access key of your git host) in `admin`'s `~/.ssh` (mode 700, not readable by `qa`):

```bash
cd /srv/projects
git clone git@<git-host>:<org>/repo-a.git
git clone git@<git-host>:<org>/repo-b.git
# ... every repository of the product: Java, PHP, JS
chmod -R g+rX,g-w,o-rwx /srv/projects/*/
```

Branch: `main` or `master` is detected (`origin/HEAD`, then `main`, then `master`). Exceptions go to `.qa-docs/branches.conf` (template: `templates/server/branches.conf`).

## 3. Cron

```bash
crontab -e   # as admin
# nightly, when nobody works; the script takes a lock and records the result in .qa-docs/sources.tsv
30 2 * * * /path/to/claude-plugins/plugins/qa-docs/server/update-sources.sh /srv/projects
```

The working trees are mirrors: the script resets them to `origin/<branch>` and deletes untracked files. Each session records the commits it starts on; documents record the commits they describe, so `/qa-docs:refresh` knows what changed. Session start warns when a repository failed to update or is older than `QA_DOCS_STALE_HOURS`.

## 4. Settings and security

1. `.qa-docs/config.env` from `templates/server/config.env`: language, main project, Confluence site, space and parent page for export. No secrets in it.
2. `.qa-docs/sensitive.txt` from `templates/server/sensitive.txt`: extra file patterns that hold secrets in these repositories (for example `application.properties` if passwords live there). Run a secret scanner over the sources once and add what it finds by path.
3. `.claude/settings.json` from `templates/settings.json`: enables the plugin, allow list for reading and read-only Jira, `ask` for the two Confluence write tools (the user approves every publish), deny rules for secrets and for `.claude/` and `.qa-docs/`, sandbox with network limited to Atlassian (replace `<JIRA_HOST>` with your site).
4. Recommended: put the same `permissions.deny` and `sandbox` into the managed settings (`/etc/claude-code/managed-settings.json`), so a user's own settings cannot weaken them.
5. `/srv/projects/.ignore` from `templates/server/ignore`: build output, dependencies and minified files that searches skip in every repository. Without it a search over 30 repositories also goes through `target/`, `vendor/` and `node_modules/`, which spends the QA's usage limit for nothing.
6. `QA_DOCS_MAX_SUBFLOWS` in `config.env` (default 6): how many sub-flows one research run traces with parallel agents. Raise it only if the team's Claude plans allow it.
7. Confluence: create the parent page in the target space, put its id in `QA_DOCS_CONFLUENCE_PARENT`. Each QA publishes with their own Atlassian account, so their Confluence permissions apply too.

## 5. Each QA engineer

```bash
ssh <qa-user>@<server>
cd /srv/projects && claude
```

In Claude Code: log in, then `/plugin marketplace add git@github.com:rdovgan/claude-plugins.git` (or the admin preinstalls it) and `/plugin install qa-docs@team-plugins`; `/mcp` -> `jira` -> log in with their own Atlassian account; `/qa-docs:onboarding`.

Sessions start in `/srv/projects`. Starting inside one repository also works (the plugin finds the workspace as the parent), with the other repositories as `additionalDirectories`.

## Checks

- `/qa-docs:check` in a session shows what is missing.
- `.qa-docs/update.log` shows every cron run.
- Locks: `qa-docs/.locks/<domain>.lock` names who is editing; a lock frees itself after `QA_DOCS_LOCK_MINUTES` without writes.

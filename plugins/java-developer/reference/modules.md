# Module map

Template. Fill it in for your workspace, or put your own copy at `<workspace>/modules.md` (or point `$JAVA_TEAM_MODULES_FILE` to it); that copy wins over this file.

All repositories are siblings in one workspace folder: from the project, the others are `../<repo>`. The session-start hook also prints a live scan (branch, artifactId, which workspace artifacts each repo mentions in its `pom.xml`). The scan, the snapshot of other repositories and `additionalDirectories` cover only repositories whose names appear in this file in backticks (plus the current project), so list them below.

## Main project

Optional. Name the repository that holds the core business logic (also set `JAVA_TEAM_MAIN_PROJECT` so the session-start hook reminds the agent in every other repository). Typical rules to write here:

- Before changing behavior, a public method, an event or a REST contract, check how the main project uses it.
- Expect legacy style there: follow the surrounding code, do not refactor it as a side effect.

## How the repositories connect

Describe what is not obvious from the poms: shared libraries, bundled/uber artifacts, deploy or publish order, where schema changes live. Multi-repo changes usually go bottom-up: lowest-level repository first, the consumer last.

## Repositories

| Repository | Role |
| --- | --- |
| (add rows, repository names in backticks) | |

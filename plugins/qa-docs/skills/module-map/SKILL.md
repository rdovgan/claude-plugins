---
name: module-map
description: Build or update the shared maps of the workspace - qa-docs/modules.md (repositories, their roles and connections) and qa-docs/domains.md (business domains and where they live in the code). Run by /qa-docs:map; use when the maps are missing or a repository was added.
---

# module-map

Writes only `qa-docs/modules.md` and `qa-docs/domains.md`. Both are shared and edited by people too: keep what is there, correct only what the code proves wrong, never drop a manual note.

## Steps

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/scan-modules.sh`: every repository with its kind, branch, commit, build name and the workspace repositories its build files name.
2. For each repository, learn its role from cheap signals: README, top-level packages or folders, `@SpringBootApplication` / `main` classes, controllers and routes, scheduled jobs, listeners and queue names, REST clients and their base URLs (by property name), the DB tables it uses. For many repositories, run `flow-tracer` agents in parallel, 4-6 repositories each and at most 6 agents, asking for "role, entry points, outbound calls" from those cheap signals only, never a full trace. Repositories already in `modules.md` whose commit did not change are skipped.
3. Find the connections that build files do not show: HTTP calls between services, queues and topics, shared tables, files. Say how each connection works.
4. Write `modules.md` from `${CLAUDE_PLUGIN_ROOT}/templates/modules.md`: the table, a mermaid diagram of the connections (split it by area if it passes about 20 nodes), and notes (main project, legacy areas, where the schema lives).
5. Write or extend `domains.md` from `${CLAUDE_PLUGIN_ROOT}/templates/domains.md`: the business domains visible from the code (bookings, payments, cancellations, channel sync, ...), each with repositories and main entry points, marked "not documented" until a domain document exists. These rows are the starting point for `/qa-docs:document`, so name entry points concretely.
6. Every statement about a repository is something you saw; mark guesses as such.

Finish with a short summary: repositories mapped, domains listed, what is still unclear.

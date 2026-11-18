---
name: domain-visual
description: Output format "visual" - turn a domain document (doc/) into an interactive overview page (processes with their diagrams, business rules, differences from Jira/Confluence, what to test, open questions) and publish it as a private Artifact. Run after the approval when the visual format is selected, by /qa-docs:report, or by /qa-docs:refresh when visual/ exists.
---

# domain-visual

For readers who take in a domain visually. The page shows the domain at a glance and hides long text behind info buttons. It uses the same fixed template as the qa-analyst visual page: you write only the data.

**Input:** `qa-docs/domains/<slug>/doc/` (README, `flows/*.md`, `reference/*.md`, `differences.md`, `open-questions.md`) and `meta.json`. The page says nothing the document does not say. A domain without `doc/`: stop and suggest `/qa-docs:document` (or `/qa-docs:rewrite <slug>`).

## 1. Write `visual/visual.json`

Save it as `qa-docs/domains/<slug>/visual/visual.json`. The schema is the qa-analyst one (`meta`, `verdict`, `stats`, `next`, `flows`, `requirements`, `scenarios`, `questions`, `sources`); for a domain fill it like this and leave the rest out:

- `meta`: `key` the slug, `title` the domain name, `date` today, `kind` "Domain document", `type` the layout, `lang` the document language (`uk` or `en`).
- `verdict`: `label` the status (`verified` / `draft`), `tone` `good` for verified and `warn` for a draft, `confidence` from the verification, `summary` what the domain is in one or two sentences, `info` the commits and who verified it.
- `stats`: processes, business rules, differences from Jira/Confluence, open questions.
- `flows`: the overview diagram and the two or three most important processes (title, a one-line `info`, the `mermaid` source from the pages; up to about 12 nodes each, business words).
- `requirements`: the business rules (`BR*`) and the differences: `status` `ok` when the code matches Jira/Confluence, `fail` when they differ (say how in `info`), `unclear` for an open point; `source` the page and the code reference.
- `scenarios`: the "what to test" items of the process pages, the important ones, with steps when the page has them.
- `questions`: `open-questions.md`. `sources`: tickets, pages and repositories with commits.

Keep visible texts short (titles about 80 characters, the summary about 200); everything longer goes into `info`. No program code. Mask personal and secret data; no credentials, internal hosts or connection strings.

## 2. Build and publish

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/build-visual.sh qa-docs/domains/<slug>`. If it reports an error, fix `visual.json` and run it again. Never edit `visual.html` by hand.
2. Publish `visual/visual.html` (absolute path) with the `Artifact` tool: `icon` "map", `description` one sentence about the domain. If `meta.json` already has `visual` with a link, update that artifact (read it first with `action: "read"`, then publish with the same `url`).
3. Record the link in `meta.json` as `"visual": "<url>"` and in the header of `doc/README.md` as `- Visual: <url>`; append a `history.md` entry. If the `Artifact` tool is not available or publishing fails, say so in one line and point to the local file; do not retry in a loop.

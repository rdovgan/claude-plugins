---
name: domain-confluence
description: Phase 5b of qa-docs - turn the verified domain document (doc/) into Confluence pages in qa-docs/domains/<slug>/confluence/, written in Confluence HTML exactly as /qa-docs:export publishes them (info and warning panels, status lozenges, Jira cards, "Code references" expands, diagrams as pictures), with pages.json for the page tree and a local preview. Adds no facts. Run by /qa-docs:document after approval, /qa-docs:confluence, /qa-docs:update-page, and by /qa-docs:export when the pages are older than doc/.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# domain-confluence

`doc/` is the checked record: every statement with its code reference, written for verification. `confluence/` is what people read in Confluence: the same facts, shaped for readers who are not testers too (analysts, product, support, developers new to the domain). It is rebuilt from `doc/` whenever `doc/` changes; nobody edits it by hand, and you never add a fact here that is not in `doc/`.

## Who reads it and what changes against doc/

- Business words first. Class and method names stay in the "Code references" expands; the text says what the system does.
- Every page answers "what do I need this for" in its first lines (an info panel), and the root page routes readers by task ("I need to... → page"), as the team's own handbook pages do.
- Code references move out of the sentences into a collapsed "Code references" expand at the end of the section, a table `statement | reference`. Every reference of `doc/` is kept: the check scripts verify them here too.
- Exact values stay exact. Tables for anything with more than two attributes; lists for steps.
- What matters gets a panel: `panel-warning` for differences from requirements and dangerous behaviour, `panel-note` for edge cases, `panel-info` for the summary. At most three panels on a page.
- A worked example on each process page: one concrete case with the numbers it produces, built only from the facts and the test cases of the page. If the facts do not support one, leave the section out.

## Steps

1. Read `meta.json`, `doc/` (every page) and, if it exists, the current `confluence/`. Layout `domain` below; `mirror` in its own section.
2. Write the pages from `${CLAUDE_PLUGIN_ROOT}/templates/confluence/`, in the document language (translate the headings, labels and status texts; keep the file names):

   | doc/ | confluence/ | Template |
   | --- | --- | --- |
   | `README.md` | `index.html` (root) | `index.html` |
   | `flows/<flow>.md` | `<flow>.html` | `process.html` |
   | `reference/rules.md`, `states.md`, `data.md`, `config.md`, `integrations.md` | `rules.html`, `states.html`, `data.html`, `config.html`, `integrations.html` | same names |
   | `differences.md`, `open-questions.md` | `differences.html`, `open-questions.html` | same names |

   A page whose `doc/` page does not exist is left out, with its links. A process file whose name clashes with a reference page (a process called `rules`) gets a `process-` prefix.
3. Write `confluence/pages.json` from the template: every page in the order of the README (root, processes, then rules, states, data, config, integrations, differences, open questions), its title, the `doc/` page it comes from, and `"parent": "index.html"` for the children. Titles are unique in the space: children are "<domain title>: <page title>".
4. Run `${CLAUDE_PLUGIN_ROOT}/scripts/confluence-pages.sh qa-docs/domains/<slug>` and fix every problem it reports; then `${CLAUDE_PLUGIN_ROOT}/scripts/check-refs.sh qa-docs/domains/<slug>`. The first script also writes `confluence/preview/`.
5. Tell the user in one or two lines: the pages written, and that `qa-docs/domains/<slug>/confluence/preview/index.html` shows them close to Confluence (open it in a browser; on the server, copy the domain folder or open it through the IDE). Append a `history.md` line.

## The HTML

Body fragments in the Atlassian HTML format that the MCP server accepts with `contentFormat: "html"`. Use only these patterns:

| What | HTML |
| --- | --- |
| Heading, paragraph, lists | `<h2>`, `<h3>`; `<p>`; `<ul><li><p>..</p></li></ul>`, `<ol start="1">` |
| Table | `<table><thead><tr><th><p>..</p></th></tr></thead><tbody><tr><td><p>..</p></td></tr></tbody></table>` |
| Panel | `<div data-type="panel-info">` (also `note`, `warning`, `success`, `error`) with paragraphs or lists inside; no table, expand or panel inside a panel |
| Expand | `<details><summary>Title</summary> ... </details>`; tables are allowed inside |
| Status | `<span data-type="status" data-color="green">VERIFIED</span>` (`neutral`, `purple`, `blue`, `red`, `yellow`, `green`) |
| Code, emphasis | `<code>`, `<strong>`, `<em>` |
| Jira ticket, Confluence page | `<a href="https://<site>/browse/KEY" data-card-appearance="inline"></a>` (empty: the card shows the title) |
| Link to another page of this domain | `<a href="<file>.html">text</a>`; the export turns it into the page URL |
| Diagram | `<img data-diagram="<name>" src="../doc/diagrams/<name>.png" alt="<title>">` on its own line, outside lists, tables and panels; the export uploads the PNG and puts the picture there |
| Table of contents | the `toc` extension as in `rules.html`, only on long reference pages |

Not allowed: `<html>`, `<head>`, `<body>`, markdown (`#`, `**`, `|` tables, fences), Confluence storage XML (`<ac:...>`), invented ids (`data-id`, mentions with a made-up `data-user-id`: write the role or the name as text), mermaid code blocks (the picture is enough; the source stays in `doc/diagrams/`), `{{...}}`.

## Mirror of an old page (layout `mirror`)

`doc/page.md` keeps the old page's structure; so does `confluence/page.html`: the same headings, tables and lists, converted to the HTML above, with the old page's diagrams as pictures where the document has them. The first line becomes an info panel ("Updated version of <old page card>, from the code at ..., what changed: <link to changes.html>"); the "Code references" section stays a section, in an expand. `doc/changes.md` becomes `changes.html` with the kind of each change as a status (`changed` yellow, `new` blue, `no longer in code` red). `pages.json`: `page.html` (root, titled as in `domain-export`) and `changes.html` (its child).

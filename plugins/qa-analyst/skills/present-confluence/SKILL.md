---
name: present-confluence
description: Output format "confluence" - turn a finished analysis into one Confluence-style page (confluence-page.md) for BA, PM, QA and developers alike - what the feature or problem is, how it works, the main cases, impact, decisions and open questions, at a middle level of detail. Run after analysis-report when the Confluence format is on, when the user adds --confluence, or by /qa-analyst:present confluence. Nothing is published.
---

# present-confluence

One page in the style of a team Confluence page. The reader is anyone on the team: a business analyst, a product manager, a QA engineer, a developer who wants the overview, someone updating the documentation. It is the middle cut: easy to read and informative, covers the main cases, and leaves edge cases, log lines, queries and code to the analysis documents.

**Input:** a finished analysis in `.claude/qa-analysis/<task>/`. Re-read `00-README.md`, `01-research.md`, `02-interview.md`, `03-flows.md`, `04-findings.md` and `05-test-scenarios.md`. The page says nothing the documents do not say.

## Steps

1. Fill `${CLAUDE_PLUGIN_ROOT}/templates/confluence/page.md` and save it as `.claude/qa-analysis/<task>/confluence-page.md`. Write it in the language the user uses, headings included.
2. Tell the user in one line how to move it to Confluence (see "Pasting" below). Never create or edit a Confluence page yourself: the Atlassian tools are read-only in this plugin.

## How to write it

- **Summary first.** The first section answers the reader's question in three to five sentences: what this is about, what the situation is, what is decided or still open. Someone who reads only that section knows the outcome.
- **Product words.** Screens, statuses, roles, partners, fields, business rules. No class, table or method names; no log lines, SQL or code. A system or service name is fine when the team uses it as a product word.
- **Main cases, not every case.** The cases table lists the typical paths and the case from the ticket (about 3 to 7 rows). Edge cases, negative tests and regression lists stay in `05-test-scenarios.md`; link it.
- **Requirements in plain words** with their ids `R*` and where each comes from, so the page can be traced back to the sources.
- **One diagram at most**, the main flow in business terms. Confluence does not render mermaid by itself: keep it in a `mermaid` code block (it works with a Mermaid macro), and describe the flow in a numbered list right under it, so the page reads well without the diagram.
- **Facts and decisions apart from assumptions.** Mark what is confirmed and what is not; open questions go to their own table with who can answer.
- Tables over long paragraphs; short paragraphs over bullets that are full sentences. Delete a section that does not apply instead of writing "n/a".
- Mask personal and secret data, as everywhere.

## Pasting

In Confluence Cloud: create the page, then `+` (Insert) -> **Markdown** and paste the file content; or paste it into the editor directly, which converts headings, lists and tables. Put the diagram into a Mermaid macro if the space has one; otherwise leave the code block or attach a picture of `03-flows.md`.

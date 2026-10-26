---
description: Bring an old Confluence page up to date with the code - writes a new version in exactly the old page's structure, with a list of what changed, and publishes it next to the qa-docs pages with a link comment on the old page. The old page is not edited. Never changes code.
argument-hint: <Confluence page link or id>
---

Make an up-to-date version of this Confluence page: $ARGUMENTS

The old page is read-only: its text, structure and history stay as they are. Everything you write goes to `qa-docs/domains/<slug>/` with `meta.json` `layout` = `mirror`.

1. Read the page (`getConfluencePage`, `contentFormat: markdown`): title, version number and date, body, footer and inline comments. If it is an overview whose substance is in child pages (`getConfluencePageDescendants`), say so and ask with `AskUserQuestion` which page to update: one run updates one page; the others are separate runs.
2. If a domain in `qa-docs/domains/*/meta.json` already has this page as `source.pageId`, continue it (or `/qa-docs:refresh <slug>` if it was exported). Do not start a duplicate.
3. Save the page as read to `source/original.md` (title, version, date, URL on top, then the body). Fill `meta.json` from `${CLAUDE_PLUGIN_ROOT}/templates/domain/meta.json` with `layout` `mirror` and `source` (`pageId`, `url`, `title`, `version`, `readAt`); the slug comes from the page title.
4. Run the phases in order, without asking "shall I continue" between them. The stops are the scope confirmation, the go-ahead after research, and the approval in verification.
   - `domain-scope`: the scope is what the page describes. Map each section of the page to a sub-flow (or to "not code": manual procedures, contacts, history), find the entry points, and confirm with the user. If a documented domain in `qa-docs/domains.md` covers the same area, name it: its `02-code.md` facts are reused in research and only the gaps are traced.
   - `domain-sources`: every statement of the old page becomes a claim `D*` with the section it came from; then the Jira tickets and comments that changed this area after the page's version date (newest first).
   - `domain-research`: as usual, within the budget; every claim gets its verdict.
   - `domain-write` (section "Mirror of an old page"): `doc/page.md` in the old structure, `doc/changes.md`, diagrams rendered to PNG.
   - `domain-verify`: as usual; it also checks that the structure matches the old page.
5. Finish with one short message: the folder, how current the old page was (confirmed / changed / new / removed counts), the changes that matter most, open questions, and `/qa-docs:export <slug>` if it was approved: it publishes the new page under the qa-docs parent page and adds a comment with the link on the old page.

If `$ARGUMENTS` is empty, ask for the page link.

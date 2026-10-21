---
description: Cheat sheet - what the qa-docs plugin does and which commands to use
---

Output this cheat sheet in the user's language, then stop:

**What it is**: documents one business area at a time from the **real code** of all repositories, plus Jira and Confluence. The result is a verified document with flow charts that the team uses as the source of truth for requirements and planning. It never changes code. Results are shared (`qa-docs/`), sessions are personal.

| Command | What it does |
| --- | --- |
| `/qa-docs:ask <question>` | Quick answer from the code with references; writes nothing, cheap |
| `/qa-docs:document <domain, flow, Jira key, page>` | Full run: scope -> sources -> code research (stops for your go-ahead) -> document -> verification. Expensive: use it for a domain, not for a question |
| `/qa-docs:refresh <slug>` | Update a document after the code changed |
| `/qa-docs:verify <slug>` | Verify again: references, fact-check, your approval |
| `/qa-docs:export <slug>` | Publish to Confluence (asks for your approval) |
| `/qa-docs:map` | Build or update `modules.md` and `domains.md` |
| `/qa-docs:check` | Check the workspace and the server setup |
| `/qa-docs:onboarding` | 3-minute tour |

**A domain folder** `qa-docs/domains/<slug>/`:

| File | Content |
| --- | --- |
| `domain.md` | **the document**: flows, rules, states, data, settings, integrations, edge cases, notes for testing, differences from Jira/Confluence |
| `00-scope.md` | what is in and out, actors, entry points |
| `01-sources.md` | what Jira and Confluence say (claims D1, D2, ...) |
| `02-code.md` | facts from the code (F1, F2, ...) with `repo/path:line`, and a verdict for every claim |
| `03-verification.md` | reference check, fact-check, who approved |
| `history.md`, `meta.json` | who changed what, on which commits; status and Confluence page |

**Good to know**: the code wins over Jira and Confluence, and every difference is listed; every statement has a code reference you can open; one person edits a domain at a time; when the code changes, the session start names the domains to refresh; nothing is published without your approval.

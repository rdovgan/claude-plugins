---
name: present-visual
description: Output format "visual" - turn a finished QA analysis into an interactive page (verdict, next steps, flow diagrams, timeline, requirements chart, checklist of test scenarios, ready-to-paste ticket text) and publish it as a private Artifact. Run after analysis-report when the visual format is on, when the user adds --visual, or by /qa-analyst:present visual.
---

# present-visual

For readers who take in information visually. The page shows the result at a glance and hides every long text behind an info button. It is built from a fixed template, so every analysis looks the same: you write only the data.

**Input:** a finished analysis in `.claude/qa-analysis/<task>/`. Re-read `00-README.md`, `01-research.md`, `03-flows.md`, `04-findings.md`, `05-test-scenarios.md` and `06-ticket-notes.md`. The page says nothing the documents do not say; if a document is missing, finish the analysis first.

## 1. Write `visual.json`

Save it as `.claude/qa-analysis/<task>/visual.json`. Every section except `meta` and `verdict` is optional: leave out what this task does not have instead of filling it with filler.

```json
{
  "meta": { "key": "ABC-123", "title": "short name of the problem", "date": "YYYY-MM-DD", "kind": "QA analysis", "type": "investigation", "lang": "uk" },
  "verdict": { "label": "Bug", "tone": "bad", "confidence": "high", "summary": "the answer in one or two sentences", "info": "what it rests on" },
  "stats": [ { "value": "3/5", "label": "requirements match", "tone": "warn", "info": "..." } ],
  "next": [ { "title": "File the bug", "tag": "06-ticket-notes", "info": "..." } ],
  "flows": [ { "title": "Now", "tag": "differs", "tone": "bad", "info": "...", "mermaid": "flowchart TD\n  A[...] --> B{...}" } ],
  "timeline": [ { "time": "14:05:31", "service": "payment", "title": "what happened", "tone": "cause", "info": "...", "detail": "masked log line", "source": "payment.log:1244" } ],
  "requirements": [ { "id": "R1", "title": "short wording", "status": "ok", "info": "verbatim requirement or what differs", "source": "page or ticket" } ],
  "scenarios": [ { "id": "T1", "title": "...", "priority": "high", "covers": ["R2"], "pre": "...", "steps": ["...", "..."], "expected": "...", "data": "..." } ],
  "questions": [ { "text": "...", "who": "analyst", "info": "why it matters" } ],
  "ticket": { "title": "bug title or comment title", "text": "the text from 06-ticket-notes.md" },
  "sources": [ { "kind": "jira", "label": "ABC-123", "url": "https://..." } ]
}
```

Values:
- `meta.lang`: `uk` or `en`, the language of the user; it sets the page labels. Write all texts in that language.
- `verdict.tone` and `tone` elsewhere: `bad` (bug, broken), `warn` (gap, unclear, needs a decision), `good` (works as designed, fixed), `info` (neutral). Timeline `tone`: `cause` (the first cause, exactly one), `error`, `warn`, `ok`, `info`.
- `confidence`: `high`, `medium`, `low`. Requirement `status`: `ok` (matches), `fail` (does not match), `unclear`, `untested`. Scenario `priority`: `high`, `medium`, `low`.
- `stats`: leave it out and the page computes requirements, checks, open questions and sources. Give it only when other figures matter more (affected bookings, failed requests, period).

## 2. Keep the page light

- Visible texts are short: `verdict.summary` up to about 200 characters; every `title`, `label` and `expected` up to about 80. Anything longer, every explanation, quote, reason and number goes into `info`, which opens on hover or tap. No paragraphs in visible fields.
- At most 5 `next` items, 3 `flows` with up to about 12 nodes each, 15 `timeline` events (the key ones, not every log line), 3 lines per `detail`.
- Flows are in business words (screens, statuses, users, partners), never class names. Put "now" and "expected" side by side when they differ; mark the point where they differ.
- No program code anywhere on the page, same as the documents.

## 3. Privacy: the page leaves the machine

Publishing uploads the page to claude.ai. It stays private to the user until they share it, but treat it as leaving the machine:
- mask personal and secret data: emails, phone numbers, card numbers, names of guests or customers, passwords, tokens, API keys, internal host names and IP addresses, connection strings;
- no raw log dumps or table dumps: only the few masked lines that prove a point;
- no credentials or environment values, ever.
If the case cannot be shown without such data, keep the detail in the local documents and say "see 04-findings.md" in `info`.

## 4. Build

Run `${CLAUDE_PLUGIN_ROOT}/scripts/build-visual.sh .claude/qa-analysis/<task>`. It checks the JSON, fills the template and writes `visual.html` next to it. If it reports an error, fix `visual.json` and run it again. Do not edit `visual.html` by hand: it is regenerated from the data, and the template already follows the Artifact page rules.

## 5. Publish

- Publish `visual.html` (absolute path) with the `Artifact` tool: `icon` "checklist", `description` one sentence with the verdict. The page title comes from the key and title in `meta`.
- If `00-README.md` already has a `- Visual: https://...` link from an earlier conversation, update that artifact instead of creating a new one: read it first (`action: "read"` with that `url`), then publish with the same `url`.
- If the `Artifact` tool is not available, or publishing is refused or fails, do not retry in a loop and do not look for other ways to host the page: tell the user in one line, and point them to the local file (it opens in a browser; diagrams then show as text).

## 6. Record it

Add or update one line in the header list of `00-README.md`, under `- Type:`:
- `- Visual: <artifact link>`, or
- `- Visual: not published (<reason>); local file visual.html`.

Give the link in your final message.

---
name: present-visual
description: Output format "visual" - turn an analysis into an interactive page (verdict, next steps, flow diagrams, requirements chart, solution options with effort and risk, the implementation plan) and publish it as a private Artifact. Run by analysis-report when the visual format is in the report, last.
---

# present-visual

For readers who take in information visually. The page shows the result at a glance and hides every long text behind an info button. It is built from a fixed template, so every analysis looks the same: you write only the data.

**Input:** the task folder `.claude/analysis/<task>/` (`notes.md`, and `01-research.md` and `02-interview.md` when written) and what this conversation established, and every document of the other formats that exists (`00-README.md`, `03-flows.md`, `04-findings.md`, `05-proposals.md`, `06-implementation-guide.md`, `07-dev-guide.md`). The page says nothing the sources do not say. Without the summary, take the recommendation, the flows and the plan from the notes and the conversation; leave out a section there is nothing for.

## 1. Write `visual.json`

Save it as `.claude/analysis/<task>/visual.json`. Every section except `meta` and `verdict` is optional: leave out what this task does not have instead of filling it with filler.

```json
{
  "meta": { "key": "ABC-123", "title": "short name of the task", "date": "YYYY-MM-DD", "kind": "Analysis", "type": "feature", "lang": "uk" },
  "verdict": { "label": "Option B", "tone": "good", "confidence": "high", "summary": "the recommended solution and why, in one or two sentences", "info": "what it rests on" },
  "stats": [ { "value": "M", "label": "effort", "info": "..." } ],
  "next": [ { "title": "Answer Q1 before step 3", "tag": "Q1", "info": "..." } ],
  "flows": [ { "title": "Now", "tag": "current", "tone": "info", "info": "...", "mermaid": "flowchart TD\n  A[...] --> B{...}" } ],
  "timeline": [ { "time": "14:05:31", "service": "booking", "title": "what happened", "tone": "cause", "info": "...", "detail": "masked log line", "source": "app.log:1244" } ],
  "requirements": [ { "id": "R1", "title": "short wording", "status": "ok", "info": "verbatim requirement, where the code handles it today", "source": "page or ticket" } ],
  "options": [ { "name": "Option B: ...", "summary": "the idea in one sentence", "recommended": true, "effort": "M", "risk": "low", "covers": ["R1", "R2"], "pros": ["..."], "cons": ["..."], "info": "..." } ],
  "steps": [ { "title": "step name", "covers": ["R1"], "files": ["repo/path/File.java"], "info": "what to do and how to check it" } ],
  "questions": [ { "text": "...", "who": "analyst", "info": "why it matters" } ],
  "sources": [ { "kind": "jira", "label": "ABC-123", "url": "https://..." } ]
}
```

Values:
- `meta.lang`: `uk` or `en`, the language of the developer; it sets the page labels. Write all texts in that language.
- `verdict.tone` and `tone` elsewhere: `bad`, `warn`, `good`, `info`. Timeline `tone` (investigations only): `cause` (exactly one), `error`, `warn`, `ok`, `info`.
- `confidence`: `high`, `medium`, `low`. Requirement `status`: `ok` (handled today), `fail` (not handled, the task adds it), `unclear`, `untested`. Option `effort`: `S`, `M`, `L`; `risk`: `low`, `medium`, `high`.
- `steps` follow `06-implementation-guide.md` in order; `options` follow `05-proposals.md`, with exactly one `recommended`.
- `stats`: leave it out and the page computes requirements, open questions and sources; give it when effort, the number of repositories or similar figures matter more.

## 2. Keep the page light

- Visible texts are short: `verdict.summary` up to about 200 characters; every `title`, `name`, `summary` and `label` up to about 80. Explanations, quotes, reasons and numbers go into `info`, which opens on hover or tap. No paragraphs in visible fields.
- At most 5 `next` items, 3 `flows` with up to about 12 nodes each (current and proposed side by side), 4 `options`, 10 `steps`.
- No code on the page: code examples live in `05-proposals.md` and `07-dev-guide.md`. File paths in `steps.files` are fine.

## 3. Privacy: the page leaves the machine

Publishing uploads the page to claude.ai. It stays private to the developer until they share it, but treat it as leaving the machine: no secrets, credentials, tokens, connection strings, internal host names or IP addresses, personal data, raw log or table dumps. If the case cannot be shown without such data, keep the detail in the local documents and say "see 04-findings.md" in `info`.

## 4. Build

Run `${CLAUDE_PLUGIN_ROOT}/scripts/build-visual.sh .claude/analysis/<task>`. It checks the JSON, fills the template and writes `visual.html` next to it. If it reports an error, fix `visual.json` and run it again. Do not edit `visual.html` by hand: it is regenerated from the data, and the template already follows the Artifact page rules.

## 5. Publish

- Publish `visual.html` (absolute path) with the `Artifact` tool: `icon` "blueprint", `description` one sentence with the recommendation. The page title comes from the key and title in `meta`.
- If `00-README.md` or `notes.md` already has a `- Visual: https://...` link from an earlier conversation, update that artifact instead of creating a new one: read it first (`action: "read"` with that `url`), then publish with the same `url`.
- If the `Artifact` tool is not available, or publishing is refused or fails, do not retry in a loop and do not look for other ways to host the page: tell the developer in one line, and point them to the local file (it opens in a browser; diagrams then show as text).

## 6. Record it

Add or update one line in the header list of `00-README.md`, under `- Jira:` (without `00-README.md`, at the top of `notes.md`):
- `- Visual: <artifact link>`, or
- `- Visual: not published (<reason>); local file visual.html`.

Give the link in your final message.

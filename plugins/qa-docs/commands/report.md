---
description: Build the selected output formats of a documented domain - confluence (the pages as they will be published, with a local preview), visual (an interactive overview as a private Artifact). The REPORT button in the formats row runs it too. Publishes nothing to Confluence.
argument-hint: [domain slug] [--confluence] [--visual]
---

Build the outputs of a domain: $ARGUMENTS

1. **Domain.** A slug in `$ARGUMENTS`; otherwise the domain this conversation is about; otherwise ask with `AskUserQuestion`, offering the folders in `qa-docs/domains/` that have `doc/`. A domain without `doc/`: say so and suggest `/qa-docs:document` (or `/qa-docs:rewrite <slug>` for the old single-file format); build nothing.
2. **Formats.** The flags in `$ARGUMENTS` when there are any; otherwise the formats selected now (the line "formats selected now" in the context, else the session start list). If none is selected, ask with `AskUserQuestion` (multi-select).
3. Write the list, space separated, to `qa-docs/domains/<slug>/.formats.txt` (the Stop hook checks exactly these). Then build, in this order: `confluence` -> `domain-confluence`, `visual` -> `domain-visual`. Append a `history.md` entry.
4. Finish with one short message: the preview `confluence/preview/index.html`, the visual page link, and `/qa-docs:export <slug>` if the document is verified. Do not paste the pages.

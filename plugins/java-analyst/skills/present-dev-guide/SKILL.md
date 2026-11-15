---
name: present-dev-guide
description: Output format "dev" - a teaching guide for the developer who implements the task themselves (07-dev-guide.md) - the design in UML and sequence diagrams, the patterns this codebase already uses for this kind of change with real reference code, templates (skeletons with TODO) for the new pieces and their tests, and the traps. Explains how to build it; does not write the solution. Run after analysis-report when the dev format is on (default), when the developer adds --dev, or by /java-analyst:present dev.
---

# present-dev-guide

The reader is a developer who will write the code themselves and wants it explained in depth, not done for them. `06-implementation-guide.md` says **what** to do, step by step; this guide teaches **how** to build it in this codebase: the shape of the design, the patterns to follow, and templates to start from. You show the way; the developer walks it.

**Input:** a finished analysis in `.claude/analysis/<task>/`. Re-read `01-research.md`, `03-flows.md`, `04-findings.md`, `05-proposals.md` and `06-implementation-guide.md`, and re-open the source files you will cite. The guide is for the recommended option only.

## Steps

1. Find the reference code: places in this codebase (or a sibling repository) that already solve a similar problem the way the team does it (a similar endpoint, listener, validator, mapper, migration, test). Use the `code-explorer` subagent for this when the area is large. Prefer recent, clean code over legacy; if the only examples are legacy, say what not to copy from them.
2. Fill `${CLAUDE_PLUGIN_ROOT}/templates/dev-guide/07-dev-guide.md` and save it as `.claude/analysis/<task>/07-dev-guide.md`.
3. Add it to the reading order in `00-README.md` as item 7.

## What goes in

- **The design in diagrams.** A `classDiagram` of the classes involved: existing ones as they are, new ones and changed members marked (`<<new>>`, `<<changed>>`). A `sequenceDiagram` of the target call path from the entry point to the stored result. Add a state or component diagram when it helps. Each diagram is followed by a short walk-through.
- **Patterns, with real reference code.** For each pattern the change needs (how this codebase structures a service, validates input, maps DTOs, handles errors and transactions, publishes events, writes migrations, tests), name the pattern, why it fits, and quote a short excerpt (up to about 15 lines) of the **real** code that shows it, with `repo/path/File.java:line`. Quotes are copied from the file, never retyped from memory or invented. Say which design patterns apply (strategy, template method, adapter, ...) only when they really fit this code, and why.
- **Templates for the new pieces.** Skeletons in the style of the codebase: package, class, annotations, fields, method signatures, and bodies with `// TODO:` comments that say what to do and which reference to look at. A template stops at the signature and the TODO: no business logic, no finished conditions, no complete queries. Mark each one "template" and name its target file.
- **Test templates** following the conventions of the module (framework, naming, fixtures, how mocks are made): the test class skeleton and one test method per requirement with given/when/then as TODO comments.
- **Traps and anti-patterns** specific to this code: what looks right but breaks (transactions, lazy loading, caching, ordering, nulls from legacy data, other repositories using the same class), with the evidence.
- **Requirements.** Tie every section to the requirements `R*` it serves; a requirement the guide does not touch is named with the step of `06-implementation-guide.md` that covers it.

## Rules

- You explain and give templates; you never write the solution. If a template would only work once filled with the real logic, leave that logic as a TODO with a hint.
- Every file, class, method and line you cite must exist; check with Grep/Read.
- Code is illustration inside markdown code blocks; nothing is applied, no repository file changes.
- Write in the language the developer uses; code identifiers and comments in the style of the codebase.

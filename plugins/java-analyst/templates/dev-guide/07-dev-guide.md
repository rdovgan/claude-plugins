# Developer guide: {{KEY or name}}

For the recommended option: {{name}}. This guide explains how to build it; the code below is reference code and templates, not the solution. Nothing has been applied.

## The design

```mermaid
classDiagram
  {{existing classes as they are; new ones <<new>>, changed members <<changed>>}}
```

{{walk-through: which class does what, what is new, what changes}}

```mermaid
sequenceDiagram
  {{target call path from the entry point to the stored result}}
```

{{walk-through of the sequence}}

## Patterns to follow

### {{Pattern name, e.g. "Validation in the service layer"}}

- Why here: {{reason tied to the task; serves R-ids}}
- Reference: `{{repo/path/File.java:line}}`

```java
{{short excerpt copied from the reference file}}
```

- Take from it: {{what to copy}}; do not copy: {{legacy parts to avoid, or "-"}}

## Templates

### {{New or changed piece}} -> `{{target repo/path/File.java}}`

Template: signatures and TODOs only.

```java
{{skeleton in the codebase style with // TODO: what to do, see <reference>}}
```

## Test templates

### `{{target test file}}`

```java
{{test class skeleton; one method per requirement with // given / when / then TODOs}}
```

## Traps

- {{trap}}: {{why it breaks here, evidence}}; instead: {{what to do}}

## Requirements map

| Requirement | Where in this guide | Step in 06-implementation-guide.md |
| --- | --- | --- |
| R1 | {{section}} | {{step}} |

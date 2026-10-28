# States: {{title}}

> Part of [{{title}}](../README.md).

## {{entity}}

![{{entity}}: states](../diagrams/states-{{entity}}.png)

```mermaid
stateDiagram-v2
  [*] --> {{State}}
```

| From | To | Trigger | Process | Reference |
| --- | --- | --- | --- | --- |
| {{state}} | {{state}} | {{event or action}} | [{{process}}](../flows/{{flow}}.md) | `{{repo/path/File.java:120}}` |

Stored as: {{column / enum and its values}} (`{{repo/path:line}}`)

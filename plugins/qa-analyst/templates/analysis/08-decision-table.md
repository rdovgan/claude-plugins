# Decision table: {{KEY or name}}

Which result the system must give for every combination of conditions, and what it gives today. The expected results come from the requirements `R*`.

## Conditions

| Condition | Values | Where it comes from |
| --- | --- | --- |
| C1 {{e.g. user role}} | {{admin / partner / guest}} | {{R-id, screen, field}} |

## Decision table

| # | C1 | C2 | C3 | Expected result | Requirement | Today | Test case |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | {{value}} | {{value}} | {{value or "any"}} | {{result}} | {{R-id}} | {{matches / differs: how / unknown}} | {{TC-id or "-"}} |

## Status transitions

{{delete this section when statuses do not matter}}

| From | Event | To | Allowed | Requirement | Today |
| --- | --- | --- | --- | --- | --- |
| {{status}} | {{action or system event}} | {{status}} | {{yes / no}} | {{R-id}} | {{matches / differs / unknown}} |

## Conclusions

{{plain text: which combinations behave wrongly and what they have in common, which combinations the requirements do not define (gaps for the analyst), which ones are impossible and why, which rows matter most to test and why}}

## Gaps in the requirements

- {{combination or transition the requirements do not cover - question for whom}}

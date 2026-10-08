# Java change review checklist

The team extends this list. Check each item against the changed lines and their consequences.

- **Transactions:** boundaries, `readOnly`, calls to external systems inside a transaction.
- **JPA:** N+1, `fetch`, result set size, pagination.
- **Errors and retries:** error handling and retries for external integrations.
- **Idempotency:** event and webhook handlers.
- **Security:** input validation, SQL injection, secrets in code.
- **Logging:** no PII or secrets, enough context to investigate.
- **Concurrency:** thread safety of shared state.
- **Compatibility:** backward compatibility of the API and DB schema.
- **Tests:** coverage of new logic and edge cases.
- **Java level:** no language or API features newer than the project's configured Java version.
- **Code style:** follows the "Code style" section of the project `CLAUDE.md`.
- **Obsolete tests:** tests asserting behavior this change removed are updated or deleted in the same PR.
- **Database:** schema changes are a new migration (never an edited one), guarded where the statement is not re-runnable; the DB change deploys before the dependent code.
- **Cross-repo:** a change in a shared library or service is checked against its consumers (see the module map); check the merge order.
- **Process:** commits start with the Jira key; branch is named `<type>/<TICKET>/<description>`.

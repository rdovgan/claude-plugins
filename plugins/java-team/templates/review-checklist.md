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

# [MVP] Compile the first relational IR fragment into SQLite SQL

## Goal
Lower IR to parametrized, read-only SQLite SQL with explicitly documented semantic mappings.

## Acceptance criteria
- [ ] Supports `repeat_buyers` fixture end to end.
- [ ] Entity identity/set semantics are preserved (e.g., distinct results and counts where required).
- [ ] Schema/identifier handling avoids SQL injection; values are bound parameters.
- [ ] No SQL dialect features used without covered tests.
- [ ] Unsupported constructs fail explicitly instead of silently weakening conditions.

**Priority:** P0 · **Depends on:** #04

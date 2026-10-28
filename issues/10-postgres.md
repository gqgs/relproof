# [Later] PostgreSQL backend and cross-backend semantic conformance

## Goal
Demonstrate portable specifications without modifying the DSL or IR semantics.

## Acceptance criteria
- [ ] Compile and execute core fixture on PostgreSQL.
- [ ] Compare canonical result sets across interpreter, SQLite, and PostgreSQL.
- [ ] Explicitly document dialect-dependent semantics and unsupported features.
- [ ] Reuse the same specification and declared domain schema.

**Priority:** P2 · **Depends on:** #08

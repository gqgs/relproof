# [MVP] Define typed schema and entity relationship model

## Goal
A small domain schema representing tables, primary keys, columns, foreign keys, and enums without SQL surface syntax.

## Acceptance criteria
- [ ] Can represent `Customers`, `Orders`, and optionally `OrderItems`.
- [ ] Names/attribute types are statically resolvable with helpful errors.
- [ ] Primary-key identity and relational constraints are explicit.
- [ ] Unknown and ambiguous relationships fail type checking.
- [ ] Tests cover missing keys, invalid references, and incompatible types.

**Priority:** P0 · **Depends on:** #01

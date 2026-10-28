# [MVP] Implement independent finite-database reference interpreter

## Goal
Execute the typed IR over finite in-memory relations, matching its documented denotational semantics.

## Acceptance criteria
- [ ] Handles empty relations, nested comprehensions, correlated predicates, and count.
- [ ] Produces values in a canonical set result representation.
- [ ] Tests cover duplicate SQL rows versus distinct logical entities.
- [ ] Does not call the SQL compiler or generated SQL internally.

**Priority:** P0 · **Depends on:** #04

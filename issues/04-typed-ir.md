# [MVP] Design typed relational IR and lowering from Python AST

## Goal
One canonical, backend-independent representation with explicit set and predicate semantics.

## Acceptance criteria
- [ ] IR handles relation traversal, filtering, projection, correlated predicates, and count.
- [ ] Well-defined binding/scoping and record identity.
- [ ] Type checker produces no free variables or invalid operators in IR.
- [ ] AST lowers to IR deterministically; IR can be inspected in tests.

**Priority:** P0 · **Depends on:** #01, #02, #03

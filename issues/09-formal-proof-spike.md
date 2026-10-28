# [Research] Investigate proof-producing translation validation

## Goal
Evaluate whether a useful fragment admits unrestricted equivalence proofs, SMT encodings, or a certified compiler pass.

## Questions
- Is encoding the canonical IR and supported SQLite SQL into SMT tractable for common expressions?
- Can SQLSolver, QED, VeriEQL, or a custom constraint logic offer sound proofs/counterexamples for our subset?
- What assumptions about NULL, bags, collation, arithmetic, and schema constraints are required?
- What is bounded verification versus unbounded verification?

## Acceptance criteria
- [ ] Literature and implementation survey with minimal examples.
- [ ] One feasibility experiment and a clearly classified `PROVED` / `REFUTED` / `UNKNOWN` or bounded outcome.
- [ ] Written recommendation for proof-scope restrictions and trust boundaries.
- [ ] No unearned claim of formal verification from fuzzing/differential testing.

**Priority:** P1 · **Depends on:** #04, #06

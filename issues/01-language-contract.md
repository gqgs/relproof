# [MVP] Define supported Python subset and formal semantic contract

## Goal
Write a precise semantics for the first restricted Python query fragment before implementing translation.

## Scope
- `@query` functions, set/generator comprehensions, `if`, attribute access, comparisons, boolean operators, `count`.
- Decide set equality and entity identities, numeric and string comparison, determinism, and the handling (or exclusion) of NULL/Option.
- Specify accepted AST node forms and reject others.
- Define the observable result model and admissible schema constraints.

## Acceptance criteria
- [ ] Human-readable language spec and examples of accepted/rejected programs.
- [ ] Every supported construct has a compositional mathematical meaning.
- [ ] Counterexample semantics (e.g., zero rows, duplicates, missing fields) are specified.
- [ ] No assertion that arbitrary Python or arbitrary SQL is supported.

**Priority:** P0 · **Depends on:** none

# Roadmap and decision log

## North star

A person who knows Python basics and a domain schema can express a query's intended semantics without learning SQL. SQL is an implementation detail, and the implementation can be checked against an independent formal meaning.

## Phase 0 — Freeze a minimal semantic contract

- Defined set-vs-bag behavior, row identity, ordering assumptions, NULL/optional values, integer/time semantics, and query purity.
- Supported syntax includes typed `@query` functions, `set(generator)` (and equivalent set comprehensions), comparisons, boolean operators, `count`, and pure, typed, nonrecursive helper predicates.
- Reject all unsupported Python syntax rather than silently interpreting it.

## Phase 1 — MVP prototype

- Schema definitions; AST validator; typed canonical IR. Static helper resolution/composition must preserve the meaning of inlined equivalent predicates.
- Independent interpreter and SQLite compiler.
- Exact-in-scope fixture for `repeat_buyers`, with a deliberately incorrect SQL translation caught by a counterexample.
- Generated finite instances and differential checks; explicit `not proved` status.

## Phase 2 — Formal methods research

- Explore SMT translation validation, bounded equivalence counterexamples, or an inductive proof of a small compiler subset.
- Decide which restrictions permit unbounded correctness proofs.
- Track unsupported/unknown/timeouts as first-class outcomes.

## Phase 3 — Portability and human experience

- PostgreSQL backend and backend conformance tests.
- Human-readable counterexample explanation and CLI.
- AI-assisted specification drafting with user-reviewed assumptions (optional).

## Evaluation criteria

1. Can a non-SQL developer write and inspect the fixture specification correctly?
2. Can an independent interpreter and SQLite implementation agree on varied valid databases?
3. Can the system expose a simple join-multiplicity bug with a minimal counterexample?
4. Are all correctness claims scoped and honest?
5. Can a new backend implement the same IR without changing the specification?

## Explicit risks

- A Python-like surface may have different semantics from actual Python: document and minimize this gap.
- Independent implementations may share the same bug; differential agreement is not proof.
- SQL NULL/bag semantics require explicit handling or initial exclusion.
- Fully general SQL equivalence is not decidable; proof coverage must be restricted.

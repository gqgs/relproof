# RelProof

**Python-like relational specifications with portable, verifiable implementations.**

> **Status:** research concept / MVP backlog. No parser, compiler, verifier, or correctness theorem has been implemented yet.

## Motivation

SQL is powerful, but understanding the database schema and business requirements is not the same as knowing how to write or audit SQL. AI-generated SQL can return plausible but incorrect answers, and ordinary testing may miss mistakes.

RelProof explores a restricted, familiar Python syntax for specifying **what** a relational query must return, with one canonical mathematical meaning. Implementations can target multiple database engines. A reference interpreter and verification tools check whether generated implementations preserve the specification.

### Example (proposed syntax, not yet executable)

```python
@query
def repeat_buyers() -> set[Customer]:
    return {
        customer
        for customer in Customers
        if count(
            order for order in Orders
            if order.customer_id == customer.id
            and order.status == Paid
        ) >= 2
    }
```

This expresses the business rule without requiring SQL joins, grouping, or HAVING. The schema supplies `Customers`, `Orders`, identity keys, attribute types, and declared relationships.

## Key design decisions

- **Python syntax, not arbitrary Python execution.** Parse with `ast`; whitelist constructs and reject unsupported features explicitly.
- **Semantics over sugar.** Model queries as finite sets of typed records initially. No implicit bags, truthy-null coercions, or unordered-versus-ordered ambiguity.
- **Single specification, multiple backends.** A typed relational IR is interpreted independently and compiled to SQL dialects.
- **AI is untrusted.** AI may help users author specs or propose optimized SQL, but doesn't decide whether a generated implementation is correct.
- **Separate tests from proofs.** Differential/property-based tests detect counterexamples; passing them is NOT a proof. An `UNKNOWN` verification result is not a success.
- **Human intent remains external.** Proof of SQL ↔ specification does not prove that the specification captures a person's original intention.

## Intended architecture

```
restricted Python source (@query)
          │
          ▼
  Python AST whitelist + typed schema checks
          │
          ▼
        typed IR ────────────────┐
          │                      │
          ▼                      ▼
  reference interpreter    SQL compiler (SQLite first)
          │                      │
          └──────────┬───────────┘
                     ▼
             differential checks
                     │
                     ▼
    [future] translation validation / proof engine
```

### Correctness target

For every well-typed spec `S`, backend `B`, and admissible finite database `D` satisfying declared schema constraints:

`Eval_B(Compile_B(S), D) = Eval_spec(S, D)`

Equality is with respect to an explicit result model (set semantics, record identities, and typed values), after a defined encoding between domain values and backend rows. Establishing this for *all* admissible `D` requires a proof or sound decision procedure; enumerating test databases is not sufficient.

## MVP definition

A small but meaningful proof of concept:

1. Specify a deliberately narrow query fragment and its semantics.
2. Parse/type-check the supported Python subset and lower it to a typed relational IR.
3. Independently interpret that IR on finite in-memory databases.
4. Compile it to SQLite SQL, preserving set and value semantics.
5. Run a `repeat_buyers` case end-to-end and use generated counterexamples to detect one intentionally faulty SQL rewrite.
6. Document what is **tested**, what is **proved**, and what remains **unknown**.

The first MVP does **not** require AI, a verified compiler, complex aggregation, arbitrary Python execution, or multiple SQL dialects. The verification research spike assesses the next step.

## Non-goals for the first iteration

- Competing with SQL's full expressive power.
- Executing user-written Python as an ORM.
- Claiming that differential testing is a mathematical proof.
- Guaranteeing correctness against every bug in a database engine.
- Natural-language interpretation without explicit user validation.

## Work plan

See `docs/ROADMAP.md`.

## Related work

- [Cosette / QED](https://github.com/uwdb/Cosette): relational query equivalence research.
- [SQLSolver](https://github.com/SJTU-IPADS/SQLSolver): automatic SQL equivalence verification.
- [Q*cert](https://querycert.github.io/): verified foundations for query compilation.
- [Logica](https://github.com/EvgSkv/logica): logic-based query language compiled to SQL.
- [PRQL](https://github.com/PRQL/prql): readable pipeline-oriented query language.

These are inspirations, not dependencies chosen for the MVP.

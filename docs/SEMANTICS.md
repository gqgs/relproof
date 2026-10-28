# Draft semantic contract — questions to settle before coding

This is a **design checklist**, not an implemented standard.

## Proposed initial choices

- Domain collections are finite *sets of typed entity identities*, not bags. Each entity has a stable identity supplied by the schema.
- Query output is a set. Result ordering is unspecified; sorting/limiting are out of scope for MVP.
- Attribute types initially: `bool`, fixed-width or arbitrary integers (choose explicitly), strings (with defined equality/collation), enums, identity references. Optional attributes are rejected until Option semantics are specified.
- `count(x for x in R if p(x))` counts distinct entities in the qualifying set, not joined SQL rows. This is critical for the duplicate-line-item counterexample.
- Only pure expressions are permitted: no side effects, mutation, function calls except whitelisted builtins/domain predicates, I/O, reflection, recursion, generator side effects, or arbitrary imports.
- Unknown names, mismatched types, unsupported AST nodes, and ambiguous domain relationships are compile errors.
- The schema explicitly declares relational tables, primary keys, enum encodings, and optionally foreign keys. Constraints define which database instances are admissible.
- Database mapping must state how SQL values convert to domain values and back.

## Research questions

- Should specs contain entity sets or structural values, and how does structural equality work?
- What mathematical treatment of optional values best fits both Python and SQL semantics?
- How should overflow, string comparison, time zones, and decimal arithmetic be modeled?
- Is `count(generator)` closer to existing Python mental models than an explicit `count_where(R, pred)`?
- How do we distinguish `PROVED`, `COUNTEREXAMPLE`, `UNKNOWN`, `UNSUPPORTED`, and `TIMEOUT`?

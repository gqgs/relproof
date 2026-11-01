# RelProof MVP semantic contract — version 0.1

**Status:** normative design for issue #1; no parser, interpreter, compiler, or
verification procedure is implemented by this document. “Must” and “reject” are
requirements for future implementations. This contract supersedes the draft
checklist. It defines only the fragment below, not arbitrary Python or SQL.

The [conformance examples](../examples/SEMANTIC_CASES.md) supply a concrete schema,
accepted/rejected sources, and hand-derived database results. They supplement,
but do not replace, these rules.

## 1. Schema and admissible databases

A schema Σ declares finitely many nominal entity types E, exactly one base relation
R_E per type, a distinguished field `id`, and a finite map of other field names
to scalar types. It also declares nominal enums and their finite nonempty sets of
members. Relation names, entity/enum names, enum member names, and source function
names must be globally distinct and must not collide with `query`, `set`, `count`,
`bool`, `int`, `str`, or `Key`. Field names are local to their entity type.
Names used as identifiers must be ASCII Python identifiers, excluding keywords.
Schema declarations are external metadata, not Python classes or executable code;
the schema serialization/API is a later implementation decision.

An admissible database D assigns each E a finite set of keys K_E and an immutable
record for every key. An entity value is the pair (E, k), k ∈ K_E. The record map
is a total function: every declared field exists, has exactly its declared type,
and has one value. There are no undeclared fields. The `id` field returns k typed
as Key[E]. Each base relation denotes {(E, k) | k ∈ K_E}.

Requirements on ingestion (including a future SQLite adapter):

- Exactly one record per key per entity type; duplicate base keys are invalid,
  even if the repeated rows are identical. Conflicting records are also invalid.
- Every field is required and non-null. Missing fields, NULL/None, invalid enum
  members, invalid scalar encodings, and out-of-range integers are invalid data.
- Every Key[E] field refers to an existing key in K_E (a mandatory foreign key,
  except for E's own primary key). No implicit joins or relationship traversal.
- Each |K_E| is at most 2^63 − 1. Empty relations and cyclic foreign-key graphs
  are permitted when all references exist in the complete snapshot.
- One immutable snapshot is used for the whole query, including helper calls.
  Physical row order has no meaning.

Invalid input is a validation error, not an empty query result and not a
counterexample to correctness on admissible databases. No adapter may repair
invalid input silently by dropping rows, filling fields, coercing types, or
merging duplicate base records. Intermediate repeated occurrences of an entity
are different: those are valid and collapse under the set rules in §4.

## 2. Types, values, and equality

There are no implicit conversions, subtyping, polymorphism, or nullable types.
In particular, bool and int are distinct, despite Python's treatment of booleans.

| Type | Values | Allowed comparisons |
| --- | --- | --- |
| `bool` | true, false | `==`, `!=` |
| `int` | mathematical integers in [−2^63, 2^63 − 1] | `==`, `!=`, `<`, `<=`, `>`, `>=` |
| `str` | finite sequences of Unicode scalar values | `==`, `!=` |
| enum T | the distinct members declared for T | `==`, `!=` within T |
| `Key[E]` | nominal E keys, encoded by signed 64-bit integers | `==`, `!=` within Key[E] |
| entity E | (E, k) in D | `==`, `!=` within E, by key |
| `set[E]` | finite subsets of R_E | `==`, `!=` within set[E], extensionally |

Only identical operand types may be compared. Thus an Order key cannot be
compared with a Customer key or an int literal, even if their encodings coincide.
Entity equality never compares attributes structurally. Different keys with
otherwise identical attributes remain distinct entities. Set equality means
exactly the same typed identities, irrespective of order or derivation count.
No record literals, tuples, scalar sets, heterogeneous sets, or structural record
equality are supported.

Integer comparisons use the usual mathematical order. No arithmetic operators
are supported. Negative integer literals are allowed; they do not introduce a
general negation operation. `count` returns an int without overflow: it counts a
subset of one K_E, whose size is bounded in §1. Neither wraparound nor promotion
to floating point is allowed.

String equality compares the exact decoded scalar sequence. It is case-sensitive,
with no normalization, locale collation, trimming, or numeric coercion. For example
`"A" != "a"` and `"\u00e9" != "e\u0301"`. Escapes denote their decoded values.
NUL is allowed; surrogate code points are not. String ordering is rejected.
Enums have no ordering and are not interchangeable with their string encodings.
There are no floats, decimals, dates/times, bytes, Option, NULL, or three-valued
logic in this version.

## 3. Source fragment and static rejection

A source module contains an optional leading string docstring, zero or more
helper definitions, and exactly one query definition. Declaration order does not
matter. All definitions, including unused helpers and all boolean branches, must
be checked. Comments and parentheses have no semantic effect. Imports and schema
construction in source are not permitted.

A query has exactly the decorator `@query`, no parameters, and a return annotation
`set[E]`. A helper has no decorators, zero or more typed positional-or-keyword
parameters, and return annotation `bool`. Its parameter types may be scalar types
or entity types from §2, but not set types. Calls supply positional arguments only,
with exactly the declared arity and types. All function bodies consist of an
optional leading string docstring and exactly one `return expression`. The return
expression must have exactly the annotated type (bool for helpers). Query
functions are entry points and cannot be called from source.

Annotations are static names (`bool`, `int`, `str`, entity/enum names), `Key[E]`
for helper parameters, and `set[E]` for query returns. Quoted annotations, type
parameters, defaults, positional-only/keyword-only parameters, variadic parameters,
and annotations with executable expressions are rejected.

The expression grammar below is schematic; type and scope rules further restrict
it. `C` is a comprehension with at least one generator, `n` is a name, and `f` is
a statically resolved helper name.

```text
value   ::= n | True | False | integer-literal | string-literal
          | value.field | count(C) | count(S)
          | f(value, ...) | not value | value and value | value or value
          | expr comparison expr
S       ::= relation-name | {C} | set(C) | set(S)
expr    ::= value | S
C       ::= value for n in S [if value]* [for n in S [if value]*]*
comparison ::= == | != | < | <= | > | >=
```

`value.field` requires an entity receiver and a declared scalar field; it is not
Python attribute lookup. Helper arguments must satisfy their annotations. Every
filter and boolean operand must have type bool. The projection of C must have an
entity type E; C denotes a set[E]. Each generator source has a set type, and its
binder gets the corresponding entity type. There is no scalar projection such as
`count(order.customer_id for order in Orders)`.

`set` and `count` each take exactly one positional argument and no keywords.
A generator expression is allowed only as that direct argument; it cannot escape,
be returned bare, or be passed to helpers. `set(S)` is the identity on sets,
including `set({C})`; zero-argument `set()` and set literals are excluded. An empty
set can be expressed by a comprehension with a false filter. A query may return
any expression of its declared set type, including a base relation.

### AST allowlist (context-sensitive, reject everything else)

| Python AST form | Allowed context/restriction |
| --- | --- |
| `Module`, `FunctionDef`, `arguments`, `arg`, `Return` | Exactly the module/signatures/bodies above; no type comments/type parameters |
| `Expr(Constant(str))` | Only an optional leading module/function docstring, ignored |
| `Name`, `Load` | Resolved expression names, decorators, annotations, or call targets as specified |
| `Constant` | bool, in-range int, or valid str only (docstrings are ignored text) |
| `Attribute` | Load of a declared field on an entity expression |
| `SetComp`, `GeneratorExp`, `comprehension` | Rules above; `is_async = 0`; target is one `Name(Store)` |
| `Call` | Bare-name `set`, `count`, or declared helper only; no keywords/star arguments |
| `BoolOp(And/Or)`, `UnaryOp(Not)` | Boolean operands only |
| `UnaryOp(USub, Constant(int))` | Negative literal only; child must be a non-bool, nonnegative integer token; combined value must fit int64 |
| `Compare` | Exactly one operator and one comparator; only `Eq`, `NotEq`, `Lt`, `LtE`, `Gt`, `GtE`, subject to §2 |
| `Subscript` | Annotation `set[E]` or `Key[E]` only, never runtime indexing |

For the minimum int literal `-9223372036854775808`, range-check the signed literal
as a unit, not its positive AST child. All ordinary integer literals must fit.
Chained comparisons, `is`, membership tests, assignments (including walrus),
statement `if`, conditional expressions, loops, lambdas, nested definitions,
classes, mutation, exceptions, `await`, `yield`, f-strings, comprehensions yielding
scalars/tuples, method calls, reflection, and arbitrary builtins are rejected.
The `if` in this fragment is exclusively a comprehension filter.
The allowlist is not permission to execute any AST with Python `eval`/`exec`.

## 4. Compositional meaning

Write ⟦e⟧(D, ρ) for the denotation under database D and a lexical environment ρ
mapping bound variable identities to values. Schema symbols and helper definitions
live in a fixed global environment G. Source names are resolved to these bindings
before evaluation; Python globals and builtins do not participate.

- A literal denotes its typed value. A bound name denotes its ρ value; a relation
  name denotes R_E; an enum member name denotes its declared member.
- For ⟦e⟧ = (E, k), ⟦e.a⟧ = D(E, k).a.
- A comparison denotes the boolean relation in §2 on the two operand denotations.
- `not`, `and`, and `or` denote logical negation, conjunction, and disjunction.
  They return bool, never an operand value. All expressions are pure and total on
  admissible inputs; short-circuit evaluation is optional and cannot change the
  denotation or suppress static errors.
- ⟦set(S)⟧ = ⟦S⟧. ⟦count(S)⟧ = |⟦S⟧|. For a generator argument, first use the
  comprehension denotation below. `count` never counts derivations or SQL rows.

For C = `e for x1 in S1 if p11 ... for xm in Sm if pm1 ...`, start with A₀ = {ρ}.
For each clause i, form:

```text
Aᵢ = { ρ'[xᵢ ↦ v] |
       ρ' ∈ Aᵢ₋₁,
       v ∈ ⟦Sᵢ⟧(D, ρ'),
       every ⟦pᵢⱼ⟧(D, ρ'[xᵢ ↦ v]) is true }
⟦C⟧(D, ρ) = { ⟦e⟧(D, ρ') | ρ' ∈ Aₘ }
```

Braces here are mathematical sets, deduplicated by the equality in §2. Filters
with no conditions are true. An empty source contributes no environments.
Both `{C}` and `set(C)` denote ⟦C⟧. Projection may select an outer entity instead
of the innermost generator variable; repeated projected identities still collapse.
There is no implied iteration order. Nested comprehensions/counts are evaluated
in the environment where they occur, so correlated predicates are well-defined.

Consequences for quantification (where P is bool and R is set[E]):

```text
exists x ∈ R: P(x)  ⇔  count(x for x in R if P(x)) > 0
no x ∈ R: P(x)      ⇔  count(x for x in R if P(x)) == 0
forall x ∈ R: P(x)  ⇔  count(x for x in R if not P(x)) == 0
```

These are explanatory equations, not additional source syntax. On an empty R,
the first is false and the latter two are true. Cardinality-based universal
quantification must project the quantified entity; counting some other entity
can change the proposition.

## 5. Lexical bindings and pure helper composition

Helper parameters are distinct and scoped only to their own body. Each
comprehension introduces a new lexical scope. A generator binder is visible in
its filters, subsequent generator sources/filters, and the final projection,
but not in its own source. Generator binders must be distinct within one
comprehension. They may shadow a parameter or a binder in an enclosing
comprehension; no local binder may shadow any global symbol in G. A binder does
not leak beyond its comprehension. Unbound names are errors, even on unreachable
branches. No caller-local variable is visible inside a helper.

For `f(e1, ..., en)`, let f have parameters a1, ..., an and return body b. Evaluate
arguments in the caller environment to values v1, ..., vn, then:

```text
⟦f(e1, ..., en)⟧(D, ρ) = ⟦b⟧(D, {a1 ↦ v1, ..., an ↦ vn})
```

The body retains the fixed G and D, not caller locals. Free names in b must resolve
to globals. Helpers are first-order predicates, not values. Calls resolve to a
unique module helper; direct and indirect recursion are rejected by checking the
entire helper call graph for cycles. Calling the query is rejected.

An inliner must perform capture-avoiding substitution: alpha-rename local binders
to fresh identities before replacing formals with argument expressions. Textual
replacement of matching name strings is incorrect. The acyclic call graph and
finite comprehensions give terminating, deterministic mathematical evaluation.
Resource exhaustion in an implementation is an error/timeout, never a result.

For the existing inline and composed `repeat_buyers` programs, expansion yields:

```text
{ c ∈ Customers |
  |{ o ∈ Orders | o.customer_id = c.id ∧ o.status = Paid }| ≥ 2 }
```

`is_paid` supplies the second conjunct, `belongs_to` the first, and
`is_repeat_buyer` the cardinality comparison. This equation specifies their
required equivalence for every admissible database, not just the sample fixtures.
It is a definitional derivation, not a machine-checked compiler proof.

## 6. Results, backend boundary, and counterexamples

A successful query returns exactly a set of typed identities of its declared
entity type. Attributes can be recovered from that same snapshot; presentation
order is not observable. The observable equality is §2 set equality, not Python
object identity, a SQL row list, or equality after erasing entity types.

A future backend adapter must declare a lossless encoding and decoding:

- int and key payloads use exact signed 64-bit integers; bool uses distinct
  validated encodings (for SQLite, integer 0/1); enums use an injective mapping.
- Strings preserve the scalar sequence exactly. Backend comparisons must implement
  §2 equality, irrespective of default column collation or affinity.
- Tables encode one full record per identity and satisfy §1. Validation is against
  the actual snapshot; merely declaring a SQL constraint is insufficient if it
  was not enforced. NULL is never mapped to an ordinary domain value.
- Query output decoding validates typed keys and membership in D, then takes the
  set of identities. Repeated output rows are harmless under this result model;
  multiplicity inside a count is not. Malformed output is an implementation error.

The preservation target is:

```text
Decode_B(Eval_B(Compile_B(S), Encode_B(D))) = ⟦S⟧(D, ∅)
```

This target applies to well-typed S and admissible D within a backend's explicitly
declared support. A backend that cannot represent or evaluate a supported value
must report unsupported/resource failure rather than approximate it or silently
narrow the language. A claim of full v0.1 support covers all this contract.
The exact SQLite adapter, IR data structures, and algorithm choices are follow-up
work; this document fixes their semantic obligations independently.

A counterexample consists of a well-typed spec, schema, admissible finite snapshot,
candidate implementation, and unequal decoded results (preferably their symmetric
difference of identities). A missing field or duplicate base key is an invalid
fixture, not a counterexample. See the concrete witnesses in the examples.

Passing finite fixtures means only agreement on those fixtures. No verifier status
API is implemented here. Future reports must distinguish demonstrated mismatches,
unsupported/invalid inputs, resource failures/unknown outcomes, and any proved
result with its actual assumptions and scope. No proof is established by this PR.

## 7. Deliberate restrictions and later review

These are resolved v0.1 choices; changing them requires a contract revision:

| Choice | Reason / question for later review |
| --- | --- |
| int64, no arithmetic, bounded entity cardinality | Exact SQLite-oriented MVP; revisit big integers, arithmetic and overflow together |
| One int64 key and one base relation per nominal entity | Simple identity decoding; revisit composite/external keys and relation subsets |
| Mandatory total foreign keys | Avoid dangling/optional references; revisit unconstrained references explicitly |
| Exact string equality only | Avoid backend collation dependencies; revisit normalized text and ordering |
| No NULL/Option, dates, decimals or floats | Define value/logic/encoding semantics before adding these |
| Entity-only sets; bool-returning helpers | Keep deduplication and composition unambiguous; revisit structural projection and set-valued helpers |
| Zero-argument queries; single-return bodies | Narrow parser/IR scope; revisit parameters, local bindings and conditionals |
| External trusted schema and validated snapshot | Schema ingestion/constraint validation need their own implementation and review |

No ordering, pagination, aggregation other than entity count, mutation, Python
runtime interoperation, or arbitrary SQL equivalence is promised by this contract.

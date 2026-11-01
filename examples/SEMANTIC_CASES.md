# Semantic conformance cases (v0.1)

These are normative expected outcomes for the [contract](../docs/SEMANTICS.md),
not executable tests or evidence of a working RelProof implementation. `.py` files
here are DSL source to parse, **not** modules to import or execute as Python.
Each file is a separate module with exactly one query. Every case uses the schema
below unless a rejection case explicitly changes it.

## Schema shared by the examples

| Entity / relation | Fields (all required) |
| --- | --- |
| Customer / Customers | id: Key[Customer], name: str, active: bool, age: int |
| Order / Orders | id: Key[Order], customer_id: Key[Customer], status: OrderStatus |
| Line / Lines | id: Key[Line], order_id: Key[Order] |

OrderStatus is the nominal enum with globally named members `Paid` and `Pending`.
Key fields reference their named entity relation. There are no additional schema
constraints: negative ages, for example, are valid int values in this fixture
schema. Keys are shown below as integers only for compact data notation, not as
untyped DSL literals. All lists describe complete base relations, not SQL bags.

Abbreviations for **full records**:

```text
C(k)       = Customer(id=k, name="same", active=true, age=30)
O(k,c,s)   = Order(id=k, customer_id=c, status=s)
L(k,o)     = Line(id=k, order_id=o)
```

An empty list means an empty relation. For every row below, the column `repeat`
is the expected result of **both** [inline](repeat_buyers.py) and
[composed](repeat_buyers_composed.py) repeat_buyers. `with_lines` refers to
[identity_count.py](identity_count.py); `all_paid` to
[quantification.py](quantification.py). Results show Customer keys; their type is
always Customer, not Order or raw int.

| Case | Customers | Orders | Lines | repeat | with_lines | all_paid |
| --- | --- | --- | --- | --- | --- | --- |
| A: empty database | [] | [] | [] | {} | {} | {} |
| B: no orders | [C(1)] | [] | [] | {} | {} | {1} |
| C: one order, duplicate join occurrences | [C(1)] | [O(10,1,Paid)] | [L(100,10), L(101,10)] | {} | {} | {1} |
| D: two distinct orders with equal non-key fields | [C(1)] | [O(10,1,Paid), O(11,1,Paid)] | [L(100,10), L(101,11)] | {1} | {1} | {1} |
| E: status matters | [C(1)] | [O(10,1,Paid), O(11,1,Pending)] | [L(100,10), L(101,11)] | {} | {} | {} |
| F: correlation matters | [C(1), C(2)] | [O(10,1,Paid), O(11,2,Paid)] | [] | {} | {} | {1,2} |
| G: identical customer attributes | [C(1), C(2)] | [O(10,1,Paid), O(11,1,Paid), O(12,2,Paid), O(13,2,Paid)] | [] | {1,2} | {} | {1,2} |
| H: empty joined relation | [C(1)] | [O(10,1,Paid), O(11,1,Paid)] | [] | {1} | {} | {1} |

The joins in `with_lines` deliberately add an existence requirement. That program
is not equivalent to repeat_buyers: H demonstrates the difference.

## Small counterexample witnesses

**C: counting occurrences rather than projected identities.** The two environments
(order=10,line=100) and (order=10,line=101) both project Order(10). The generated
set is {Order(10)}, so its count is 1. The following *intentionally wrong candidate
SQL* counts two joined rows and returns Customer(1):

```sql
SELECT c.id
FROM Customers AS c
JOIN Orders AS o ON o.customer_id = c.id
JOIN Lines AS l ON l.order_id = o.id
WHERE o.status = 'Paid'
GROUP BY c.id
HAVING COUNT(*) >= 2;
```

For this SQL illustration, keys are SQLite INTEGER values and OrderStatus uses
TEXT encodings `'Paid'` and `'Pending'`. Case C is admissible; it witnesses a
mismatch against `identity_count.py`, with symmetric difference {Customer(1)}.
Changing this candidate's aggregate to `COUNT(DISTINCT o.id)` removes this
particular bug. Passing C alone is not evidence of general correctness.

**D: deduplicating the wrong thing.** The two orders have distinct identities, so
`count(order for order in Orders if order.customer_id == customer.id)` is 2.
Counting distinct customer IDs or distinct statuses gives 1 and wrongly excludes
Customer(1). RelProof excludes scalar projection, but an incorrect compiler could
still introduce this mistake.

**B: empty quantification.** The paid-order count is 0; “at least two” is false,
“there exists a paid order” is false, and “all orders are paid” is true. A compiler
that drops customers with no orders via an inner join changes the last result.
For A, even vacuous truth produces no customers because the outer relation is empty.

**E/F: helper expansion must preserve filters and correlation.** Dropping is_paid
incorrectly returns {1} on E. Dropping belongs_to counts two paid orders globally
and incorrectly returns {1,2} on F. Both correct repeat_buyers forms return {}.

**G: structural deduplication loses identities.** C(1) and C(2) have the same
non-key attributes, but the correct result contains both identities. Neither
name equality nor equality of the non-key record is entity equality.

**Lexical capture.** [lexical_helpers.py](lexical_helpers.py) returns Order keys
{} on A, {} on C, and {10,11} on D. On D each candidate has a different other
order. Naive replacement of `candidate` by the caller text `order` produces
`order != order` inside the helper's comprehension and incorrectly returns {}.
A valid expansion first renames the helper-local binder:

```python
@query
def orders_with_company() -> set[Order]:
    return set(
        order for order in Orders
        if count(other for other in Orders if other != order) > 0
    )
```

## Additional accepted programs

Each block is a complete, independent module. Expected results use the same schema.
These cover relation returns, redundant set wrapping, exact comparisons, and scope.

```python
@query
def everyone() -> set[Customer]:
    return set({c for c in Customers})
```

Equivalent to `return Customers` and `return set(c for c in Customers)`, including
on empty inputs. On G all three return {Customer(1), Customer(2)}.

```python
def within_range(c: Customer) -> bool:
    return c.age >= -9223372036854775808 and c.age <= 9223372036854775807


@query
def exact_match() -> set[Customer]:
    return {c for c in Customers if within_range(c) and c.active == True
            and c.name == "same" and not (c.name == "Same")}
```

Returns all customers in A–H. If C(1).name is replaced by `"Same"`, it is excluded.
A predicate `"\u00e9" == "e\u0301"` is false; `"\u00e9" == "é"` is true.

```python
@query
def set_equality() -> set[Customer]:
    return {c for c in Customers if Customers == set(x for x in Customers)}
```

Returns Customers. Equality is typed, extensional set equality, not ordered-list
equality or equal cardinality alone.

```python
def any_customer(c: Customer) -> bool:
    return count(c for c in Customers) > 0


@query
def scope_example() -> set[Customer]:
    return {c for c in Customers if any_customer(c)}
```

The inner `c` shadows the parameter, counts all customers, and does not leak into
the caller. The result is Customers, including {} on A. Alpha-renaming any binder
to a fresh name must leave the result unchanged.

## Rejected source programs

For each expression row, replace EXPR in this complete module template. Every
result must be a static rejection, even if the supplied database is empty.

```python
@query
def rejected() -> set[Customer]:
    return EXPR
```

| EXPR | Required reason for rejection |
| --- | --- |
| `(c for c in Customers)` | Bare generator escapes intrinsic |
| `{c.name for c in Customers}` | Scalar projection |
| `{(c, o) for c in Customers for o in Orders}` | Tuple/structural projection |
| `{c for c in Customers if c.missing == 1}` | Undeclared field |
| `{c for c in Customers if c.age == True}` | int/bool type mismatch |
| `{c for c in Customers if c.id == 1}` | Key[Customer]/int mismatch |
| `{c for c in Customers for o in Orders if c.id == o.id}` | Different nominal key types |
| `{c for c in Customers if c.name < "z"}` | String ordering excluded |
| `{c for c in Customers if c.age}` | No truthiness conversion |
| `{c for c in Customers if c.name == None}` | None/Option excluded |
| `{c for c in Customers if 0 < c.age < 100}` | Chained comparison excluded |
| `{c for c in Customers if c.age + 1 > 0}` | Arithmetic excluded |
| `{c for c in Customers if c.age == 9223372036854775808}` | Out-of-range int |
| `{c for c in Customers if c.name == "\ud800"}` | Surrogate is not a scalar value |
| `{c for c in Customers if True or unknown(c)}` | Unknown call checked even in dead branch |
| `{c for c in Customers if len(Orders) > 0}` | Unsupported builtin |
| `{c for c in Customers if Customers == Orders}` | Different set element types |
| `{c for c in Customers if count(c.id for c in Customers) > 0}` | count requires entity projection |
| `{c for c in Customers for c in Customers}` | Duplicate binder in one comprehension |
| `{Orders for Orders in Customers}` | Binder shadows global relation |
| `set()` | No zero-argument intrinsic |
| `{}` | Dictionary, not an empty entity set |

Each following block is also a complete rejected module:

```python
def paid(o: Order) -> bool:
    return o.customer_id == customer.id


@query
def rejected() -> set[Customer]:
    return {customer for customer in Customers if paid(customer)}
```

Reject both the free `customer` inside paid (caller locals are unavailable) and
the Customer argument supplied where Order is required.

```python
def first(c: Customer) -> bool:
    return second(c)


def second(c: Customer) -> bool:
    return first(c)


@query
def rejected() -> set[Customer]:
    return Customers
```

Reject the indirect recursive cycle even though neither helper is used. Direct
self-calls are rejected by the same graph rule. Forward calls without a cycle
are valid.

```python
@query
def rejected() -> set[Customer]:
    if True:
        return Customers
    return Customers
```

Reject statement `if` and the non-single-return body. Comprehension filters are
the only supported `if` construct. Likewise, imports, assignments, custom
decorators, default/keyword arguments, and method calls are excluded by the AST
allowlist, not interpreted as Python behavior.

## Invalid database cases (not semantic counterexamples)

Start with case C and apply each mutation separately:

| Mutation | Expected validation error |
| --- | --- |
| Append the identical O(10,1,Paid) again | Duplicate base identity, even with identical values |
| Append O(10,1,Pending) | Conflicting duplicate base identity |
| Remove C(1).name | Missing required field |
| Set C(1).name to NULL | Null field forbidden |
| Set C(1).age to true, `"30"`, or 2^63 | Wrong scalar type or range; no coercion |
| Set O(10).status to an undeclared member | Invalid enum value |
| Change O(10).customer_id to 2 | Dangling mandatory foreign key |
| Add an undeclared field to C(1) | Record does not match schema |

No one of these may be reported as successful evaluation with {} or silently
normalized into a valid database. In contrast, repeating a projected identity
through the two distinct Lines of C is valid and is deduplicated.

## Future implementation checks

Use these cases as shared inputs and expected outputs for the AST/type checker,
independent IR evaluator, and SQL backend, with rejection cases kept separate
from query-result comparisons. Add generated admissible databases later; do not
label these finite checks as proof. In particular, check inline/composed agreement,
alpha-renaming invariance, empty quantification, type-preserving decoding, and the
explicit wrong-SQL witness before making any broader correctness claim.

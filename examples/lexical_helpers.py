"""Accepted v0.1 DSL: a caller's `order` must not be captured by helper binders."""


def has_other_order(candidate: Order) -> bool:
    return count(order for order in Orders if order != candidate) > 0


@query
def orders_with_company() -> set[Order]:
    return set(order for order in Orders if has_other_order(order))

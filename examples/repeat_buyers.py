"""Accepted RelProof v0.1 DSL; schema and expected results: SEMANTIC_CASES.md."""

@query
def repeat_buyers() -> set[Customer]:
    return set(
        customer for customer in Customers
        if count(
            order for order in Orders
            if order.customer_id == customer.id
            and order.status == Paid
        ) >= 2
    )

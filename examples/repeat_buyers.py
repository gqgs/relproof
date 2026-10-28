"""Proposed RelProof source syntax; illustrative only, not executable yet."""

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

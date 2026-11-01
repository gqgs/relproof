"""Accepted v0.1 DSL: count orders, even when each has multiple matching lines."""

@query
def repeat_buyers_with_lines() -> set[Customer]:
    return set(
        customer for customer in Customers
        if count(
            order for order in Orders
            for line in Lines
            if line.order_id == order.id
            and order.customer_id == customer.id
            and order.status == Paid
        ) >= 2
    )

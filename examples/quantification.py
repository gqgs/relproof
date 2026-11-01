"""Accepted v0.1 DSL: all of a customer's orders are paid, vacuously if none."""

@query
def all_orders_paid() -> set[Customer]:
    return {
        customer for customer in Customers
        if count(
            order for order in Orders
            if order.customer_id == customer.id
            and not (order.status == Paid)
        ) == 0
    }

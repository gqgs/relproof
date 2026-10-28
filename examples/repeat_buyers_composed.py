"""Illustrative RelProof source syntax: pure helper composition, not yet executable."""


def is_paid(order: Order) -> bool:
    return order.status == Paid


def belongs_to(order: Order, customer: Customer) -> bool:
    return order.customer_id == customer.id


def is_repeat_buyer(customer: Customer) -> bool:
    return count(
        order for order in Orders
        if is_paid(order)
        and belongs_to(order, customer)
    ) >= 2


@query
def repeat_buyers() -> set[Customer]:
    return set(
        customer for customer in Customers
        if is_repeat_buyer(customer)
    )

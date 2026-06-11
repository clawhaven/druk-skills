# Good And Bad Tests

## Good Tests

Good tests verify observable behavior through real interfaces.

```python
def test_user_can_checkout_with_valid_cart():
    cart = create_cart()
    cart.add(product)

    result = checkout(cart, payment_method)

    assert result.status == "confirmed"
```

Characteristics:

- Names describe a capability.
- Setup resembles real caller usage.
- Assertions check outcomes, not implementation.
- Internal refactors should not require test rewrites.

## Bad Tests

Implementation-detail tests couple to internal structure.

```python
def test_checkout_calls_payment_service(mocker):
    process = mocker.patch("app.checkout.payment_service.process")

    checkout(cart, payment_method)

    process.assert_called_once()
```

Red flags:

- mocking internal collaborators
- testing private methods
- asserting call counts or order when the user-visible behavior is elsewhere
- querying storage directly when the public read interface would prove the behavior
- test names that describe how the code works instead of what it does

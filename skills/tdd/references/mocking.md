# Mocking

Mock at system boundaries:

- external APIs
- payment, email, SMS, auth, or analytics providers
- time and randomness
- filesystem or network where isolation is required
- databases only when a test database is impractical

Do not mock:

- your own classes or modules
- internal collaborators
- code you control just to avoid wiring it

## Boundary Interfaces

Prefer dependency injection for external clients.

```python
def process_payment(order: Order, payment_client: PaymentClient) -> PaymentResult:
    return payment_client.charge(order.total)
```

Avoid constructing hard external dependencies deep inside domain code.

Prefer SDK-style methods over generic fetchers. Specific methods make mocks simpler and typed results clearer:

```python
class BillingApi:
    def get_customer(self, customer_id: str) -> Customer: ...
    def create_invoice(self, payload: InvoicePayload) -> Invoice: ...
```

# CONTEXT.md Format

Use `CONTEXT.md` as a concise domain glossary.

## Structure

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**: A customer's request for goods or services.
_Avoid_: purchase, transaction

**Invoice**: A request for payment sent to a customer after delivery.
_Avoid_: bill, payment request

## Relationships

- An **Order** produces one or more **Invoices**.
- An **Invoice** belongs to exactly one **Customer**.

## Example Dialogue

> **Developer:** When a **Customer** places an **Order**, do we create the **Invoice** immediately?
> **Domain expert:** No. An **Invoice** is generated only once fulfillment is confirmed.

## Flagged Ambiguities

- "account" was used to mean both **Customer** and **User**. Resolution: these are distinct concepts.
```

## Rules

- Be opinionated. Pick one canonical term and list aliases to avoid.
- Keep definitions to one sentence when possible.
- Define what the concept is, not what it does in the code.
- Include only domain-specific concepts, not generic programming terms.
- Use bold term names in relationships.
- Group terms under subheadings only when natural clusters emerge.

## Single vs Multi-Context Repos

Single-context repos usually have one root `CONTEXT.md`.

Multi-context repos should have a root `CONTEXT-MAP.md`:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) - receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) - generates invoices and processes payments

## Relationships

- **Ordering -> Billing**: Ordering emits `OrderPlaced`; Billing consumes it to create invoices.
```

If neither file exists, create a root `CONTEXT.md` lazily when the first term is resolved. If the relevant context is unclear, ask before writing.

# Deep Modules

A deep module has a small interface and a substantial implementation behind it.

```text
Small Interface
---------------
Deep Implementation
```

A shallow module has a large interface and little hidden behavior. Avoid adding one unless it is a deliberate integration adapter.

Ask:

- Can the number of methods be reduced?
- Can parameters be simplified?
- Can more complexity live behind the interface?
- Does the interface express the domain language?

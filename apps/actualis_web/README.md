# Actualis Web

`actualis_web` is the HTTP adapter for the Actualis umbrella. It depends on the public contexts of
`actualis_core` and `actualis_manufacturing`; it does not own authority, transaction, or product
rules.

From the repository root:

```sh
bin/setup
bin/mix-local phx.server
```

Then visit the [health endpoint](http://localhost:4000/api/health) or the
[OpenAPI document](http://localhost:4000/api/openapi.json).

Development identity headers are a local proof mechanism, not production authentication. See the
[Core technical reference](../../docs/technical/core-kernel/README.md) and the
[manufacturing reference](../../docs/technical/manufacturing-reference/README.md).

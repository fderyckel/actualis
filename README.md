# Actualis Core

Actualis Core is a production-oriented constitutional-kernel proof built as an Elixir/Phoenix modular monolith backed by PostgreSQL.

The implemented vertical slice proves that one pallet movement can be:

- requested by a resolved human and device identity;
- authorized by active principal, device trust, site assignment, purpose, grant, and policy version;
- protected by idempotency and expected-version concurrency;
- committed with the pallet movement, evidence, outbox event, and two filtered projection deltas in one transaction;
- replayed safely or reconstructed from retained evidence.

## Architecture challenge and scope

The proposal is directionally sound, but its 9–12 month roadmap is not one implementation unit. This repository deliberately implements the Stage 1 exit condition and a thin synchronization proof. It does not pretend that development headers are authentication or that an outbox row is delivered integration.

The command body cannot choose its principal, device, or capability. The local HTTP adapter injects identity from headers, and authority data determines device trust. Production must replace those headers with verified OIDC and authenticated device credentials.

## Local setup

Elixir 1.20.2, Erlang/OTP 29, PostgreSQL 18.4, Hex, and Phoenix dependencies are installed or pinned locally.

```sh
bin/setup
bin/mix-local phx.server
```

Then open [the OpenAPI document](http://localhost:4000/api/openapi.json) or check [health](http://localhost:4000/api/health).

Run verification with:

```sh
bin/mix-local quality
MIX_ENV=prod bin/mix-local compile --warnings-as-errors
```

## Demo command

After `bin/setup`, submit:

```sh
curl -X POST http://localhost:4000/api/v1/capabilities/manufacturing.move_pallet \
  -H 'content-type: application/json' \
  -H 'x-actualis-principal-id: 33333333-3333-4333-8333-333333333333' \
  -H 'x-actualis-device-id: 44444444-4444-4444-8444-444444444444' \
  -d '{
    "purpose":"fulfil_material_movement",
    "scope":{"site_id":"11111111-1111-4111-8111-111111111111"},
    "input":{
      "pallet_id":"77777777-7777-4777-8777-777777777777",
      "source_location_id":"22222222-2222-4222-8222-222222222221",
      "destination_location_id":"22222222-2222-4222-8222-222222222222",
      "reason":"Replenish production"
    },
    "expected_version":1,
    "idempotency_key":"demo-move-0001"
  }'
```

Repeating the identical request returns the original command and evidence identifiers with `"replayed": true`. Reusing the key with a different request is rejected.

## Current production blockers

- OIDC verification and cryptographic device authentication;
- outbox delivery, signing, acknowledgement, retry, reconciliation, and dead letters;
- append-only evidence enforcement, object evidence, and retention;
- projection revocation worker, realtime transport, and offline client storage;
- rate limiting, security telemetry, deployment templates, recovery rehearsal, and production-shaped benchmarks;
- the operator tablet and supervisor workbench user interfaces.

See [ADR 0001](architecture/adrs/0001-first-kernel.md), the [threat model](architecture/threat-models/pallet-move.md), and the [technical reference](docs/technical/core-kernel.md).

## Engineering standards

All new and materially changed code and documentation follows the
[Actualis engineering standards](docs/engineering/README.md). The standards define the
core/kernel boundary, Elixir/Phoenix/Ecto/PostgreSQL conventions, documentation requirements, and
the automated and human merge gates.

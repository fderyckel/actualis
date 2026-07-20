# Actualis v0

Actualis v0 is a production-oriented constitutional-kernel proof built as an Elixir/Phoenix modular monolith backed by PostgreSQL. The umbrella contains a domain-neutral Core, a separately owned manufacturing reference application, a Phase 0 Stock domain application, and a web adapter.

The manufacturing reference application consumes Core through a generic capability handler port. The applications are co-deployed and share one database transaction; this is a module boundary, not a microservice boundary. The implemented vertical slice proves that one pallet movement can be:

- requested by a resolved human and device identity;
- authorized by active principal, device trust, site assignment, purpose, grant, and policy version;
- protected by idempotency and expected-version concurrency;
- committed with the pallet movement, evidence, outbox event, and two filtered projection deltas in one transaction;
- replayed safely or reconstructed from retained evidence.

The [Stock domain application](docs/technical/stock/README.md) currently defines only its package
boundary, organisation scope, capability vocabulary, and telemetry names. It has no registered
handler, persistence, route, or user interface.

## Architecture challenge and scope

The proposal is directionally sound, but its 9–12 month roadmap is not one implementation unit. This repository deliberately implements the Stage 1 exit condition and a thin synchronization proof. It does not pretend that development headers are authentication or that an outbox row is delivered integration.

The command body cannot choose its principal, device, or capability. The local HTTP adapter injects identity from headers, and authority data determines device trust. Production must replace those headers with verified OIDC and authenticated device credentials.

The [Phase 0 evidence gate](architecture/phase-0/README.md) tracks operational narratives,
workload hypotheses, safe datasets, surface-prototype briefs, threat models, and benchmark evidence.
It is explicitly in progress and must not be treated as validated field research.

## Local setup

Elixir 1.20.2, Erlang/OTP 29, PostgreSQL 18.4, Hex, and Phoenix dependencies are installed or pinned locally.

```sh
bin/setup
bin/mix-local phx.server
```

Then open [the OpenAPI document](http://localhost:4000/api/openapi.json) or check [health](http://localhost:4000/api/health).

For a minimal Debian or Ubuntu VM, follow the
[fresh-VM evaluation guide](docs/user/installation/fresh-vm.md). It keeps Phoenix and PostgreSQL
private and uses an SSH tunnel for access.

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

Docker Engine is optional host preparation, not an Actualis installer. The repository does not yet
contain a Dockerfile, Compose manifest, or published application image; see the [deployment status
and production gaps](docs/technical/deployment/README.md).

See the [pallet-movement application-module decision](architecture/adr/0006-pallet-movement-application-module.md), the [threat model](architecture/threat-models/pallet-move.md), the [Core technical reference](docs/technical/core-kernel/README.md), and the [manufacturing reference](docs/technical/manufacturing-reference/README.md).

## Engineering standards

All new and materially changed code and documentation follows the
[Actualis engineering standards](docs/engineering/README.md). The standards define the
core/kernel boundary, Elixir/Phoenix/Ecto/PostgreSQL conventions, documentation requirements, and
the automated and human merge gates.

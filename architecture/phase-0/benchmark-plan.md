# Phase 0 benchmark plan

Status: workload and measurement contracts prepared; only the current in-process Core/PostgreSQL
command path has a runnable smoke harness.

## Measurement contract

Every result must record artifact revision, runtime versions, hardware, topology, dataset version,
row and byte counts, concurrency, duration, warm-up, command mix, failure count, p50/p95/p99, pool
wait, database time, and known deviations from the target topology. A developer-laptop result is not
a production-shaped capacity claim.

## Candidate matrix

| Candidate | Question | Minimum representative test | Current status |
| --- | --- | --- | --- |
| PostgreSQL layout | Can one cell preserve command latency, lock behavior, audit queries, and recovery at the declared authoritative data size? | Grow a synthetic cell toward 1 TB, run governed command and audit mixes, inspect plans, locks, WAL, backup and restore | Direct command smoke harness only |
| Phoenix connections and fan-out | Can the chosen topology sustain the connection and delta envelope with bounded memory and backpressure? | Step toward 10,000 connected clients using realistic subscription and reconnect distributions | No realtime adapter; not runnable |
| SQLite/OPFS sync | Does local projection catch-up remain correct under offline duration, duplicate, out-of-order, revocation, and quota cases? | Browser and native SQLite adapters over the same recorded sync trace | No sync adapter; not runnable |
| ClickHouse telemetry | Does the candidate meet ingest, retention, and investigation-query needs without becoming authoritative state? | Replay a site-shaped synthetic telemetry trace and defined query set | Candidate deliberately unselected; not runnable |

The absent adapters are not a reason to adopt them. Build only the smallest representative adapter
needed to answer the recorded question, then accept, reject, or defer the candidate.

## Current runnable slice

`evals/phase0/benchmark.exs` measures the in-process governed pallet command with real PostgreSQL
writes, authority checks, evidence, outbox, and projections. It uses isolated SQL-sandbox
transactions and synthetic identities. It deliberately excludes HTTP, network fan-out, external
delivery, and production contention.

Run it only after the test database is migrated:

```sh
MIX_ENV=test mix run evals/phase0/benchmark.exs --commands 100 --concurrency 4
```

Its output is a smoke measurement and harness check, not a Phase 0 benchmark conclusion.

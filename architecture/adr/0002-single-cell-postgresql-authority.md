# ADR 0002: Single-cell PostgreSQL authority

- Status: Accepted baseline
- Date: 2026-07-18

## Context

The walking skeleton needs strong relational constraints, reconstructable decisions, idempotent delivery, and a realistic recovery path without distributed transactions or unnecessary infrastructure.

## Decision

Start with one cell and one fenced PostgreSQL writer. Store transactional truth, validated observations, relationships, policies, outbox records, and purpose-shaped projections in module-owned schemas in that cell.

Evidence metadata and content hashes live in PostgreSQL; payloads and attachments use an S3-compatible object store. Cross-store actions use outbox/inbox, idempotency, reconciliation, and compensating capabilities.

## Consequences

- The first deployment can prove transactions, migration, backup, restore, and failure containment with a small operational surface.
- Reporting, raw telemetry, AI, and solver load cannot share the interactive command pool without explicit budgets.
- Additional cells and specialized stores require measured workload evidence and their own recovery story.

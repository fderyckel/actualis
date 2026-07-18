# Actualis Core

Actualis Core is the governed authority, decision, commitment, execution, and evidence kernel described in *Actualis Stack - Architecture Vision and Implementation Blueprint v0.1* (17 July 2026).

This repository contains the core architecture only. Manufacturing, education, commerce, experience packages, edge agents, telemetry, solvers, AI, communication providers, and wire-protocol adapters are consumers or adjacent components. They do not belong in the core.

## Core responsibility

Actualis Core owns:

- cell and principal context;
- capability registration and governed invocation;
- authorization policy evaluation and obligations;
- commitment and calendar envelopes;
- intent, scenario, decision, and selection metadata;
- command execution, acknowledgement, compensation, and durable coordination;
- evidence, provenance, audit reconstruction, and retention metadata;
- transactional outbox/inbox and stable ports to adjacent components.

Domain packages own their relational schemas, business invariants, domain capability handlers, and domain events. Core orchestrates them without interpreting or storing their business entities.

## First outcome

The first release candidate must prove this runtime path with a conformance domain fixture:

`cell + principal + purpose -> capability contract -> authorization -> domain handler -> atomic effects + evidence + outbox -> acknowledgement -> audit reconstruction`

The fixture exists only to test the core contract. A real manufacturing or education package remains a separate product implementation and is required before calling the wider stack proven.

## Documents

- [Implementation plan](docs/IMPLEMENTATION_PLAN.md)
- [Core runtime skeleton](docs/WALKING_SKELETON.md)
- [Quality gates](docs/QUALITY_GATES.md)
- [Architecture baseline](architecture/README.md)
- [Contributing](CONTRIBUTING.md)

## Core rules

- Domain meaning stays outside the kernel.
- Every consequential action crosses one governed capability boundary.
- PostgreSQL is the authoritative relational store for a cell.
- Domain handlers own business invariants and state; Core owns invocation, authority, coordination, and evidence envelopes.
- Every caller is an identified principal, including humans, devices, integrations, workers, and AI.
- AI may be represented as a principal but cannot grant authority or approve itself.
- New infrastructure is added only after a measured quality scenario proves the need.

## Deliberately not in this repository

- Manufacturing, education, commerce, or other domain models
- Product experiences and the Surface SDK
- Edge protocol drivers and raw telemetry ingestion
- Solvers, simulations, runtime AI, and semantic analytics
- Email/SMS providers, webhooks, JSON-RPC, and other Link/Relay adapters
- A generic entity model, schema compiler, or universal ontology
- Kubernetes, NATS, Temporal, ClickHouse, OpenSearch, graph databases, or vector databases until separately justified

## Repository status

Planning and architecture baseline. No production code exists yet.

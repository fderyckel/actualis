# Phase 0 repository and boundary threat model

Status: draft for security-owner review  
Scope: current Actualis repository plus the Phase 0 boundaries that must constrain later adapters  
Reviewed evidence: repository revision `0f1463d` and uncommitted Phase 0 implementation work on
2026-07-19

## Overview

Actualis is intended to turn operational observations and human decisions into governed,
evidence-bearing commitments. The currently deployed-shaped surface is much narrower: a Phoenix
JSON adapter calls a domain-neutral Core and a co-deployed manufacturing application backed by one
PostgreSQL database. Production identity, Edge enrollment, offline sync, AI tools, provider delivery,
and cross-cell control-plane behavior do not exist yet.

The assets that matter most are:

- authoritative domain and lifecycle state;
- principal, device, assignment, grant, purpose, and policy state;
- idempotency receipts and aggregate versions that prevent duplicate or stale effects;
- evidence, provenance, outbox intent, and later delivery acknowledgements;
- cell routing and isolation metadata;
- identity, device, signing, encryption, and support-access credentials; and
- future manufacturing, education, safeguarding, and other sensitive product data.

Phase 0 threat statements about absent components are design requirements, not implemented
mitigations.

## Threat Model, Trust Boundaries, and Assumptions

### Trust boundaries

| ID | Boundary | Less-trusted side | Trusted decision or asset side |
| --- | --- | --- | --- |
| TB-01 | Network adapter to application boundary | HTTP clients, headers, JSON, route parameters | Phoenix adapter and canonical command validation |
| TB-02 | Identity proof to principal context | External IdP, device credentials, session assertions | Resolved principal, device, purpose, and cell context |
| TB-03 | Core to product handler | Registered product code and opaque product payloads | Core transaction, authority, receipt, evidence, and delivery contracts |
| TB-04 | Cell and database boundary | Other cells, support tooling, background workloads | One cell's authoritative writer and purpose-scoped reads |
| TB-05 | Support-access boundary | Staff workstation and support identity | Approved, scoped, expiring customer-cell access |
| TB-06 | Device enrollment and Edge boundary | Factory network, gateways, readers, local storage | Enrolled device identity, configuration, observation and command contracts |
| TB-07 | Offline sync boundary | Replayable, stale, reordered, copied local state | Current server authority, revocation, cursor and reconciliation state |
| TB-08 | AI and solver tool boundary | Prompts, retrieved content, model output, tool results | Typed proposal contracts and human/policy authority |
| TB-09 | Cross-system integration boundary | Webhooks, RPC clients, providers and partner retries | Versioned adapter contract, inbox, signature and delivery state |
| TB-10 | Build, evaluation and prototype boundary | Developer inputs, generated fixtures, benchmark output | Source, CI credentials, release artifacts and evidence claims |

### Input control

- **Attacker-controlled:** public request bytes, identifiers, replay timing, duplicate delivery,
  webhook bodies, network ordering, compromised browser/local storage, malicious retrieved AI
  content, and potentially a stolen device credential.
- **Operator-controlled:** purpose selection, scan inputs, movement reason, approval actions,
  support-access requests, device enrollment decisions, policy changes, and recovery operations.
- **Developer-controlled:** handler registration, migrations, contracts, prototype fixtures,
  benchmark parameters, dependencies, build configuration, and release promotion.

Operator and developer control is not automatically trustworthy. High-consequence changes require
separation of duties, bounded scope, evidence, and review.

### Security invariants

1. No principal, device, adapter, support tool, AI, or solver can bypass the governed capability
   boundary for an authoritative effect.
2. Cell and authorization scope are derived from trusted context and cannot be broadened by product
   input.
3. Product handlers cannot run an effect before authority permits it; validation remains
   deterministic and side-effect-free.
4. A duplicate, stale, expired, reordered, or context-mismatched request cannot create a second
   authoritative effect.
5. Core authorization is permission to attempt, never proof of physical truth, physical safety,
   delivery, acknowledgement, or execution.
6. Evidence distinguishes asserted origin, domain validation, authority, effect, delivery state,
   and eventual outcome.
7. Offline, support, integration, and AI access are denied by default and bounded when enabled.
8. Synthetic evaluation artifacts contain no customer data, credentials, or unsupported production
   claims.

### Assumptions and non-assumptions

- PostgreSQL and the application host are administered as trusted infrastructure, but compromised
  database or host credentials remain a high-impact threat.
- TLS, production OIDC, authenticated device credentials, signing keys, and secret delivery are not
  implemented in this repository snapshot.
- Development identity headers are attacker-controlled and are acceptable only on a loopback-bound
  evaluation surface.
- Hardware attestation can strengthen origin assurance but cannot prove that a physical claim is
  true; domain validation remains required.
- Physical interlocks, safety-rated controllers, and energy isolation remain outside Actualis and
  may always inhibit an operation.
- Prototype and benchmark artifacts do not process real personal or operational data.

## Attack Surface, Mitigations, and Attacker Stories

| Surface and attacker story | Existing mitigation | Required Phase 0 or later control |
| --- | --- | --- |
| A client self-asserts another principal, device, capability, or scope | Web adapter overwrites identity and capability; Core validates canonical input and authority scope | Replace development headers with verified OIDC and authenticated device proof; add cross-cell negative tests |
| A registered handler mutates data while canonicalizing input, before authority | Handler contract requires deterministic, side-effect-free validation | Architecture test/review enforcement; move all authoritative work to `execute/2` inside the Core transaction |
| A caller replays or races a movement | Principal-scoped receipt, deterministic request hash, row lock and expected version | Retention policy, concurrent duplicate tests, and bounded in-progress retry semantics |
| A support identity obtains standing or cross-customer access | No production support path exists | Customer-approved purpose, ticket/evidence reference, narrow cell and duration, step-up, recording, expiry, and review |
| A stolen or cloned device credential submits plausible observations | Device status and scope are represented; production proof is absent | Enrollment ceremony, credential rotation/revocation, optional hardware-backed key, sequence and clock-quality evidence, domain plausibility checks |
| A trusted sensor claim is false or refers to the wrong physical context | Current pallet state and business invariants are checked | Preserve origin separately from validation; bind device, configuration, location, calibration/assurance and observation sequence |
| An offline client replays stale or revoked projection data | Snapshot/delta cursor, expiry, revocation field and current reauthorization exist on server | Signed sync envelope, local encryption, quota, revocation watermark, bounded offline authority, duplicate/out-of-order and lost-device tests |
| Prompt injection or malicious retrieved content asks an AI tool to reveal data or execute work | No runtime AI surface exists; architecture assigns AI no authority | Typed allowlisted tools, purpose-scoped retrieval, output-as-proposal, no raw secrets, provenance, human/policy approval, egress and cost limits |
| A partner replays, forges, or redirects a webhook | Durable outbox intent exists; publisher and adapter are absent | Signature with key rotation, timestamp/nonce, inbox idempotency, SSRF-safe destinations, retry/dead-letter state and acknowledgement evidence |
| A compromised worker marks delivery successful before it occurred | Outbox row is not represented as delivery | Distinct requested, attempted, provider-accepted, delivered, seen and acknowledged states; reconciliation and least-privilege workload identity |
| A caller enumerates evidence or projection data outside purpose | Reads are reauthorized and evidence is matched on generic authorization scope | Field-level obligations, access evidence, rate limits, non-enumerable identifiers and privacy review |
| A migration or restore silently breaks evidence or scope isolation | Full migration history and fresh-database tests exist | Representative upgrade data, backup/restore hashes, old/new compatibility, bounded locks and roll-forward rehearsal |
| A developer commits customer data or secrets as a Phase 0 fixture | Versioned fixture declares synthetic classification and has executable checks | Secret/PII scanning, fixture review, output retention policy and isolated benchmark destinations |

### Out-of-scope attacker stories for the current repository

Direct exploitation of a ClickHouse cluster, browser OPFS adapter, Edge gateway, AI provider,
support console, or webhook publisher is not currently reachable because those components do not
exist. Their contract-level threats remain in scope for Phase 0 decisions and become code-level
attack surfaces only when representative adapters are introduced.

## Severity Calibration (Critical, High, Medium, Low)

### Critical

- cross-cell or cross-customer authority bypass enabling consequential writes at scale;
- a path that lets a remote principal override lower safety enforcement or dispatch arbitrary
  physical commands; or
- compromise of signing, identity, or support control that gives persistent unrestricted access to
  multiple cells without detection.

### High

- same-cell authorization bypass that moves held material or exposes protected education or
  safeguarding data;
- duplicate/replay behavior that creates a second authoritative effect;
- evidence or policy tampering that makes a consequential action unreconstructable; or
- remote compromise through an adapter with access to application or database credentials.

### Medium

- bounded denial of service exhausting a cell's command pool without cross-cell impact;
- purpose-filter failure exposing low-sensitivity operational fields inside one authorized cell; or
- support, sync, or delivery audit gaps that remain detectable and recoverable without an incorrect
  authoritative effect.

### Low

- development-only information exposure on a loopback evaluation environment;
- prototype-only UI defects that do not handle real data or call an authoritative runtime; or
- inaccurate benchmark metadata caught before an architecture or capacity decision is accepted.

Severity increases with cross-cell reach, physical or safeguarding consequence, persistence,
credential compromise, inability to reconstruct the event, and the number of affected principals.

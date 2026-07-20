# Phase 0 reality-contract evidence gate

Status: **in progress; not validated**  
Baseline date: 2026-07-19  
Canonical source: Part 20 of the
[Actualis Stack Architecture Vision v0.1](../../docs/Actualis_Stack_Architecture_Vision_v0.1.pdf)

## Purpose

Phase 0 reduces product, safety, security, usability, and scale uncertainty before the stack
hardens. It is an evidence gate, not permission to build the complete Phase 1 runtime early.

The recent Core/manufacturing extraction contributes one piece of Phase 0 evidence: product
ownership and dependency direction are executable while one local transaction is preserved. It
does not validate the operational journey, user surfaces, physical assumptions, or scale targets.

The separate `actualis_stock` application contributes another bounded-context check: a canonical
organisation scope and reserved capability vocabulary can consume Core contracts without adding
Stock semantics to Core. It intentionally registers no handler and persists no Stock state.

## Current gate status

| Phase 0 requirement | Current evidence | Status |
| --- | --- | --- |
| Shadow operational and IT/security stakeholders | Roles and interview prompts are identified, but no named owner, site observation, or interview record exists | Blocked on external participation |
| Write 20-30 operational narratives | 24 manufacturing hypotheses exist in the reality contract and have a machine-readable validation register | Drafted; unvalidated |
| Define load envelope and safe datasets | Versioned workload envelope and synthetic fixture exist under `evals/phase0` | Prepared as hypotheses |
| Prototype two education surfaces and one scan-first manufacturing surface | Three outcome briefs and evaluation protocols exist | Visual options and tested prototypes not started |
| Threat-model the required boundaries | Repository and Phase 0 boundary models cover cells, support, enrollment, sync, AI tools, and integrations | Drafted; security-owner review required |
| Benchmark PostgreSQL, Phoenix, SQLite/OPFS, and ClickHouse | A repeatable Core/PostgreSQL command-path harness exists; the other candidate adapters do not | Partial; no production-shaped result |

Phase 0 is not complete until the evidence register records named owners, observations, decisions,
measured results, and review dates. An artifact marked `prepared` is not a validated outcome.

## Evidence package

- [Evidence register](evidence-register.v0.1.json)
- [Manufacturing narrative validation register](manufacturing-narrative-validation.v0.1.json)
- [Manufacturing reality contract](../reality-contracts/manufacturing-exception-replan-v0.1.md)
- [Surface prototype briefs](surface-prototype-briefs.md)
- [Benchmark plan](benchmark-plan.md)
- [Phase 0 boundary threat model](../threat-models/phase-0-boundaries.md)
- [Participation Phase 0 gate](../participation/phase-0/README.md)
- [Workload envelope](../../evals/phase0/workload-envelope.v0.1.json)
- [Synthetic dataset](../../evals/phase0/fixtures/manufacturing-synthetic.v0.1.json)
- [Evaluation harness](../../evals/phase0/README.md)

## Decision rule

Do not select a shared SDK, telemetry store, sync mechanism, service split, or control-plane database
from an unmeasured preference. Record the workload, smallest representative adapter, result,
limitations, and decision first. A candidate may be rejected without building it at production
scale when the reality contract shows it is unnecessary.

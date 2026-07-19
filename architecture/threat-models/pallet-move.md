# Pallet-move threat model

This model covers the implemented logical inventory transition in the separately owned,
co-deployed manufacturing application recorded in
[ADR 0006](../adr/0006-pallet-movement-application-module.md). It does not claim that Core
authorizes physical machine safety, proves that a pallet physically moved, or replaces local
safety controls. [ADR 0004](../adr/0004-safety-and-operational-authority-boundary.md) defines that
boundary; [ADR 0005](../adr/0005-deterministic-replay-and-simulation-contract.md) defines the
replay boundary.

| Threat | Implemented control | Remaining work |
|---|---|---|
| Caller self-authorizes | Body identity/capability are overwritten; authority resolves database state | Replace local headers with OIDC and device proof |
| Duplicate effect | Principal-scoped key and deterministic request hash | Retention and pruning policy |
| Lost update | Row lock plus expected version | Ordered locking convention for multi-aggregate commands |
| Stale physical source | Claimed source must equal authoritative current location | Observation validation/promotion |
| Held material moves | Only released pallets can move | Break-glass and approval workflow |
| Core authorization is mistaken for physical-safety approval | Authorization and domain invariant evaluation are separate; the current effect changes logical pallet state only | Edge/device contract must let lower safety enforcement inhibit an operation and report the outcome without any Core override path |
| Delayed command executes after its context changed | Expected pallet version and idempotency protect the authoritative write | Add issued-at, expiry, enforcement-boundary, acknowledgement, and stale-context semantics before command dispatch is implemented |
| Trusted device reports a false physical observation | Evidence records the acting principal and device; current location is checked against authoritative database state | Record observation time, ingestion time, assurance/calibration references, confidence, and validation status; authentication must not be presented as physical truth |
| Historical replay repeats an effect | Completed idempotent requests return the stored receipt response and do not create a second movement | Inject or record clock and generated identifiers; guarantee that historical replay cannot publish outbox, device, solver, AI, or provider effects |
| Unrecorded nondeterminism prevents reconstruction | Request hashes, policy version, domain versions, effects, and stored outcomes support the current narrow replay | Record all promised replay inputs and version compatibility; current wall-clock and UUID generation remain internal implementation gaps |
| Future simulation mutates production | No simulation runtime is implemented | Before introducing one, isolate its namespace, disable production delivery ports, and add negative escape tests |
| Field disclosure | Separate projection payloads plus grant field filtering and reauthorization | Mask transformations and revocation worker |
| Lost downstream notification | Outbox event commits with the effect | Delivery, signature, retry, acknowledgement, dead letters |
| Evidence tampering | Evidence commits atomically with the effect | Append-only database enforcement and external anchoring |

# ADR 0004: Safety and operational authority remain distinct

- Status: Accepted baseline
- Date: 2026-07-18

## Context

Actualis governs consequential operations across Core, domain packages, Edge, devices, humans, and automated principals. Some manufacturing operations can affect hazardous equipment or energy. A valid Core authorization, authenticated command, signed observation, or successful software invariant check does not establish that the physical environment is safe.

Without an explicit boundary, capability authority could be mistaken for functional-safety authority, and cloud or general-purpose application controls could become an unintended substitute for safety-rated interlocks, controllers, guards, or physical energy isolation.

## Decision

Actualis separates operational authorization from physical and functional safety.

The authority order is:

1. physical energy isolation and safety-rated protection;
2. local safety controllers, interlocks, and device-enforced limits;
3. Edge operational enforcement;
4. Core capability authorization and obligations;
5. human, integration, solver, or AI requests.

A lower layer may reject or inhibit an operation authorized by a higher layer. A higher layer cannot override a lower safety layer. A Core authorization is permission to attempt an operation through the next enforcement boundary; it is never evidence that the operation is physically safe or that it occurred.

Safety-relevant capability contracts declare freshness, expiry, expected version, acknowledgement, idempotency, and failure behavior. Edge and device adapters reject expired, stale, payload-mismatched, or context-mismatched commands. An identical duplicate delivery is acknowledged or rejected idempotently without repeating a physical or authoritative effect. Loss of Core connectivity must not weaken an existing safety state. Any bounded disconnected operation must be explicitly defined by the owning domain package and local safety design.

In accordance with ADR 0003, domain packages own concrete safety invariants and certification artifacts. Core owns stable envelopes for criticality, authorization, obligations, command expiry, acknowledgement, and evidence references. Selected high-consequence protocols may require model-based or formal analysis, but such analysis does not replace implementation verification, equipment certification, or physical safeguards.

Cryptographic signatures and hardware-backed attestation can establish identity, origin, integrity, and measured device state. They do not prove that a sensor reading is physically true. Evidence contracts therefore preserve observation source, time, calibration or assurance references, confidence, and validation status where supplied by the domain.

## Consequences

- Actualis can add restrictive operational controls without becoming the sole safety barrier.
- Safety claims remain local to the equipment, domain, jurisdiction, and certification scope that can substantiate them.
- Edge adapters need explicit stale-command, disconnect, restart, and recovery tests.
- Evidence consumers must distinguish authenticated provenance from verified physical truth.
- AI, solvers, integrations, and operators cannot bypass safety enforcement by holding a valid Core grant.

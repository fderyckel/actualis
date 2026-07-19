# Manufacturing exception and replan reality contract v0.1

- Status: Draft for operational validation
- Architecture status: Selected lead proof journey
- Implementation status: Partial command proof; end-to-end journey unavailable
- Decision date: 2026-07-19
- Domain ownership: Manufacturing application package, outside Actualis Core
- Operational owner: Unassigned
- Decision owner role: Production planner
- Safety authority: Local physical and safety-rated controls

## Outcome

When an observed material movement or quality condition invalidates the current production
assumptions, Actualis must:

1. preserve the observation and its uncertainty;
2. prevent an unauthorized or unsafe logical transition;
3. show the operator the next permitted action;
4. identify commitments affected by the exception;
5. let an authorized planner compare and select a response;
6. obtain any required independent approval;
7. dispatch only a current, authorized decision;
8. track acknowledgement and execution evidence; and
9. reconstruct the complete path from observation to verified outcome.

This is the first product proof for Core. It is not a request to move manufacturing concepts
into the kernel.

## Why this journey leads

The repository already has a narrow pallet-movement proof with authorization, idempotency,
expected-version checks, evidence, an outbox row, and two projection shapes. Extending that
evidence into a real exception journey is lower risk than starting a second domain while the
Core boundary remains unproven.

Manufacturing also forces the important distinctions in the architecture:

- authenticated origin versus physically true observation;
- authority to attempt versus physical-safety authority;
- proposal versus approved commitment;
- command dispatch versus execution acknowledgement;
- durable outbox state versus delivered communication; and
- server authority versus bounded offline continuity.

## Scope

### Included in the proof

- One bounded plant or site in one Actualis cell
- One pallet or material-unit movement
- One quality-hold or invalid-location exception
- One authenticated Edge simulator
- Observation validation and promotion
- Operator denial and permitted quarantine response
- Affected-commitment identification
- Planner selection and independent approval where required
- Dispatch, expiry, acknowledgement, and evidence
- Operator and planner/supervisor surfaces
- One signed partner webhook
- Relay delivery through a deterministic test adapter
- Offline buffer, reconnect, replay, and duplicate handling

### Excluded from the proof

- Certified PLC, SIS, interlock, guard, or physical-energy-isolation behavior
- A complete MES, APS, inventory, quality, or maintenance product
- A general solver platform
- Runtime AI or autonomous decision-making
- A generic domain DSL or schema compiler
- Production-scale raw telemetry storage
- Multi-cell control-plane behavior
- Global active-active relational writes

The first replan may use deterministic alternatives or a bounded solver adapter. The proof
must preserve a typed decision contract, but it must not build a universal solver abstraction.

## Actors and principals

| Actor | Principal type | Authority in this journey |
| --- | --- | --- |
| Operator | Human | Request permitted material movement and acknowledge instructions within assignment, qualification, purpose, site, shift, and device scope |
| Production planner | Human | Inspect affected commitments, create or compare scenarios, and select a response |
| Quality approver | Human | Release a hold or approve an exception when policy requires independent authority |
| Edge gateway | Device/workload | Buffer signed observations, receive bounded commands, enforce expiry, and report acknowledgement |
| RFID or scanner device | Device | Supply source observations through the gateway; never self-promote an observation |
| Projection worker | Workload | Build purpose-scoped deltas without broadening authority |
| Relay worker | Workload | Deliver an authorized communication request and record outcome |
| Partner adapter | Integration | Receive a signed, versioned, at-least-once event |
| Support engineer | Support | No standing access; only a scoped, approved, expiring support grant |
| Solver or AI | Worker or AI | May propose through typed contracts when later introduced; cannot approve or execute |

## Authority and safety order

The enforcement order is:

1. physical energy isolation and safety-rated protection;
2. local controller, interlock, and device-enforced limits;
3. Edge operational enforcement;
4. Core capability authorization and obligations; and
5. human, integration, solver, or AI request.

A lower layer may inhibit an operation accepted by a higher layer. A Core allow decision means
only that the principal may attempt the declared operation through the next boundary. It does
not prove that a pallet moved or that the physical environment was safe.

Disconnected operation is denied by default. Any later offline allowance must declare scope,
duration, local invariant, expiry, reconciliation, and recovery behavior.

## Current executable evidence

| Behavior | Current status |
| --- | --- |
| Human and device identifiers enter through a governed HTTP route | Implemented with development-only identity headers |
| Human, device, assignment, grant, policy, purpose, and site checks | Partial |
| Principal-scoped idempotency and request hashing | Implemented |
| Expected pallet version and row locking | Implemented |
| Released pallet can move between active locations | Implemented |
| Held pallet movement is rejected | Implemented |
| Movement, receipt, evidence, outbox row, and deltas commit atomically | Implemented |
| Operator and supervisor projection shapes | Implemented as JSON data |
| Purpose-scoped evidence reconstruction | Partial |
| Production authentication and device proof | Not implemented |
| Observation ingest, validation, and promotion | Not implemented |
| Commitment impact, scenario, selection, and approval | Not implemented |
| Outbox publication, signed webhook, Relay, and acknowledgement | Not implemented |
| Realtime client sync, offline queue, and human-facing surfaces | Not implemented |
| Immutable promotion, restore, failover, and production-shaped load proof | Not implemented |

## Canonical journey

### 1. Observe

An authenticated gateway receives a device observation containing the device identity,
sequence, source time, ingest time, location claim, payload version, and available assurance
or calibration reference.

The observation is stored as evidence before it is treated as operational truth.

### 2. Validate and promote

The manufacturing domain validates device status, sequence, clock quality, schema, location
context, and business plausibility. It promotes a validated observation or records a rejected
or uncertain observation without inventing a value.

### 3. Detect the exception

A pallet is on quality hold, is not at the claimed source, or conflicts with an authoritative
version. The normal issue or movement capability rejects with a safe reason code.

The operator surface explains the permitted next action without disclosing policy internals.
For a quality hold, that action may be a separately governed quarantine movement.

### 4. Identify impact

The manufacturing package identifies work orders, material reservations, delivery
commitments, or other domain commitments affected by the exception and captures the
authoritative snapshot used for evaluation.

Core stores only stable commitment and snapshot references. It does not interpret work-order
or pallet fields.

### 5. Form alternatives

The planner creates or requests bounded alternatives. Each alternative records assumptions,
hard constraints, objectives, source snapshot, affected commitments, and explanation.

The first proof may use deterministic fixtures or a narrow solver adapter. It must still show
when no feasible alternative exists.

### 6. Select and approve

The planner selects an alternative. Policy determines whether quality, production, or another
principal must approve it. No principal may approve their own conflicting action.

Selection is not commitment. Approval records policy and contract versions, reason codes, and
evidence references.

### 7. Commit and dispatch

The approved response becomes a versioned commitment and creates an execution command with
expected state, issue time, expiry, risk class, enforcement boundary, and idempotency key.

The command is delivered at least once. Edge rejects expired, stale, payload-mismatched, or
context-mismatched commands and does not repeat an identical effect.

### 8. Acknowledge and communicate

Edge records accepted, rejected, executed, failed, or expired acknowledgement separately.
Relay records requested, provider-accepted, delivered, seen, and acknowledged communication
states where the operational commitment requires them.

### 9. Verify and reconstruct

A later observation may verify the outcome. Authorized audit reconstruction links the
observation, validation, policy decision, domain versions, selected alternative, approvals,
commitment, dispatch, acknowledgement, communications, and eventual outcome.

## Initial narrative catalogue

These are hypotheses to validate with operators, planners, quality staff, maintenance,
security, and support. They are not substitutes for field observation.

| ID | Narrative hypothesis | Evidence required |
| --- | --- | --- |
| M-01 | A trusted operator moves a released pallet between active locations | Normal command, version, evidence, delta, acknowledgement |
| M-02 | A held pallet cannot be issued to production | Denial reason, policy, quality state, no movement effect |
| M-03 | A held pallet may move only to an approved quarantine location | Separate capability or obligation, destination rule, evidence |
| M-04 | The pallet is no longer at the claimed source | Current location, stale claim, safe conflict response |
| M-05 | Two operators move the same pallet concurrently | One commit, one version conflict, no silent overwrite |
| M-06 | An operator reuses an idempotency key for different input | Reuse denial and original receipt |
| M-07 | A device repeats an identical observation after reconnect | One promoted fact, duplicate receipt, preserved raw evidence |
| M-08 | Observations arrive out of order | Sequence uncertainty is visible; no false ordering |
| M-09 | A device is unknown, revoked, or outside its site | Quarantine or rejection without authoritative promotion |
| M-10 | Device time is unreliable | Ingest time retained; confidence and validation record clock quality |
| M-11 | Connectivity fails during a shift | Bounded local buffer, visible status, quota, safe reconnect |
| M-12 | A queued command expires before reconnect | Edge rejects it; Core records expiry without execution |
| M-13 | The quality hold affects a committed work order | Affected commitment and source snapshot are reconstructable |
| M-14 | Two planners select responses from the same snapshot | Expected-version rule prevents conflicting commitment |
| M-15 | The planner selects a response requiring quality approval | Independent approval is enforced and recorded |
| M-16 | The planner attempts self-approval | Separation-of-duties denial with a safe explanation |
| M-17 | No feasible replan exists | Infeasibility is explicit; no invented executable plan |
| M-18 | Edge accepts a command but no execution acknowledgement arrives | Durable pending state, expiry, escalation, no silent success |
| M-19 | A Relay provider accepts but does not deliver | Delivery state remains unresolved and escalation is observable |
| M-20 | A partner receives a duplicate webhook | Signature and idempotency prevent duplicate downstream authority |
| M-21 | A worker restarts after publishing but before recording success | Redelivery occurs without duplicate authoritative effect |
| M-22 | Support needs urgent access | Scoped grant, approval, expiry, recording, and review |
| M-23 | A backup is restored into an isolated cell | Counts, hashes, versions, evidence, and outbox state reconcile |
| M-24 | Background delivery saturates its pool | Operator command SLO remains within the declared budget |

The operational owner must accept, reject, or revise each relevant narrative and add missing
normal work, workarounds, exception handling, privacy, and recovery cases.

## Evidence contract

The end-to-end trace must retain, where applicable:

- cell and site;
- principal and workload identities;
- relationship, purpose, assurance, context, and risk;
- capability, event, schema, policy, configuration, and package versions;
- observation source, sequence, source time, ingest time, confidence, and validation result;
- expected and committed domain versions;
- snapshot and affected-commitment references;
- candidate, selection, explanation, and approval references;
- command issue time, expiry, enforcement boundary, and idempotency key;
- domain effects and outbox/inbox state;
- dispatch and acknowledgement state;
- Relay and Link delivery attempts;
- object hashes, retention class, and integrity state; and
- eventual outcome or unresolved status.

Authenticated provenance does not prove physical truth. The evidence must preserve both the
origin claim and the domain validation that accepted, rejected, or qualified it.

## Initial measurements

These are engineering hypotheses until production-shaped tests and operational baselines
replace them.

| Measure | Initial target |
| --- | --- |
| Ordinary governed command | p95 below 250 ms; p99 below 750 ms, excluding external work |
| Authoritative delta availability | p95 below 1 second within the cell region |
| Duplicate authoritative effects | Zero under retries, reconnect, worker restart, and redrive |
| Consequential trace completeness | 100% of required versions, authority, effects, and evidence |
| Interactive workload isolation | Command target holds while delivery workers saturate their pool |
| Authoritative recovery | RPO at most 5 minutes and RTO at most 60 minutes until a customer tier replaces it |

The operational study must additionally measure:

- exception rate and dominant exception classes;
- time from observation to operator understanding;
- time from exception to planner decision;
- approval delay and rework;
- commitments affected per exception;
- offline duration and buffered observation volume;
- duplicate and out-of-order rates;
- current acknowledgement and communication gaps; and
- operational cost of an unresolved or incorrect response.

## Product-surface proof

The same governed capability must be consumed by two materially different experiences:

### Operator surface

- scan-first;
- immediate local receipt;
- explicit online, queued, committed, denied, and expired states;
- large, unambiguous actions;
- minimum purpose-scoped projection; and
- no planner-only evidence or policy detail.

### Planner or supervisor surface

- dense exception and commitment context;
- current authoritative version and conflict visibility;
- alternatives, trade-offs, approvals, and acknowledgement state;
- evidence navigation appropriate to the principal's purpose; and
- no ability to bypass the same capability boundary.

Generated administration screens do not satisfy this proof.

## Exit criteria

The journey passes its first gate when:

- a named operational owner accepts the normal and failure narratives;
- manufacturing ownership is outside Core and enforced by dependency tests;
- one simulated device disconnects, buffers, reconnects, and promotes one observation exactly
  once;
- a held or stale movement rejects without an authoritative movement effect;
- an operator sees the permitted next action and a planner sees affected commitments;
- selection and required independent approval cannot be skipped;
- dispatch expiry and acknowledgement are explicit;
- one signed webhook and one Relay delivery survive duplicate/retry tests;
- two distinct surfaces consume the same governed contracts;
- an authorized reader reconstructs the complete journey without cross-module SQL;
- one immutable artifact is promoted and restored with evidence integrity intact; and
- measured results either confirm or revise the initial latency, isolation, and recovery
  hypotheses.

## Immediate implementation backlog

1. Extract manufacturing ownership from Core and introduce a neutral conformance fixture.
2. Define versioned cell, principal, invocation, decision, obligation, effect, evidence, event,
   dispatch, and acknowledgement envelopes.
3. Add observation and command simulators with explicit sequence, clock-quality, expiry, and
   duplicate behavior.
4. Implement outbox publication, inbox deduplication, retries, dead letters, redrive, and a
   deterministic Relay adapter.
5. Implement realtime deltas and purpose-scoped local projection behavior.
6. Build the operator and planner/supervisor proof surfaces as independent packages.
7. Package one immutable release and run restore, reconnect, duplicate, and workload-isolation
   exercises.

## Validation record

Before this contract is marked validated, record:

- the named operational owner;
- observation dates and sites;
- interviewed or shadowed roles;
- accepted, rejected, and added narratives;
- measured baseline values;
- applicable safety and regulatory boundaries;
- launch identity, retention, residency, and communication decisions; and
- links to resulting contract, threat-model, and ADR changes.


---
title: Actualis Participation implementation proposal
doc_type: implementation_plan
audience: product_architecture_and_coding_agents
status: proposed_phase_0_in_progress
source_paths:
  - architecture/participation
  - architecture/adr/0008-versioned-domain-capability-integration.md
  - architecture/adr/0009-participation-domain-package-boundary.md
  - architecture/threat-models/participation.md
  - apps/actualis_core/lib/actualis/capability
  - apps/actualis_manufacturing
last_verified: 2026-07-19
---

# Actualis Participation

## Architecture, implementation proposal, and coding-agent delivery plan

| Field | Decision |
| --- | --- |
| Product package | **Actualis Participation** |
| OTP application | `:actualis_participation` |
| Elixir namespace | `Actualis.Participation` |
| First product area | **Activity Readiness** |
| Sector scope | Neutral across Scout, football, and similar participation organizations |
| Architecture | Elixir/Phoenix capability-centric modular monolith |
| Phase status | Phase 0 in progress; no Participation application exists |
| Reviewed baseline | Working tree based on `0f1463d94ff9703134810f9854f7ef03760e8657` |

This is the durable implementation brief for product owners, maintainers, and coding agents. It
defines scope, ownership, dependencies, invariants, phases, gates, and task protocol so later work
does not reinterpret the architecture one pull request at a time.

When this document and executable behavior disagree, source, migrations, contracts, and tests win.
Planned items remain unavailable until their phase gate is proven.

## 1. Executive decision

Build **Actualis Participation**, not a Scouting module and not a generic ERP.

Participation governs how people take part in programmes and activities. It covers groups,
memberships, schedules, registrations, responsible adults, requirements, consent, signatures,
readiness, attendance, and later purpose-limited welfare and communication behavior.

The same implementation must support:

| Neutral concept | Scout configuration | Football configuration |
| --- | --- | --- |
| Cell | Scout unit | Football club |
| Group | Section | Team |
| Programme | Scouting year | Football season |
| Participant | Scout | Player |
| Membership | Section membership | Team registration |
| Activity | Camp, weekend, outing | Camp, tournament, trip |
| Occurrence | Weekly meeting | Training session or match |
| Responsible adult | Guardian or leader | Parent, coach, or staff member |
| Readiness | Camp forms and authorization | Registration, medical, or camp forms |

Camp is an activity profile. It is not a Core concept, package, or hierarchy level. Year-long
training/meetings and a summer camp share one programme and participation model.

## 2. Product outcomes

The initial product must let an organization:

1. operate as an isolated Actualis cell;
2. organize participants into effective-dated groups and programmes;
3. schedule explicit and bounded recurring activity occurrences;
4. import authoritative roster data with provenance and reconciliation;
5. link adult accounts to participants through cell-scoped, time-bounded rights;
6. invite and register participants for an activity;
7. collect versioned declarations, documents, authorization, consent, and attestations;
8. derive readiness from explicit inputs rather than an editable status;
9. expose purpose-shaped participation and welfare views; and
10. reconstruct decisions, signatures, verification, messages, and exceptions from retained
    versions and evidence.

## 3. Scope boundary

### 3.1 Participation owns

- Cell-local organization profile and terminology.
- Groups, participants, memberships, responsible parties, and import provenance.
- Programmes, activities, occurrences, invitations, and registrations.
- Requirement definitions and sets, assignments, submissions, evidence references, and
  attestations.
- Explicit signature policies, readiness assessment, verification, expiry, and governed
  exceptions.
- Purpose-shaped Participation and welfare projections.
- Later attendance, arrival/departure, headcount, announcements, emergency broadcasts, and
  controlled replies.

### 3.2 Separate packages or later decisions own

- Payments, refunds, accounting, purchasing, budgets, and payroll.
- Inventory, equipment, tents, facilities, transport, and fleet.
- Generic CRM, HR, project management, and arbitrary administration.
- Formal safeguarding case management.
- A low-code entity, form, report, or workflow builder.

Safeguarding remains separate because access, disclosure, retention, and escalation are materially
more restrictive than ordinary activity incidents.

### 3.3 Core remains neutral

Core owns cell/principal context, governed invocation, authority, idempotency, obligations,
transaction coordination, evidence metadata, and durable delivery envelopes. It does not own
participants, teams, sections, programmes, activities, camps, health forms, or guardians.

## 4. Non-negotiable anti-ERP rules

Every phase and change is reviewed against these constraints.

1. **No universal entity model.** Do not add `entities`, `business_objects`, `doctypes`, generic
   party/resource/document tables, EAV, or unrestricted custom fields.
2. **No metadata-defined application.** Administrators may select supported templates and policies;
   they cannot create executable schemas, arbitrary state machines, policy code, or persistence
   hooks.
3. **No shared mega-schema.** Each OTP application owns schemas, migrations, invariants, and public
   contexts. Shared PostgreSQL provides atomicity, not shared ownership.
4. **No CRUD bypass.** Consequential work uses named operations such as `confirm_registration` and
   `verify_readiness`. Web, LiveView, jobs, imports, and support tools cannot write through internal
   changesets or `Repo` directly.
5. **No global-role authorization.** “Admin”, “leader”, “coach”, or “guardian” alone never permits
   access. Evaluate cell, target, relationship, assignment, purpose, fields, risk, effective time,
   and policy version.
6. **No polymorphic everything table.** Shared lifecycle fields may live in a focused base schema;
   materially different invariants use explicit typed extensions.
7. **No hook/monkey-patch extension system.** Use public contexts, small behaviours, static
   configuration, and versioned facts.
8. **No internal event-bus maze.** Use direct typed calls and one visible transaction. Events are
   committed facts for durable consumers, not hidden application control flow.
9. **No distribution without evidence.** Begin as a modular monolith. A service, broker, workflow
   engine, or extra database requires measured resource, security, availability, placement, or
   release-cadence evidence.

## 5. Current implementation baseline

The repository already moved beyond the earlier manufacturing-coupled proof:

- The umbrella contains `actualis_core`, `actualis_manufacturing`, and `actualis_web`.
- `Actualis.Capability.Handler` separates product validation/execution from Core.
- `Actualis.Capability.Registry` resolves configured product handlers.
- `Actualis.CapabilityRuntime` owns the transaction around receipt, authority, handler, evidence,
  and durable event intent.
- `actualis_manufacturing` owns product schemas, invariants, projections, migrations, and tests.
- A neutral Core fixture verifies allow/deny, replay, rollback, evidence, and source-boundary basics.
- Authority is moving to a generic authorization scope rather than manufacturing `site_id`.

The seam is still partial:

- no capability contract version or handler descriptor;
- no startup-built duplicate-free registry;
- no explicit Core cell object/routing contract;
- wall time and UUIDs are generated directly;
- no domain relationship-fact resolver;
- obligations are not a pending/finalization lifecycle;
- result/fact compatibility and size/content limits are incomplete; and
- the conformance matrix lacks versions, obligations, concurrency, malformed results, full cell
  isolation, and delivery replay.

Participation tables must not be added to compensate for these gaps.

## 6. Repository and release topology

The fixed boundary is a separate OTP application and migration path. The permanent Git topology is
a Phase 0 decision and must comply with ADR 0003.

Target dependency direction:

```text
Participation Phoenix/PWA adapter
              |
              v
      Actualis public contracts
              |
              v
       actualis_core <--- actualis_participation
```

Rules:

- `actualis_core` has no compile-time dependency on Participation.
- Participation depends only on public Core contracts.
- Web delivery depends on public Core/product contexts, never private schemas.
- The release lists handlers and migration paths explicitly and pins package artifacts.
- Runtime package installation, downloaded migrations, and arbitrary hooks are prohibited.
- Each authoritative request routes to and reauthorizes inside exactly one cell.

One adult identity may resolve to separate principal contexts and rights in multiple cells. Cells do
not share operational participant, membership, or family tables. A future multi-cell inbox merges
only authorized summaries and tolerates partial availability.

## 7. Core integration contract

[ADR 0008](../../architecture/adr/0008-versioned-domain-capability-integration.md) is authoritative
after acceptance. The required semantics are summarized here.

### 7.1 Invocation

A consequential invocation includes:

```elixir
%Actualis.Capability.Invocation{
  cell_id: cell_id,
  principal_id: principal_id,
  device_id: device_id,
  capability: "participation.registration.confirm",
  contract_version: 1,
  purpose: "activity_participation",
  input: %{...},
  expected_versions: %{"registration" => 3},
  idempotency_key: "client-generated-stable-key",
  evidence_references: [],
  client_context: %{},
  correlation_id: correlation_id
}
```

Capability name, contract version, and handler version are distinct. Published contract versions are
immutable.

### 7.2 Handler lifecycle

1. `descriptor/0` declares capability/version, handler version, risk, and required fact/obligation
   types.
2. A pure prepare/validate step canonicalizes product input.
3. Core hashes canonical input, claims idempotency, resolves facts, and evaluates authority.
4. The handler executes inside the Core transaction using explicit clock/identifier/configuration
   inputs.
5. Core validates the stable result envelope, stores evidence metadata and outbox facts, and commits
   once.

No network, email, SMS, object upload, AI, solver, or provider call occurs inside the transaction.

### 7.3 Relationships and obligations

Participation resolves an exact fact such as:

```text
principal P is responsible_party for participant S
in cell C with rights [confirm_participation, attest_health_declaration]
valid from T1 until T2, sourced by version R
```

Core evaluates and records the fact reference without interpreting family law or querying the
Participation table.

A second signature or approval becomes persisted pending state. Finalization is a new invocation
against current policy, relationships, requirement/document versions, and expected domain versions.
No transaction stays open while a human acts.

## 8. Participation contexts and domain model

Suggested schema names may be refined during design, but agents cannot collapse contexts or replace
them with generic metadata.

### 8.1 `Actualis.Participation.Directory`

Owns:

| Schema | Purpose |
| --- | --- |
| `OrganizationProfile` | Cell-local product identity, terminology, locale, policy profile |
| `Group` | Team, section, or equivalent with stable code and active period |
| `Participant` | Non-login represented person and source identity |
| `Membership` | Effective participant-to-group relationship |
| `ResponsibleParty` | Principal-to-participant rights, validity, source, verification |
| `ImportBatch` | Source, object reference/hash, schema version, actor, outcome |
| `ImportRecord` | Source record, normalized hash, action/result, errors |

Invariants:

- Every row and lookup is cell-scoped.
- Cross-cell foreign-key combinations are impossible.
- A participant never becomes a principal implicitly.
- Rights deny by default and are effective-dated.
- Imports are idempotent by source identity and version/hash.
- Upstream-authoritative fields change only through import/reconciliation operations.
- Ambiguous people are never merged by name alone.

### 8.2 `Actualis.Participation.Programmes`

A programme is a bounded year or season, not a project, ledger period, folder, or cost centre.

```text
draft -> active -> closed -> archived
   `-------> cancelled
```

Store cell, stable code/name, start/end dates, timezone, status/version, and policy/configuration
version.

### 8.3 `Actualis.Participation.Activities`

Owns activities, occurrences, invitations, and registrations.

```text
activity:     draft -> published -> closed
                `---------> cancelled

registration: invited -> accepted -> withdrawn
                  |-----> declined
                  `-----> expired
```

Rules:

- Activity, programme, participant, invitation, registration, and occurrence share one cell.
- Activity category is descriptive and cannot select arbitrary code.
- Recurring meetings/training materialize a bounded series of occurrences.
- Generation is deterministic and idempotent; use explicit occurrences plus a narrow weekly-series
  operation before considering a general scheduler.
- Reschedule/cancellation produces facts and explicit readiness consequences.

### 8.4 `Actualis.Participation.Readiness`

Owns:

| Schema | Purpose |
| --- | --- |
| `RequirementDefinition` | Immutable supported requirement type/version |
| `RequirementSet` | Versioned collection applied to an activity |
| `RequirementAssignment` | Requirement applied to a registration/participant |
| `Submission` | Versioned response or object-evidence reference |
| `Attestation` | Assertion by an authenticated principal or uploaded signature |
| `ReadinessAssessment` | Derived outcome with exact input versions/reasons |
| `ReadinessVerification` | Staff verification or governed exception |

Initial explicit requirement types:

- participation confirmation;
- account attestation;
- uploaded signed document;
- parental authorization;
- photo/video consent;
- health declaration;
- prescription attachment; and
- named staff verification.

Initial explicit signature policies:

- any one authorized responsible adult;
- all currently authorized legal guardians;
- specifically named responsible adults;
- responsible adult plus activity-leader verification; and
- adult participant self-attestation.

Readiness is derived from the immutable requirement set, assignments, latest valid submissions,
attestation policy, expiry, and approved exceptions. There is no writable `ready` switch.

```text
not_ready | ready | verified | exception_approved | expired
```

Every assessment records exact input versions and explanation codes.

### 8.5 `Actualis.Participation.Welfare`

Added only after the readiness and privacy gates. It owns health declarations, prescriptions,
emergency instructions, medication/care records, and purpose-shaped welfare projections.

| Information | Default proposed audience |
| --- | --- |
| General readiness | Relevant group/activity staff |
| Allergies, medication, emergency actions | Named activity staff |
| Complete declaration | Activity leader and named deputy |
| Care history | Designated care leads |
| Break-glass view | Explicitly authorized adult with reason, expiry, alert, review |

Health content never appears in general events, logs, telemetry labels, notification text, or broad
projections. Access expires after the activity according to an approved policy.

### 8.6 `Actualis.Participation.Communications`

Deferred until readiness works. Initial patterns are announcement, emergency broadcast, optional
controlled private reply, and a protected update/photo feed subject to consent. It is not a social
group-chat product.

## 9. Initial capability and fact catalogue

Recommended capabilities:

```text
participation.directory.import_roster
participation.directory.assign_responsible_party
participation.programme.create
participation.programme.activate
participation.activity.create
participation.activity.publish
participation.activity.generate_occurrences
participation.registration.invite
participation.registration.confirm
participation.registration.decline
participation.registration.withdraw
participation.requirement.assign
participation.requirement.submit
participation.requirement.attest
participation.readiness.assess
participation.readiness.verify
participation.readiness.approve_exception
```

The first real handler should be
`Actualis.Participation.Capabilities.ConfirmRegistrationV1`. It proves cell isolation,
relationship authorization, idempotency, expected versions, domain invariants, evidence, and outbox
behavior without starting with health data.

Initial minimum-data facts:

```text
participation.roster_imported.v1
participation.membership_changed.v1
participation.responsible_party_assigned.v1
participation.programme_activated.v1
participation.activity_published.v1
participation.occurrences_generated.v1
participation.registration_confirmed.v1
participation.registration_declined.v1
participation.requirement_submitted.v1
participation.requirement_attested.v1
participation.readiness_changed.v1
participation.readiness_verified.v1
```

Sensitive form and welfare payloads are authorized object references, not outbox copies.

## 10. Phoenix delivery design

Phoenix controllers and LiveViews are adapters. They resolve trusted identity and cell, parse
transport input, call a public governed command or authorized read, and translate safe results. They
contain no domain validation, authority decision, readiness calculation, or `Repo` call.

Planned journeys:

- Adult action inbox: selected cell, linked participants, outstanding actions, activities.
- Staff readiness dashboard: groups, registrations, missing requirements, verification.
- Activity setup: dates, groups, invite audience, requirement-set version, named staff.
- Registration: confirm/decline and complete assigned requirements.
- Verification: filter by reason, inspect permitted evidence, request correction, verify/except.
- Later live activity: check-in/out and current headcount.

Planned purpose-shaped reads include `adult_action_inbox`, `activity_readiness_summary`,
`leader_registration_detail`, `care_lead_health_summary`, and `live_headcount`. Reads reauthorize
current purpose and fields.

After commit, PubSub may carry a small invalidation tuple. LiveViews refetch through an authorized
read API. Never broadcast welfare data or full records through PubSub.

## 11. Import, evidence, privacy, and operations

### 11.1 Roster import

1. Upload to the evidence object port.
2. Record source, hash, schema version, uploader, and purpose.
3. Parse into non-authoritative staging data.
4. Validate all rows without partial authoritative mutation.
5. produce a reconciliation plan.
6. Apply an accepted plan through an idempotent governed capability.
7. Store per-row outcomes and domain references.
8. Emit a summary fact without personal data.

Final field mappings wait for approved redacted samples.

### 11.2 Object evidence

- Upload before the transaction.
- Record hash, media type, size, object key, retention class, scan and integrity state.
- Use short-lived authorized download or streaming.
- Quarantined, invalid, or hash-mismatched objects cannot satisfy a requirement.
- Provider/network work never occurs while the authoritative transaction is open.

### 11.3 Privacy/security

- Store only fields needed by implemented purposes.
- Use fictional data in code, tests, docs, and screenshots.
- Keep personal/welfare data out of logs, metrics, traces, URLs, facts, and safe errors.
- Authorize welfare reads by cell, target, relationship/assignment, purpose, fields, and time.
- Record access without copying protected content into the audit record.
- Treat break-glass as a restrictive capability, not a bypass flag.
- Complete legal/privacy role analysis and a DPIA where required before real pilot data.

### 11.4 Operational proof

Before pilot, rehearse database backup/restore, evidence hash reconciliation, failed migration
roll-forward, worker restart, duplicate delivery, expired authorization, cell-isolation regression,
and production-shaped dashboard load.

Telemetry contains safe capability/outcome dimensions, correlation IDs, outbox lag, replay/conflict
counts, denied/break-glass access, and aggregate readiness counts—never personal fields or free text.

## 12. Delivery phases

Each phase has an exit gate. A coding agent cannot start a later phase to bypass a failing earlier
contract.

### Phase 0 — Ratify boundaries and obtain real inputs

Status: **In progress**.

Deliverables:

- Accept/amend this proposal.
- Accept/amend ADR 0008 and ADR 0009.
- Verify the Core/Participation context map and threat model.
- Decide package topology, authentication age, responsible-party rights, signature/exception rules,
  roster authority, pilot cells, PWA, communications, welfare retention, and legal ownership.
- Obtain redacted roster, health, authorization, consent, and signed-document examples.

Exit: every first-slice table/capability/fact has one owner; no open decision can change the first
Core contract; missing mappings remain explicitly blocked rather than invented.

### Phase 1 — Complete the Core domain-package contract

Status: **Partial implementation already exists**.

#### C1: Cell identity and isolation

- Add an explicit Core cell contract and forward-only migrations where required.
- Distinguish cell identity from product scope vocabulary.
- Add cross-cell authority, receipt, evidence, and replay tests.

Acceptance: Core resolves and records a cell without a product table; all cross-cell cases deny.

#### C2: Versioned descriptors and startup registry

- Add invocation, descriptor, result, error, rejection, and fact contracts.
- Extend the handler with immutable contract version and handler version metadata.
- Build/validate a read-only registry at startup and reject duplicate keys.

Acceptance: two versions coexist; unknown/downgraded versions fail safely; duplicates stop startup.

#### C3: Deterministic transactional runtime

- Inject clock/identifier ports and record selected versions/results.
- Validate bounded handler results and safe errors.
- Keep receipt, authority outcome, domain effect, evidence, and outbox in one transaction.

Acceptance: fixed inputs replay deterministically; rollback leaves no partial Core/product effect.

#### C4: Relationships and obligations

- Add the narrow exact-target relationship-fact contract.
- Add pending obligation and reauthorized finalization semantics.
- Cover expiry, revocation, changed policy/state, and separation of duties.

Acceptance: a stale relationship/signature cannot finalize and no long transaction is retained.

#### C5: Conformance and migration completion

- Expand the neutral fixture for versions, obligations, concurrency, malformed results, cell
  isolation, restart, and delivery replay.
- Finish remaining generic-scope migration debt without rewriting history.
- Preserve Core-to-product dependency tests and documentation traceability.

Phase 1 exit: an external neutral handler uses declared ports only; Core has no product semantics;
all Core quality, migration, replay, cell, transaction, and boundary gates pass.

### Phase 2 — Scaffold Actualis Participation

Goal: create the approved package, migration path, Directory context, and Core integration tests.

#### P1: Package scaffold

- Create Mix/OTP app, supervision only where needed, pinned Core contract dependency, formatter,
  ExDoc, Credo, Dialyzer, quality alias, package manifest, handlers, and migration runner.
- Add architecture tests rejecting web/foreign-schema `Repo` access.

#### P2: Directory and provenance

- Implement profile, groups, participants, memberships, responsible parties, import batches/records.
- Enforce cell-aware keys, effective time, source authority, and synthetic reconciliation.

#### P3: Relationship resolver

- Return only declared exact-target facts with source/version references.
- Cover cross-cell, expired, revoked, and wrong-purpose cases.

Exit: one adult can hold independent rights in two cells; imported participants remain non-login;
imports replay safely; Core knows no Participation schema.

### Phase 3 — Programmes and year-round activities

#### P4: Programmes

- Implement lifecycle, dates, timezone, versioning, and invalid-transition tests.

#### P5: Activities and occurrences

- Implement activities, explicit occurrences, and bounded idempotent weekly generation.
- Emit reschedule/cancellation facts.

#### P6: Invitations and registrations

- Implement invitation/registration lifecycle.
- Deliver `ConfirmRegistrationV1` with responsible-party and adult-self policies.
- Build authorized adult/staff read models.

Exit: a football season with training and a camp and a Scout year with meetings and a camp use the
same schemas/contracts; no activity category branch appears in Core.

### Phase 4 — Activity Readiness

#### P7: Requirement versions

- Add immutable definitions/sets, activity attachment, deterministic assignment, explicit
  supersession/reassessment.

#### P8: Submission and object evidence

- Add structured responses and accepted object references with integrity/scan validation.
- Preserve versions and keep protected payloads out of Core metadata.

#### P9: Attestations and signature policies

- Implement account attestation, uploaded signed documents, and approved bounded policies.
- Use pending obligations and record signer relationship/document/policy/content versions.

#### P10: Assessment and verification

- Derive deterministic outcomes/reasons, staff verification, governed exceptions, and projections.
- Recalculate/expire on relevant version changes.

Exit: any activity can collect and verify explicit requirements; readiness is never directly
editable; every outcome is reconstructable.

### Phase 5 — Welfare and privacy hardening

- Derive exact health schema from approved forms.
- Add prescription/medical evidence references and named activity/care staff.
- Implement purpose-shaped summary/detail reads, post-activity expiry, audited break-glass, retention,
  deletion/anonymization, legal hold, access review, and privacy tests.

Exit: ordinary staff see readiness without health; named staff see only allowed fields while active;
expired/cross-cell access fails closed; protected content never leaks to general channels.

### Phase 6 — Phoenix product experience and PWA

- Adult action inbox and registration journey.
- Staff readiness dashboard, correction, verification, and exceptions.
- Accessible forms, upload, attestation, errors, and recovery.
- Cell switcher with per-cell requests and no unauthorized combination.
- Installable online-first PWA if approved; no offline welfare cache.
- Technical/user docs and real implementation screenshots where useful.

Exit: representative adults and staff complete their tasks without technical knowledge; accessibility,
safe errors, and cell isolation pass.

### Phase 7 — Live activity and communications

- Check-in/out, attendance, headcount.
- Emergency broadcast with delivery evidence.
- Named-staff welfare summary and optional approved care log.
- Announcements, controlled replies, protected update/photo feed with consent enforcement.
- Offline emergency access only behind its own accepted threat model.

Exit: concurrency/retry cannot corrupt headcount; delivery replay does not duplicate authoritative
intent; consent revocation stops future access; offline grants expire and reconcile safely.

### Phase 8 — Pilot readiness and operational proof

- Approve pilot scope and synthetic-to-real transition.
- Complete privacy/DPIA and legal-role analysis.
- Close critical security findings.
- Rehearse migrations, backup/restore, evidence reconciliation, and rollback/stop plan.
- Produce load/isolation evidence, support/incident/access-review/data-subject procedures, and staff
  training.

Exit: Product, Security, Privacy, Data/Legal, and Operations approve; every high risk has an owner,
mitigation, and expiry; pilot access can be revoked without improvisation.

## 13. Release plan

### Release 1 — Activity Readiness

Phases 1–6: completed Core package seam, directory/provenance, programmes/activities, registrations,
requirements/signatures/readiness, approved welfare handling, and adult/staff web journeys.

### Release 2 — Live Activity

Phase 7: headcount, emergency communication, live purpose-limited care access, announcements,
controlled family updates, and separately approved offline behavior.

### Later packages

Payments, transport, inventory/equipment, purchasing/budgets, duty planning, risk assessment, and
safeguarding remain independent roadmaps.

## 14. Testing strategy

### Core conformance

- descriptor validation and duplicate registration;
- allow, deny, obligations, expiry, revocation, separation of duties;
- replay, key conflict, stale version, concurrency, and cross-cell denial;
- malformed/oversized result and event contracts;
- full transaction rollback;
- deterministic clock/identifiers and external-result replay;
- restart-safe receipts, outbox delivery, dead-letter, and redrive;
- dependency tests proving Core has no product knowledge.

### Participation

- database constraints and lifecycle transitions;
- cell, target, purpose, field, and effective-time negative tests;
- idempotency, optimistic concurrency, deterministic occurrence generation;
- import replay and ambiguous reconciliation;
- responsible-party expiry and concurrent signatures;
- requirement-set/document/consent version changes;
- readiness properties and exact explanation codes;
- welfare minimization and post-activity revocation;
- facts, logs, telemetry, and errors contain no protected payload.

### Web/product

- safe HTTP/LiveView result mapping;
- no web `Repo` dependency;
- adult/staff journeys and recovery;
- keyboard, label, focus, error, and screen-reader accessibility;
- screenshots only after a deterministic working UI exists.

Every repository exposes a non-mutating quality gate including formatting, warnings-as-errors,
tests, static analysis, docs, migration checks, boundary checks, and security/dependency checks as
the tools are adopted. An agent cannot weaken gates to finish a phase.

## 15. Coding-agent execution protocol

### Before editing

1. Read applicable `AGENTS.md`, ADRs, documentation workflow/map, conventions, contracts,
   migrations, implementation, and tests.
2. Record repository, commit, and working-tree state; preserve unrelated user changes.
3. Name the exact phase/work package, prerequisites, public contracts, and out-of-scope work.
4. Stop when a missing product/legal decision would create a permanent incompatible choice.

### Implementation loop

1. Add behavior-level positive and negative tests.
2. Add forward-only migrations when persistent state changes.
3. Implement the smallest public contract behind the correct context/capability boundary.
4. Run focused checks, then the full quality gate.
5. Review cell scope, authority, minimization, transactionality, concurrency, migration safety, and
   dependency direction.
6. Update contracts, technical docs, user docs or `user_impact: none`, and the documentation map.
7. Report exact commands/results and remaining approved limitations.

### Prohibited shortcuts

An agent must not:

- add Participation tables to `actualis_core`;
- create generic entity/custom-field/workflow infrastructure;
- use broad JSON to avoid modelling an invariant;
- call `Repo` from controllers, LiveViews, or foreign contexts;
- authorize by UUID or role alone, or omit cell predicates;
- perform external effects inside the authoritative transaction;
- edit published migrations or silently reset data;
- weaken quality gates or broad-suppress warnings;
- expose protected-resource existence or personal data in errors/facts/logs/fixtures;
- describe planned behavior as implemented.

### Task card

```text
Work package:
Outcome:
Repository and starting commit:
In scope:
Out of scope:
Preconditions:
Public contracts affected:
Schemas/migrations affected:
Authorization and cell-isolation cases:
Concurrency/idempotency cases:
Sensitive-data considerations:
Tests required:
Documentation required:
Quality commands:
Acceptance criteria:
Roll-forward/recovery plan:
```

### Handoff

Report outcome first, changed contracts/files, migration implications, tested behavior and negative
cases, exact quality results, security/privacy/cell impact, documentation, and remaining risks or
decisions. “Tests pass” without commands and scenario coverage is insufficient.

## 16. Phase-wide definition of done

A phase is complete only when:

1. its outcome and exit gate are demonstrated by executable or operational evidence;
2. Core/product/schema ownership remains valid;
3. default-deny and cross-cell cases are covered;
4. idempotency, versions, concurrency, and replay are explicit;
5. required domain effects, receipts, evidence, and outbox facts are atomic;
6. migrations work from empty and the previous supported state;
7. protected data does not leak through logs, events, errors, projections, or fixtures;
8. quality gates pass without new broad suppressions;
9. documentation labels current/partial/planned behavior accurately;
10. rollout, roll-forward, monitoring, and recovery are credible; and
11. no unexplained warning, skipped test, hidden TODO, or boundary violation remains.

## 17. Open decisions and inputs

The live register is the
[Participation Phase 0 gate](../../architecture/participation/phase-0/README.md). Coding agents must
consult it before Directory, signature, import, welfare, communications, PWA, multi-cell, or pilot
work.

The unresolved items include authentication age, exact responsible-party rights, signature and
exception rules, roster authority/mapping, pilot cells, PWA scope, communication model, health form
fields, retention and post-activity access, controller/processor responsibilities, and offline
emergency behavior.

## 18. Success criteria

The programme succeeds when:

- football and Scout configurations use the same package without either vocabulary entering Core;
- year-long programmes and recurring activities coexist with summer camps;
- a product package can be removed without changing Core schemas;
- new activity categories do not require Core changes;
- every consequential mutation passes through a named governed capability;
- adults act across cells only through independent rights;
- participants remain distinct from principals;
- readiness is derived, versioned, and reconstructable;
- welfare/consent access is purpose-, field-, cell-, relationship-, and time-limited; and
- the system contains no universal entity store, arbitrary workflow compiler, shared mega-schema,
  global-role authorization, or hook-driven extension framework.


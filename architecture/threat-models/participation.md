# Participation threat model

Status: Phase 0 proposed controls; product not implemented  
Reviewed: 2026-07-19  
Owners: Actualis Security, Privacy, Product, and Engineering

## Scope

This model covers the proposed Participation package, including roster import, participants and
responsible adults, programmes and activities, registrations, requirements, signatures, readiness,
later welfare data, communications, and multi-cell adult access.

It complements the repository-wide
[Phase 0 boundary model](phase-0-boundaries.md) and the proposed Core seam in
[ADR 0011](../adr/0011-versioned-domain-capability-integration.md). It does not approve real personal
data, decide legal controller/processor roles, or authorize offline health access.

## Protected assets

- Cell isolation and organization operational data.
- Participant identity, membership, group, and attendance data.
- Adult account links, responsible-party rights, and staff assignments.
- Invitations, registration decisions, requirements, submissions, signatures, and exceptions.
- Health declarations, prescriptions, emergency actions, care records, and access history.
- Photo/video consent and protected activity media audiences.
- Source files, object evidence, hashes, provenance, retention, and deletion state.
- Capability, policy, relationship, requirement-set, and assessment versions.
- Evidence, outbox facts, delivery attempts, and audit reconstruction.

## Trust boundaries

1. Adult/staff browser or PWA to the Phoenix adapter.
2. Identity provider to cell-specific principal resolution.
3. Multi-cell discovery/switching to one authoritative cell.
4. Core authority to Participation relationship facts.
5. Core transaction coordinator to Participation-owned tables.
6. Roster/form upload to staging, scanning, reconciliation, and authoritative apply.
7. PostgreSQL metadata to protected object storage.
8. Committed communication intent to email, SMS, push, or media delivery providers.
9. Active activity access to post-activity expiry, retention, and deletion.
10. Online authority to any future bounded offline emergency store.

## Threats and required controls

| Threat | Required control | Validation |
| --- | --- | --- |
| Adult account sees another cell through shared identity | Resolve independent principal/rights per cell; route and reauthorize every request; never cross-cell join by external subject | Two-cell negative matrix and partial-failure tests |
| UUID reveals a participant or protected record | Require cell, purpose, relationship/assignment, target, fields, and time; use safe not-found responses | Enumeration and existence-probing tests |
| Imported participant receives login rights | Keep participant and principal lifecycles separate; account linking is an explicit governed operation | Import and schema boundary tests |
| Guardian/coach role is applied too broadly | Resolve exact participant/activity rights, source, validity, purpose, and requested operation | Wrong-target, expired, revoked, and delegated-right tests |
| One guardian signs where all/named guardians are required | Versioned signature policies and signer-set evaluation; readiness remains pending | Policy combination and concurrent signature tests |
| Staff silently marks a person ready | Readiness is derived; exceptions use a separate authorized capability, reason, expiry, and evidence | Direct-write boundary and exception tests |
| Requirement changes reinterpret an old signature | Immutable requirement/document/policy versions; explicit supersession and reassessment | Version-change and replay tests |
| Roster replay duplicates or overwrites people | Idempotency by source and external record/version/hash; reviewed reconciliation; no name-only merge | Replay, ambiguity, and rollback tests |
| Malicious upload satisfies a requirement | Size/type limits, hashing, malware scan/quarantine, accepted-integrity state, short-lived download authorization | Malformed, quarantined, hash-mismatch, and access tests |
| Health content leaks into general readiness | Separate welfare storage/projections; readiness exposes minimum status/reasons without medical payload | Field-minimization and serialized-payload tests |
| Health access remains after activity | Named assignment and purpose with effective period; automatic revocation and access review | Boundary-time, cancellation, and post-activity tests |
| Break-glass becomes an admin bypass | Dedicated high-risk capability, required reason, short expiry, audit alert, review, no bulk access | Denial, alert, expiry, and abuse tests |
| Photo is delivered after consent revocation | Check applicable consent at audience projection/delivery time; stop future delivery and refresh access | Revocation and delayed-delivery tests |
| Sensitive data appears in events/logs/errors | Minimum fact payloads, references to protected objects, safe reason codes, telemetry allowlists | Static scans and disclosure tests |
| Controller/LiveView/import bypasses governance | Public contexts and governed operations only; architecture checks reject adapter `Repo` writes | Dependency and source-boundary tests |
| Concurrent registration/check-in loses an update | Expected versions, deterministic lock order, unique constraints, idempotency | Race and retry tests |
| External delivery occurs inside transaction | Persist delivery intent atomically; provider work after commit; idempotent consumers | Fault injection and worker-restart tests |
| Offline welfare cache outlives authority | Defer by default; require separate model, encrypted bounded data, signed expiry, revocation/reconciliation | Separate approval and offline attack tests |
| Support or AI tool obtains broad access | Separate principal type, explicit purpose, least fields, time-bound grant, evidence, no hidden backdoor | Grant, expiry, prompt/tool disclosure, and audit tests |

## Security and privacy invariants

- Unknown cells, relationships, fields, purposes, requirement variants, and signature policies deny
  by default.
- A participant is not a principal and never authenticates merely because a roster contains them.
- Every authoritative record and lookup is cell-scoped; an identifier alone grants nothing.
- A relationship fact is valid only for its exact cell, principal, target, purpose, source/version,
  and effective time.
- A pending signature or obligation is not a completed requirement or committed final effect.
- Readiness cannot be edited directly and remains reconstructable from exact input versions.
- Welfare content is absent from general events, logs, metrics, URLs, errors, and broad projections.
- Evidence retention does not imply continued product access to its protected content.
- Break-glass is more restrictive and observable than ordinary access, never a Boolean bypass.
- Cross-store or provider failure cannot partially commit authoritative state.
- Historical replay never resends a communication or repeats another external side effect.

## Abuse cases

### Guardian with children in two organizations

The same external account selects cell A and supplies a participant ID from cell B. Resolution and
query predicates must remain inside cell A and return a safe denial. The system must not use the
external identity to join participant relationships across cells.

### Leader exports all health forms

A section/team role is presented as authority for a bulk export. The request denies unless a named,
active activity assignment, permitted purpose, allowed field set, and explicit export capability all
exist. Ordinary readiness visibility does not imply access to complete declarations.

### Late second signature

The second signature arrives after the requirement set, responsible-party relationship, or activity
state changed. Finalization reauthorizes and reassesses current versions; it does not continue the
original transaction or apply the signature to a different document version.

### Revoked photo consent with queued delivery

Consent is revoked after a media update is queued. The delivery projection checks current applicable
consent before granting future access. Audit history retains the fact of prior authorized delivery
without retaining broad access to the media.

## Phase gates

Before ordinary roster data:

- approve cell isolation, account/participant separation, relationship facts, source authority,
  reconciliation, retention, and data-subject procedures.

Before signatures or object evidence:

- approve immutable document/version semantics, signer policies, exception authority, object
  scanning, integrity, download, retention, and deletion controls.

Before welfare data:

- complete a focused privacy/security review and DPIA where required; approve fields, purpose,
  assignments, post-activity access, break-glass, incident response, and retention/deletion.

Before real pilot data:

- name product, security, privacy, legal/data, and operational owners; close critical findings;
  rehearse backup/restore and evidence reconciliation; and approve the controller/processor model
  based on actual purposes and means.

Before offline emergency access:

- create and approve a separate threat model covering device trust, encrypted storage, scope,
  expiry, revocation, loss, wipe, sync, evidence, and incident handling.

## Residual risk and review triggers

Children's data, family relationships, health information, multi-cell adult access, and third-party
delivery remain high-impact even with technical controls. Legal review, operating discipline, access
review, training, and incident response are part of the control system.

Review this model when authentication age, relationship rights, signature policies, health fields,
retention, break-glass, package trust, multi-cell routing, communication, media, AI/support access, or
offline behavior changes.

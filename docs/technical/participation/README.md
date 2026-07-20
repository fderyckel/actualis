---
title: Actualis Participation foundation
doc_type: technical
audience: agents_and_maintainers
kernel_area: participation_domain_package
status: planned
source_paths:
  - architecture/participation
  - architecture/adr/0008-versioned-domain-capability-integration.md
  - architecture/adr/0009-participation-domain-package-boundary.md
  - architecture/threat-models/participation.md
test_paths:
  - none
paired_user_docs:
  - none
last_verified: 2026-07-19
---

# Actualis Participation foundation

## Current status

Actualis Participation is **planned, not implemented**. The repository contains no Participation
application, schema, migration, handler, contract, route, projection, or UI.

Phase 0 has prepared proposed architecture and delivery documentation. The decisions are not
accepted merely because files exist. Manufacturing remains the accepted lead programme journey; the
Participation plan does not replace it.

## Product boundary

The proposed package is `actualis_participation`, namespace `Actualis.Participation`, with Activity
Readiness as its first product area. It supports a Scout year and football season through neutral
groups, programmes, activities, occurrences, registrations, requirements, and responsible-party
relationships.

Planned contexts:

| Context | Ownership |
| --- | --- |
| Directory | Profile, groups, participants, memberships, responsible parties, import provenance |
| Programmes | Bounded operating years or seasons |
| Activities | Activities, occurrences, invitations, registrations |
| Readiness | Requirement versions, submissions, attestations, assessment, verification, exceptions |
| Welfare | Later purpose-limited health and care information |
| Communications | Later announcements, emergency broadcasts, controlled replies |

Finance, purchasing, inventory, transport, HR/payroll, generic CRM, arbitrary workflow, and
safeguarding cases are outside the package.

## Current Core prerequisite state

The generic handler/transaction seam is **partial**, not absent:

- handler behaviour, configured lookup, Core transaction ownership, generic authority scope,
  manufacturing extraction, and a neutral fixture exist;
- immutable capability versions/descriptors, startup duplicate validation, explicit cell identity,
  deterministic clock/identifier ports, relationship facts, pending obligations, and the complete
  conformance matrix remain planned.

[ADR 0008](../../../architecture/adr/0008-versioned-domain-capability-integration.md) proposes the
remaining contract. Participation cannot persist consequential state until the affected pieces are
accepted and executable.

## Planned invariants

- Every authoritative row and lookup is cell-scoped.
- A participant is not a login principal.
- Adult rights are exact-target, effective, sourced, purpose-aware, and independently resolved per
  cell.
- Imports are provenance-tracked, reconciled, and idempotent.
- Programmes are bounded periods, not generic projects or accounting periods.
- Recurrence materializes bounded deterministic occurrences.
- Activity category cannot select arbitrary executable behavior.
- Requirements, documents, consent, and signature policies are immutable/versioned.
- Readiness is derived and reconstructable, never directly set.
- General readiness is separate from welfare content.
- Adapters and jobs use named public contexts/capabilities, not `Repo` bypasses.
- No universal entity/custom-field/workflow engine is introduced.

## First proof

The first product handler should confirm an activity registration. It proves cell/target scope,
responsible-party authorization, idempotency, expected version, invariant rejection, atomic evidence
and outbox facts, and safe replay without making health or multi-signature behavior the first seam
test.

## Phase 0 status

Prepared:

- [full proposal](../../participation/IMPLEMENTATION_PROPOSAL.md);
- [Phase 0 gate](../../../architecture/participation/phase-0/README.md);
- [context map](../../../architecture/participation/context-map.md);
- [Core seam decision](../../../architecture/adr/0008-versioned-domain-capability-integration.md);
- [Participation boundary decision](../../../architecture/adr/0009-participation-domain-package-boundary.md); and
- [threat model](../../../architecture/threat-models/participation.md).

Still open: approval of both ADRs, package topology, account/relationship/signature policies,
redacted input artifacts, pilot topology, PWA/communication decisions, welfare retention and access,
and legal/privacy ownership.

No user guide or screenshots are appropriate because there is no operable surface.

## Verification scope

Phase 0 verification covers document status, links, source accuracy, consistency with accepted Core
boundaries, and repository documentation gates. It does not prove Participation behavior.

Update this page whenever either proposed ADR changes, the package is scaffolded, source forms are
approved, the first capability changes, or any context/privacy/release boundary changes.

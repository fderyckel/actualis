# Participation Phase 0 gate

Status: In progress  
Reviewed: 2026-07-19  
Owners: Actualis Product, Engineering, Security, and Privacy

## Outcome

Freeze the Participation vocabulary, ownership boundaries, security posture, first product slice,
and real-input requirements before product schemas or UI spread.

Phase 0 is an architecture and discovery phase. It does not authorize real personal data, create an
`actualis_participation` application, or make Activity Readiness available to users.

## Prepared in this phase

- Product architecture proposal with a bounded next coding-agent sequence; the full implementation
  proposal remains to be created after decision review.
- Proposed versioned Core domain-package seam in
  [ADR 0011](../../adr/0011-versioned-domain-capability-integration.md).
- Proposed Participation bounded context and anti-ERP constraints in
  [ADR 0009](../../adr/0009-participation-domain-package-boundary.md).
- [Current and target context map](../context-map.md).
- [Participation threat model](../../threat-models/participation.md).
- Technical status page and documentation-map entry.
- Decision and source-input register below.

These documents are proposals until their owners accept or amend them.

## Current Core evidence and prerequisites

The current repository already provides a partial domain-neutral seam:

| Core capability | Current state | Participation prerequisite still missing |
| --- | --- | --- |
| Handler behaviour | Implemented, capability string only | Contract and handler version descriptors |
| Configured registry | Implemented as lookup over configured modules | Startup validation and duplicate key rejection |
| Core-owned transaction | Implemented | Explicit deterministic clock/identifier ports and bounded result contract |
| Generic authority scope | Partial | Explicit cell contract and full cross-cell conformance tests |
| Neutral conformance fixture | Partial | Versions, obligations, concurrency, malformed results, and delivery replay |
| Product extraction | Manufacturing is a separate OTP application | Permanent Participation package/repository topology decision |
| Relationship facts | Not implemented | Exact-target, effective, versioned resolver contract |
| Long-running obligations | Not implemented | Pending/finalization lifecycle with reauthorization |

Participation code must not work around these gaps with direct Core-table access or adapter-owned
business logic.

## Product decision register

| Decision | Proposed default | Status | Required before |
| --- | --- | --- | --- |
| Product/package name | Actualis Participation / `actualis_participation` | Proposed | ADR acceptance |
| First capability area | Activity Readiness | Proposed | Roadmap acceptance |
| Minor authentication | Participants under 18 do not authenticate in the initial release | Needs confirmation | Directory/account design |
| Adult multi-cell access | One account may act in multiple cells through separate rights | Proposed | Relationship contract |
| Responsible-party rights | Explicit rights, source, validity, target, and purpose | Principle agreed; exact rights open | Relationship policies |
| Signature rule | Bounded variants: any, all, named, adult+staff, adult-self | Proposed; exceptions open | Attestation design |
| Missing signature | Configured approved rule; exception is a governed decision, never silent | Proposed | Readiness exceptions |
| Roster authority | Federation/club source remains authoritative for declared fields | Proposed; sources open | Production import mapping |
| Pilot topology | One or several cells | Open | Product shell and routing |
| Client delivery | Installable online-first PWA before native apps | Proposed | UI phase |
| Communications | Announcement plus optional controlled private reply | Proposed | Communications phase |
| Welfare retention/access | Purpose-, field-, assignment-, cell-, and time-limited | Principle agreed; periods open | Welfare phase |
| Legal roles | Follow actual purposes and means; not an admin toggle | Legal review required | Real-data pilot |
| Offline emergency access | Not included without a separate approved threat model | Proposed | Live-activity phase |

An open row is not permission for a coding agent to choose a permanent schema default.

## Required real inputs

No real or redacted product artifacts have been supplied to this repository yet.

| Input | Why it is needed | Safe interim work | Blocks |
| --- | --- | --- | --- |
| Redacted roster/export samples and source rules | Exact identifiers, fields, authority, reconciliation | Synthetic contract and fixtures | Production import mapping |
| Redacted health declaration | Exact welfare fields, versions, required evidence | Threat model and abstract requirement types | Welfare schema |
| Redacted parental authorization | Attestation content and applicability | Generic attestation contract | Final requirement definition |
| Redacted photo/video consent | Scope, duration, revocation, use restrictions | Consent lifecycle design | Media projection policy |
| Example wet-signed document | Upload, hash, signer, and verification evidence | Object-evidence contract | Uploaded-signature flow |
| Pilot organization and cell count | Routing, roles, load, and support assumptions | Single-cell baseline | Pilot topology |
| Named privacy/legal owner | DPIA, retention, controller/processor analysis | Technical minimization controls | Real-data pilot |

Use fictional participants and organizations in every fixture until the real-data gate is approved.

## Phase 0 exit gate

Phase 0 is complete only when:

1. Product and Engineering accept or amend ADR 0011 and ADR 0009.
2. The first-slice contexts, tables, capabilities, facts, and evidence each have one owner.
3. The package/repository and composed-release topology is decided.
4. Authentication, responsible-party, signature/exception, roster-authority, and pilot-topology
   decisions are explicit enough not to change the first Core contract.
5. Required source artifacts are received, or every blocked field mapping is clearly deferred.
6. Security and Privacy accept the threat-model scope and owners.
7. The next coding task is bounded to the remaining Core contract work; no Participation tables are
   introduced prematurely.

## Next coding-agent sequence

1. Turn ADR 0011's version and descriptor semantics into executable Core contracts and startup
   registry validation.
2. Add deterministic clock/identifier ports and expand the neutral conformance matrix.
3. Design and implement the narrow relationship-fact and pending-obligation contracts.
4. Finish explicit cell identity and isolation behavior without product vocabulary.
5. Re-run Core migration, conformance, boundary, and documentation gates.
6. Only after this gate and ADR 0009 approval, scaffold `actualis_participation` in its approved
   repository topology.

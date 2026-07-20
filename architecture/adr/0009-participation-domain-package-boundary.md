# ADR 0009: Participation is a bounded product domain, not a sector module or ERP

- Status: Proposed
- Date: 2026-07-19
- Owners: Actualis Product and Engineering

## Context

Actualis must support organizations that manage people across a year-long programme and
time-bounded activities. A Scout unit may have sections, weekly meetings, weekends, and a summer
camp. A football club may have teams, a season, recurring training, matches, tournaments, and a
summer camp.

Naming the package after Scouting would encode one sector into reusable product code. Naming it
“clubs”, “organizations”, or “ERP” would invite accounting, inventory, purchasing, HR, CRM, and
unrelated workflows into one vague module.

The stable domain is participation: people have effective memberships in groups and programmes,
register for activities, satisfy explicit requirements, and receive purpose-limited support from
responsible adults and staff.

## Decision

Name the product package **Actualis Participation**, with OTP application
`:actualis_participation` and Elixir namespace `Actualis.Participation`.

Participation is separately owned from Actualis Core. It owns its schemas, migrations, contexts,
capability handlers, domain facts, projections, tests, and product documentation. Its source may be
composed beside Core in an explicit integration workspace, but `actualis_core` never depends on or
queries it. The permanent Git/release topology is confirmed before the Phase 2 scaffold and must
remain consistent with [ADR 0003](0003-domain-packages-outside-core.md).

The first user-facing capability area is **Activity Readiness**. Camp readiness is an activity
configuration, not a hierarchy level or package boundary.

### Neutral vocabulary

| Participation concept | Scout use | Football use |
| --- | --- | --- |
| Cell | Unit | Club |
| Group | Section | Team |
| Programme | Scouting year | Season |
| Participant | Scout | Player |
| Membership | Section membership | Team registration |
| Activity | Camp, weekend, outing | Camp, tournament, trip |
| Occurrence | Weekly meeting | Training session or match |
| Responsible adult | Guardian or leader | Parent, coach, or staff member |
| Readiness | Camp forms and authorization | Registration, medical, or camp forms |

A programme is a bounded operating period. An activity belongs to a programme and may have one or
more scheduled occurrences. Recurring training or meetings materialize bounded occurrences.
Activity category is descriptive; it never selects arbitrary executable code.

### Participation ownership

Participation owns:

- a cell-local organization profile and display terminology;
- groups, participants, effective memberships, and responsible-party relationships;
- provenance-tracked roster imports and reconciliation;
- programmes, activities, occurrences, invitations, and registrations;
- versioned requirements, submissions, evidence references, attestations, supported signature
  policies, readiness assessment, verification, expiry, and governed exceptions;
- purpose-shaped Participation and welfare projections; and
- later attendance, headcount, announcements, emergency broadcasts, and controlled replies.

Core owns only cell/principal context, governed invocation, authority, obligation and evidence
envelopes, idempotency, transaction coordination, and durable delivery contracts.

A participant is not an authenticated principal. Importing or creating a participant never creates
login credentials. An adult account may act in multiple cells only through separately resolved,
effective, and authorized assignments or responsible-party relationships.

### Anti-ERP constraints

Participation will not implement:

- a universal entity, document, party, business-object, or resource table;
- entity-attribute-value or unrestricted custom-field persistence;
- a metadata-defined form, report, state-machine, or workflow engine;
- generic before/after persistence hooks or monkey patches;
- authorization based only on a global role name;
- a single polymorphic table with unrelated lifecycle fields;
- accounting, payments, purchasing, inventory, fleet, payroll, generic CRM, or safeguarding cases;
  or
- controllers, LiveViews, imports, or jobs that bypass named governed operations.

Supported requirement and signature policies are explicit, versioned Elixir contracts. A new
variant requires code, tests, review, migration/compatibility analysis, and documentation.

### Elixir and Phoenix boundaries

Use cohesive public contexts such as `Directory`, `Programmes`, `Activities`, `Readiness`, and later
`Welfare` and `Communications`. Web, LiveView, jobs, imports, and provider adapters call public
context/capability functions. They do not call `Repo`, internal changesets, or foreign schema modules
directly.

Pure rules remain plain Elixir modules. Ecto schemas model named relational concepts and enforce
cell-aware constraints. OTP processes are introduced only for real concurrency, scheduling,
resource ownership, back-pressure, or failure-isolation needs.

## Phase 0 effect

Phase 0 adds decisions, maps, threat analysis, input registers, and a coding-agent delivery plan. It
does not add Participation tables, handlers, routes, supervisors, or UI. It does not replace
[ADR 0007](0007-manufacturing-exception-replan-lead-proof-journey.md); manufacturing remains the
accepted lead proof journey for the current Actualis programme.

## Consequences

- Scout and football organizations share one model without sector forks.
- Year-long operation is first-class; the product is not reduced to camp registration.
- Cohesion depends on keeping finance, assets, transport, generic administration, and safeguarding
  outside the package.
- Responsible-party rights, signatures, health, retention, and communications require explicit
  product, privacy, legal, and operating decisions.
- Purpose-limited welfare data is a later, higher-risk phase after ordinary registration and
  readiness boundaries work.
- Real redacted forms and roster samples are prerequisites for final production field mappings.

## Alternatives rejected

### `actualis_scouting`

Rejected because football and other participation organizations would become adaptations of a Scout
model.

### `actualis_clubs` or a generic organization module

Rejected because not every valid organization is a club and organization administration is broader
than participation.

### A generic ERP application

Rejected because finance, assets, people, activities, and arbitrary workflows do not share one
stable set of invariants, access rules, or retention policies.

### Put participants or relationships in Core

Rejected because their lifecycle and meaning are product semantics. Core may evaluate typed,
versioned relationship facts without becoming a person master.

## Validation

The decision is ready to accept when Product and Engineering approve the name, vocabulary, bounded
context, package topology, and anti-ERP constraints. The implemented product conforms when:

- a football season with recurring training and a summer camp and a Scout year with meetings and a
  summer camp use the same tables and capability contracts;
- Core contains no participant, team, section, programme, training, camp, guardian, health-form, or
  readiness schema or invariant;
- every authoritative row and lookup is cell-scoped;
- a participant never becomes a principal implicitly;
- readiness is derived from versioned requirements, valid submissions, attestations, expiry, and
  approved exceptions rather than a writable Boolean;
- adapters use named context and capability boundaries;
- adjacent ERP capabilities and safeguarding remain separate; and
- dependency and conformance tests enforce ownership direction.

Reconsider the boundary when a proposed feature cannot be expressed as governing a person's
membership or participation in a programme or activity without importing an unrelated lifecycle.


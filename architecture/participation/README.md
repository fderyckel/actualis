# Actualis Participation architecture

Status: Phase 0 in progress  
Reviewed: 2026-07-19  
Owner: Actualis Product and Engineering

Actualis Participation is the proposed domain package for organizations that manage people across
year-long programmes and time-bounded activities. It is deliberately neutral: the same model must
support a Scout unit with weekly meetings and a summer camp, and a football club with training,
matches, tournaments, and a summer camp.

The package name is `actualis_participation`, with the Elixir namespace
`Actualis.Participation`. Its first product capability area is **Activity Readiness**. Camp
readiness is one activity configuration, not a package boundary or hierarchy level.

Phase 0 artifacts:

- [Phase 0 gate](phase-0/README.md) records completed architecture work, open product decisions,
  required real inputs, and the exit gate.
- [Context map](context-map.md) separates Core, Participation, Phoenix delivery, identity,
  upstream rosters, evidence storage, and communications.
- A full implementation proposal and coding-agent protocol remain to be created after the proposed
  decisions and real-input register are reviewed.
- [Participation threat model](../threat-models/participation.md) covers cell isolation, minors,
  responsible adults, signatures, welfare data, imports, and activity-time access.
- [ADR 0011](../adr/0011-versioned-domain-capability-integration.md) proposes the remaining
  versioned Core integration contract.
- [ADR 0009](../adr/0009-participation-domain-package-boundary.md) proposes the bounded context and
  anti-ERP constraints.

No Participation application code exists yet. Existing generic Core runtime work is partial and
must not be described as a completed versioned domain-package contract.

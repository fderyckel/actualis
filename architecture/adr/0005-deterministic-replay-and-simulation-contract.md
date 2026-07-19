# ADR 0005: Deterministic replay precedes simulation

- Status: Accepted baseline
- Date: 2026-07-18

## Context

Actualis must reconstruct consequential decisions and may later compare alternatives in accelerated or counterfactual scenarios. An outbox, event history, or snapshot makes data durable, but does not by itself make execution deterministic. Wall-clock reads, generated identifiers, randomness, changing policies, solver versions, AI calls, device responses, and external services can make the same apparent input produce a different result.

Building a general simulator now would be premature. Failing to preserve deterministic seams now would make trustworthy replay and future simulation disproportionately expensive.

## Decision

Core defines deterministic replay as reconstruction from an explicit, versioned input set. The set contains, as applicable:

- a cell and authoritative snapshot reference;
- ordered invocation, event, observation, and acknowledgement records;
- capability, contract, schema, policy, configuration, and rule versions;
- explicit clock values, generated identifiers, and randomness inputs;
- recorded solver, AI, device, and external-system results used by the decision.

Capability and policy logic must not depend on unrecorded wall time, randomness, environment state, or network results. Time, identifiers, and randomness enter through explicit ports. Code that consumes an external or nondeterministic result records the result and its provenance before that result becomes part of a consequential decision.

Replay reconstructs prior evaluation from recorded inputs and must not silently repeat an external side effect. AI and solver calls are replayed from their recorded results by default; re-execution is a separately labelled experiment with pinned versions and is not historical reconstruction.

A simulation forks a declared snapshot into an isolated namespace and uses a virtual clock plus explicit adapters for external systems. Simulation output is a proposal with evidence and lineage. It cannot publish to production delivery ports, acknowledge production commands, or mutate authoritative state. Moving a simulated proposal into production requires a new governed capability invocation against current authoritative versions and invariants.

Determinism applies to Core evaluation, orchestration state, and domain logic that declares conformance. It does not claim to reproduce the physical world, scheduler timing, network behavior, or an unrecorded external system. Each replay or simulation result states its determinism scope and any substituted inputs.

Schema and contract evolution must preserve a supported replay path for retained evidence. Where exact replay can no longer be supported, the incompatibility is explicit and the original evidence remains readable.

## Consequences

- Current implementation work must inject or record nondeterministic inputs instead of reading them implicitly.
- Historical reconstruction remains distinct from rerunning a newer model, solver, policy, or capability implementation.
- Future scenario tooling can reuse production contracts without gaining production authority.
- Event and evidence retention must include the versions and inputs needed for the promised replay period.
- Conformance tests can verify repeated evaluation against the same input set and detect accidental nondeterminism.

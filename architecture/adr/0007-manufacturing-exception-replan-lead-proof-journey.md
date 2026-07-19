# ADR 0007: Manufacturing exception and replan is the lead proof journey

- Status: Accepted
- Date: 2026-07-19
- Owners: Actualis product and architecture

## Context

The Architecture Vision v0.1 requires Actualis to begin with one consequential decision, two
different surfaces, one machine observation, one authorized command, and one complete
evidence trail. It also requires the programme to choose either manufacturing exception and
replan or education timetable adaptation as the lead operational journey.

The repository currently contains a pallet-movement proof. It demonstrates useful Core
mechanics but does not implement observation promotion, commitment impact, replanning,
approval, dispatch acknowledgement, delivery, offline continuity, or human-facing surfaces.
The implementation originally sat inside Core even though
[ADR 0003](0003-domain-packages-outside-core.md) and
[ADR 0006](0006-pallet-movement-application-module.md) assign manufacturing ownership to a
separate domain package. It has since moved into the co-deployed `actualis_manufacturing`
application; the larger journey gaps remain.

Continuing to expand Core without a real product proof would trigger the v0.1
"platform before product" risk. Starting a different domain now would discard the useful
evidence already present and leave the same boundary questions unresolved.

## Decision

Manufacturing exception and replan is the first cross-component Actualis proof journey.

The journey is defined by the
[manufacturing reality contract](../reality-contracts/manufacturing-exception-replan-v0.1.md).
It must prove:

- one authenticated device observation and explicit validation/promotion;
- one governed material-movement exception;
- one operator response and one planner decision;
- independent approval where policy requires it;
- dispatch, expiry, acknowledgement, and communication state;
- two materially different experience packages; and
- one reconstructable evidence trail.

Manufacturing schemas, invariants, capabilities, events, projections, and product surfaces
remain outside Actualis Core. Core development is justified only by reusable contracts required
by this journey and verified through a neutral conformance fixture.

Education timetable adaptation is the second proof slice. Branded content/commerce remains
the third proof of headless experience freedom.

The programme does not stabilize a generic schema compiler, Surface SDK, solver platform,
service split, telemetry store, broker, workflow engine, or runtime AI architecture before
these proof slices expose genuine repetition or a measured quality scenario.

## Consequences

- The existing pallet implementation becomes migration input for a manufacturing package, not
  precedent for Core ownership.
- Core and the manufacturing proof should advance as synchronized tracks with independent
  ownership and dependency direction.
- A named manufacturing operational owner is required before the reality contract can be
  marked validated.
- The first replanning proof may use deterministic alternatives or a narrow solver adapter; it
  need not create a general optimization platform.
- Product surfaces, Edge behavior, Relay delivery, and Link adapters are required to validate
  the stack but do not become Core modules.
- If the journey needs a new Core concept, the team must first show that it is a stable
  lifecycle envelope rather than manufacturing vocabulary.

## Validation

This decision is validated when the reality contract's exit criteria pass and the architecture
fitness scorecard shows:

- an operational owner accepts the normal and failure flows;
- the same governed contracts support two distinct surfaces;
- device disconnect and replay do not duplicate a validated observation or effect;
- manufacturing can be removed without changing Core schemas;
- the full observation-to-outcome path is reconstructable; and
- production-shaped load, restore, and workload-isolation evidence either confirms or revises
  the starting hypotheses.

## Reconsideration

Reconsider the lead journey only if operational discovery shows that it lacks a real owner,
cannot be observed safely, or does not exercise the claimed architecture. A change requires a
superseding ADR and must not move manufacturing semantics into Core to preserve sunk work.

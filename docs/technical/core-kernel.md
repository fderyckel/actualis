# Core-kernel technical reference

Status: partial production foundation; implemented and tested locally.

`Actualis.CapabilityRuntime.execute/1` is the single command boundary. It validates the canonical request, claims a principal-scoped receipt, evaluates `Actualis.Authority`, locks the pallet, applies invariants, and persists all consequences in one Ecto transaction.

Confirmed failure semantics include invalid commands, untrusted devices, unassigned operators, ungranted purposes, stale versions, stale source locations, held material, invalid destinations, duplicates, and idempotency-key misuse. Governed rejections retain a completed receipt and evidence but no movement or outbox event.

Projection snapshots execute at repeatable-read isolation and return the current durable cursor. Catch-up reauthorizes the caller and returns ordered, unexpired, unrevoked deltas after that cursor, filtering fields against the active grant.

The outbox is durable storage only; publication is planned. Local identity headers are not production authentication.

Evidence: `apps/actualis_core/test/actualis/kernel_test.exs` and `apps/actualis_web/test/actualis_web/controllers/kernel_controller_test.exs`.

# Pallet-move threat model

| Threat | Implemented control | Remaining work |
|---|---|---|
| Caller self-authorizes | Body identity/capability are overwritten; authority resolves database state | Replace local headers with OIDC and device proof |
| Duplicate effect | Principal-scoped key and deterministic request hash | Retention and pruning policy |
| Lost update | Row lock plus expected version | Ordered locking convention for multi-aggregate commands |
| Stale physical source | Claimed source must equal authoritative current location | Observation validation/promotion |
| Held material moves | Only released pallets can move | Break-glass and approval workflow |
| Field disclosure | Separate projection payloads plus grant field filtering and reauthorization | Mask transformations and revocation worker |
| Lost downstream notification | Outbox event commits with the effect | Delivery, signature, retry, acknowledgement, dead letters |
| Evidence tampering | Evidence commits atomically with the effect | Append-only database enforcement and external anchoring |

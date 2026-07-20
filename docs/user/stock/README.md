---
title: Understanding planned stock control in Actualis
doc_type: user_concept
audience: operators_supervisors_administrators_support
kernel_area: stock_domain_package
status: planned
paired_technical_docs:
  - docs/technical/stock/README.md
screenshots: []
last_verified: 2026-07-19
---

# Understanding planned stock control in Actualis

## Current availability

Stock control is not yet available to operate. Actualis currently contains only the initial
technical boundary and planned permission names. There are no stock screens, items, locations,
balances, movements, or counting procedures.

Screenshots and operating steps are intentionally absent. They will be added from a working
interface rather than from a mock-up.

## What the stock capability is intended to clarify

Actualis will keep several quantities separate so operators are not given an ambiguous number
labelled simply “stock.”

| Term | Intended meaning |
|---|---|
| On hand | Quantity calculated from posted physical stock movements |
| Physical observation | Quantity a named counter actually observed at a place and time |
| Variance | Difference between a comparable observation and ledger expectation |
| Usable | On-hand quantity that is not quarantined or damaged |
| Reserved | Quantity promised by a separate process; it does not change on hand |
| Available | A named process calculation, normally usable minus active reservations |
| Target | A monitoring threshold, not a recorded balance |
| Expected inbound | A promise from another process; it becomes on hand only when received |

The same stock foundation is intended to support school supplies, manufacturing materials, and
community equipment. Courses, work orders, events, members, procurement, and accounting remain
separate processes.

## Planned permission areas

The technical foundation reserves distinct permission areas for:

- viewing positions;
- managing stock items;
- managing accountable locations;
- moving quantities;
- posting exceptional adjustments;
- conducting physical counts;
- reviewing count differences; and
- managing monitoring policies.

No administrator can grant or use these Stock permissions through a product interface yet.

## Planned delivery order

1. Register stock items and locations, then receive, issue, transfer, and audit quantities.
2. Conduct frozen-location physical counts and reconcile reviewed differences.
3. Monitor typed conditions such as minimum usable quantity, expiration, and unresolved variance.
4. Connect one real education, manufacturing, or community process through governed commands and
   reliable events.

Reservations, equipment custody, rolling counts, and offline capture remain optional. They will
not be enabled as generic ERP features without a concrete need.

## What is not yet documented as an operation

There are no trustworthy steps yet for:

- creating an item or location;
- receiving, issuing, or transferring stock;
- checking an on-hand quantity;
- counting a location;
- approving a correction;
- configuring monitoring; or
- recovering from a failed stock operation.

Each procedure will be documented from implemented labels, permissions, validation, and recovery
behavior when its working interface exists.

## Related information

- [Technical Stock foundation](../../technical/stock/README.md)
- [Actualis Core user guide](../core-kernel/README.md)

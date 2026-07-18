---
title: Understanding the Actualis core kernel
doc_type: user_concept
audience: operators_supervisors_administrators_support
kernel_area: foundation
status: partial
paired_technical_docs:
  - docs/technical/core-kernel/README.md
screenshots: []
last_verified: 2026-07-18
---

# Understanding the Actualis core kernel

## Current availability

The current workspace contains a partial in-process kernel and a JSON service, not an end-user application. The service exposes governed pallet movement, authorized data views, and evidence reads to software clients, but there is no screen a human operator can use. This page explains the behavior users will encounter; it does not provide steps for an unavailable interface.

Screenshots will be added when a working product surface exists. They are intentionally absent now so conceptual mockups are not mistaken for implemented behavior.

## What the kernel is for

The core kernel is the controlled record of who or what acts, where manufacturing items are, why an action was allowed or denied, and what evidence remains afterward.

The current pallet-movement kernel connects a manufacturing action to:

- the person, device, integration, worker, or AI that acted;
- the site and location in which the action occurred;
- the permission and purpose used for the action;
- the item state before and after the action;
- a receipt that prevents the same request from being applied twice;
- an evidence record and an event for downstream views.

This governed flow exists inside the kernel and is exposed through a JSON service. Verified production authentication, user administration, and user-interface behavior are not part of the current snapshot.

## Core concepts

| Term | Meaning for a user |
|---|---|
| Principal | The identity of a human or system actor. An identity can be active, suspended, or revoked. |
| Site | A manufacturing facility or operational site. |
| Location | A named place within a site, such as a storage or processing area. A location can be inactive. |
| Operator assignment | The record that associates an operator identity with a site for a period of time. |
| Trusted device | A device identity associated with a site. Device trust can be trusted, quarantined, or revoked. |
| Policy version | A versioned set of authorization rules that can be draft, approved, or retired. |
| Capability grant | Permission for an identity to perform a named action for a defined scope and purpose, potentially with field restrictions, obligations, or expiry. |
| Pallet | A tracked manufacturing item with a label, material code, current location, quality status, and version. |
| Movement | A historical record that a pallet moved from one location to another, by an identified actor, for a reason. |
| Command receipt | The record that makes a submitted action traceable and protects it from accidental duplicate application. |
| Evidence record | The record that explains the action or decision, including purpose, scope, policy version, and resulting effects. |
| Projection delta | An ordered change used to update an operator or supervisor view. It can expire or be revoked. |

## How governed pallet movement works

Although there is no user screen yet, the kernel's current movement sequence is defined:

1. A request identifies the human, trusted device, site, pallet, current location, destination, business purpose, reason, pallet version, and unique retry key.
2. Actualis validates the request and checks that the human is active, the device is trusted for the site, the operator assignment is current, and an approved permission matches the capability, site, and purpose.
3. Actualis locks the pallet and checks that it is still at the claimed source, its version has not changed, its quality status is released, and the destination is active in the same requested site.
4. On success, Actualis changes the location and version, writes movement history, evidence, an event, operator and supervisor updates, and a completed receipt in one database transaction.
5. Repeating the exact completed request with the same retry key returns the saved result. Reusing that key for a different request is refused.

An authorization denial or business-rule rejection is also completed with a receipt and evidence. It does not move the pallet or create the success event and view updates.

## Pallet quality status

The current model defines three quality statuses:

- **Released:** the movement handler can move the pallet when all identity, permission, version, source, and destination checks also pass.
- **Hold:** the movement handler refuses to move the pallet. The user-visible release workflow is not yet defined here.
- **Quarantined:** the movement handler refuses to move the pallet. The user-visible recovery workflow is not yet defined here.

Released status alone does not grant permission. The identity, trusted device, assignment, grant, purpose, version, source, and destination checks must also pass.

## Why a move may be refused

The interface wording is not yet defined, but the kernel distinguishes these conditions:

| Condition | Meaning | Safe response |
|---|---|---|
| Not authorized | The human, device, assignment, policy, permission, scope, or purpose did not pass the access check. | Do not retry unchanged. Ask an authorized administrator or supervisor to review access and site context. |
| Pallet not found | The pallet does not exist in the requested site. | Confirm the site and pallet identity. |
| Version conflict | The pallet changed after the displayed or synchronized view was read. | Refresh the pallet, review its latest state, and decide again. |
| Source location conflict | The pallet is no longer at the source claimed in the request. | Refresh the pallet and use its current location. |
| Quality status blocks movement | The pallet is on hold or quarantined. | Follow the approved quality workflow; do not work around the status. |
| Invalid destination | The destination is missing, inactive, or outside the requested site. | Select an active destination in the correct site. |
| Destination unchanged | The destination is the pallet's current location. | Choose a different active location or cancel. |
| Retry key reused | The same retry key was already used for different request details. | Create a new key for the genuinely new request. |
| Command still processing | A request with this retry key has not completed. | Wait for a defined recovery or status surface; automated recovery is not present in this snapshot. |

The future interface must translate these conditions into clear product messages and preserve the safe-response guidance.

## Operator and supervisor views

The kernel can build site-scoped operator and supervisor snapshots and ordered updates. Every read re-checks the human, device, site assignment, purpose, policy, and matching view permission. The result contains only fields listed in the permission grant. Movement updates expire from catch-up after eight hours and are ignored if revoked; a fresh snapshot is the baseline when older deltas are unavailable.

No screen currently displays these views in this workspace.

## What users should eventually be able to verify

Once an operating surface is implemented, each documented task should make it possible to confirm:

1. which site, location, pallet, and current version are being acted on;
2. which action and business purpose are requested;
3. whether the identity and device are permitted to perform it;
4. whether the operation completed, was denied, or must be retried;
5. where to see the receipt, movement history, and explanation that were recorded.

The future task guide must include real screenshots of the pallet state, the action controls, the confirmation or denial state, and the resulting history wherever those images reduce ambiguity.

## What is not yet documented as an operation

No trustworthy step-by-step instructions can be written from the current source for:

- signing in or choosing a site;
- administering identities, devices, assignments, policies, or grants;
- creating or locating a pallet;
- moving a pallet;
- placing a pallet on hold or in quarantine;
- reviewing receipts, evidence, events, or synchronized changes;
- recovering from a denied, conflicting, offline, or failed action.

Each becomes a separate user task page, generated from the working implementation with exact interface labels, verified recovery behavior, and current screenshots.

## Related information

- [Technical core-kernel reference](../../technical/core-kernel/README.md)
- [Documentation workflow](../../process/documentation-workflow.md)

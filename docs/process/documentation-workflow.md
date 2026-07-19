---
title: Core-kernel documentation workflow
doc_type: process
scope: core_kernel
status: active
last_verified: 2026-07-19
---

# Core-kernel documentation workflow

## Outcome

Every core-kernel change ships with accurate, navigable documentation for two audiences:

1. A technical reference for coding agents and maintainers that is also straightforward for a human engineer to read.
2. A user guide for the people who need to understand and operate Actualis.

Agents generate, verify, curate, and fine-tune both tracks. A human maintainer remains accountable for approving the implementation and its documentation together.

## Source-of-truth order

When evidence conflicts, use this order and call out unresolved differences:

1. Executable behavior and automated tests.
2. Public contracts, schemas, migrations, configuration, and access policy.
3. Accepted architectural decisions and implementation requirements.
4. Existing documentation.
5. Screenshots.

Screenshots prove what a person saw at capture time; they do not override current behavior.

## When documentation is required

A technical update is required when a change affects any of the following:

- domain terms, data shape, constraints, or state transitions;
- commands, queries, events, projections, or integration contracts;
- authorization, scope, purpose, field masking, or policy behavior;
- idempotency, transactions, concurrency, ordering, or failure behavior;
- migrations, configuration, deployment, observability, or recovery;
- a source path listed in `docs/doc-map.yaml`.

A user update is required when a change affects anything a user can see, choose, enter, understand, or recover from, including terminology, permissions, validation, status, notifications, and visible audit history.

Internal refactoring with no changed contract still requires the technical page's verification date and source map to be checked. Record `user_impact: none` with a short reason in the documentation map when no user page changes.

## Change workflow

### 1. Classify the change before implementation

The implementation agent identifies:

- affected kernel area and source paths;
- changed contracts or invariants;
- affected roles and user tasks;
- whether a screenshot-bearing surface changes;
- technical pages, user pages, and documentation-map entries to update.

Put this documentation plan in the change description. Unknowns are marked explicitly and resolved before approval.

### 2. Build an evidence packet

After implementation, the generating agent reads the final change rather than relying on the original plan. The evidence packet contains only material needed for the affected area:

- changed source, migration, policy, event, and configuration files;
- relevant tests and their results;
- routes or UI surfaces that expose the behavior;
- before/after behavior and failure cases;
- deterministic test personas and data used for screenshots;
- decisions that explain non-obvious trade-offs.

The packet is temporary working context. Durable claims go into the documentation; durable design decisions belong in a linked decision record when that convention is introduced.

### 3. Generate or update the technical track

Start with the [technical-page template](../_templates/technical-page.md). Write for retrieval by an agent and comprehension by a maintainer:

- use canonical names that match the source;
- state scope and implementation status near the top;
- describe contracts, invariants, authorization, transactions, events, and failure modes;
- link each important claim to its source path or test in the source map;
- separate current behavior from planned work and known gaps;
- use small diagrams or examples only when they remove ambiguity.

Do not turn source code into prose line by line. Explain the stable model and the reasons a future change must respect it.

### 4. Generate or update the user track

If the change is user-visible, start with the [user-task template](../_templates/user-task-page.md). Write around the user's goal:

- name the outcome and the roles that can achieve it;
- list prerequisites in product language;
- use exact visible labels and statuses from the working product;
- keep one action per numbered step;
- explain how to confirm success and what changes as a result;
- cover predictable permission, validation, concurrency, and connectivity failures;
- link to concepts without exposing implementation detail.

If there is no operable surface yet, create or update a concept page only. Label procedural steps as unavailable and do not imply that a user can perform them.

### 5. Capture and curate screenshots

Follow the [screenshot standard](../assets/screenshots/README.md). Screenshots are required when they materially help a user:

- recognize the correct screen or state;
- locate a control that is not obvious from the text;
- distinguish a successful outcome from a failed one;
- recover from a visible error.

Use a deterministic local or review environment with fictional data. Capture after copy and layout stabilize. Add the image, meaningful alt text, a short caption, and a screenshot record in the same change.

Technical docs normally prefer diagrams, request/response examples, or schema excerpts. Use screenshots there only for tools or diagnostic surfaces that are genuinely visual.

### 6. Verify independently

A verifier agent re-opens the evidence rather than trusting the draft. It checks:

- every status, field, default, constraint, permission, and visible label;
- happy path and significant failure paths;
- links, commands, examples, and image references;
- that implementation status is not overstated;
- that technical and user pages agree without being duplicate text;
- that the documentation map covers the changed sources.

The verifier returns claim-level corrections. The generating agent resolves them or records a clearly owned gap.

### 7. Curate and fine-tune

A curator agent performs an audience pass after factual corrections:

- shorten repetitive or code-shaped prose;
- standardize terms using the user-facing vocabulary;
- improve headings and cross-links so answers can be found quickly;
- move deep implementation detail out of user pages;
- add context, examples, diagrams, or screenshots only where they reduce effort;
- verify accessibility of images and instructions;
- remove stale future-tense promises and unsupported claims.

For a small change, the same agent may perform all three passes, but it must treat them as separate passes and re-read the evidence during verification.

### 8. Pass the merge gates

Documentation and implementation are approved together only when all applicable gates pass:

- **Coverage:** every changed mapped source has a technical page or an explicit exemption; user impact is documented or explicitly `none`.
- **Accuracy:** behavior, permissions, statuses, examples, and UI copy match current evidence.
- **Status:** partial and planned behavior is visibly separated from implemented behavior.
- **Traceability:** page metadata and `docs/doc-map.yaml` point to current sources and paired pages.
- **Navigation:** pages are reachable from the relevant documentation entry point and have no broken local links.
- **Screenshots:** required images exist, use fictional data, have alt text and captions, and match the current surface.
- **Usability:** an intended reader can tell what the feature is, whether it is available, and what to do next.

## Change checklist

Copy this into the implementation change or pull request:

```text
Documentation impact
- [ ] Affected kernel areas and mapped source paths identified
- [ ] Technical documentation generated or updated
- [ ] User documentation generated or user_impact: none recorded with reason
- [ ] Current, partial, planned, and unavailable behavior clearly distinguished
- [ ] Screenshot impact assessed
- [ ] Required screenshots captured with deterministic fictional data
- [ ] Independent evidence-verification pass completed
- [ ] Audience curation and terminology pass completed
- [ ] Documentation map, metadata, links, and navigation checked
```

## Review cadence outside feature changes

- Review high-risk authority and execution pages after every related change.
- Review all core-kernel pages before a tagged kernel release.
- Re-capture screenshot sets when the documented surface, theme, copy, navigation, or example data changes.
- Treat a page as stale when its mapped sources changed after `last_verified`, even if the prose still looks correct.

## Current core-kernel limitation

This repository snapshot contains a partial domain-neutral capability runtime and a separately owned,
in-process manufacturing reference application with governed JSON endpoints, but no human-facing
end-user UI. The initial user documentation is therefore a concept guide, and screenshots are
correctly marked not applicable. Procedure pages and real captures become required as soon as an
operable human-facing surface is introduced.

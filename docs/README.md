# Actualis v0 documentation

Actualis documentation has two coordinated tracks. Both are generated and maintained with agent assistance, reviewed against the implementation, and written so a person can use them without reading source code.

| Track | Primary audience | Answers | Entry point |
|---|---|---|---|
| Technical reference | Coding agents, maintainers, architects, reviewers | What exists, why it exists, how it behaves, and what must remain true | [Core-kernel technical reference](technical/core-kernel/README.md) |
| User guide | Operators, supervisors, administrators, support | What Actualis means, how to complete work, and how to recover from problems | [Core-kernel user guide](user/core-kernel/README.md) |

The first product consumer has its own [manufacturing reference](technical/manufacturing-reference/README.md).
It documents product schemas, invariants, projections, and the Core integration seam without
presenting those concepts as kernel behavior.

The planned [Stock domain package](technical/stock/README.md) has a Phase 0 application boundary,
scope contract, and capability vocabulary. No Stock operation or user interface is available.

The proposed [Participation Phase 0 architecture](../architecture/participation/README.md) defines
product boundaries, real-input gates, and privacy/security constraints. No Participation application
code or operating surface exists.

Architecture discovery and benchmark readiness are tracked separately in the
[Phase 0 reality-contract evidence gate](../architecture/phase-0/README.md). Its prepared artifacts
are not user procedures or claims that field validation has occurred.

The tracks are not copies. A technical page documents contracts, invariants, authorization, persistence, and failure behavior. A user page documents goals, prerequisites, visible steps, outcomes, and recovery. They link to each other through the [documentation map](doc-map.yaml).

## Working agreement

Every implementation change must follow the [documentation workflow](process/documentation-workflow.md). Documentation is part of the change, not a follow-up task.

- Update the technical track for every kernel contract or implementation change.
- Update the user track whenever a user-visible concept, permission, workflow, message, state, or recovery path changes.
- If there is no user-visible impact, record why in the documentation map.
- Capture screenshots only from a working, deterministic product surface. Never invent a UI screenshot to represent an implementation that does not exist.
- Treat source, tests, migrations, and executable contracts as evidence. Treat existing prose and screenshots as material that must be re-verified.

Templates are available for [technical pages](_templates/technical-page.md) and [user task pages](_templates/user-task-page.md).

## Installation and deployment

- Administrators: [prepare a fresh Debian or Ubuntu VM](user/installation/fresh-vm.md).
- Maintainers: [fresh-VM deployment status and production gaps](technical/deployment/README.md).

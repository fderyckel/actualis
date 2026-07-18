# Actualis development root

`dev-actualis/` is the project root and the only source of development truth.

- Run every development, build, test, migration, documentation, and maintenance command from this directory.
- Create and edit project files only within this directory.
- Resolve all project-relative paths from this directory.
- Do not develop against, copy implementation from, or write generated output into the parent ChatGPT project mirror or its `sources/` directory.
- Treat files outside `dev-actualis/` as external reference material unless the user explicitly changes the project root.

## Core-kernel documentation

Every Actualis core-kernel implementation change must follow `docs/process/documentation-workflow.md`.

- Assess and update the agent-oriented, human-readable technical track under `docs/technical/`.
- Assess and update the end-user track under `docs/user/`, or record `user_impact: none` with a reason in `docs/doc-map.yaml`.
- Generate documentation from the final implementation and tests, then perform separate factual-verification and audience-curation passes.
- Add current product screenshots when they materially help a user complete or recover from a task. Never fabricate screenshots for an unavailable interface.
- Treat documentation and implementation as one change and apply all merge gates in the workflow.

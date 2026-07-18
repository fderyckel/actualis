# Actualis engineering standards

Status: **Normative**  
Owner: **Actualis Engineering**  
Last reviewed: **2026-07-18**

These standards define how Actualis software and documentation are written, reviewed, and
verified. They apply to application code, tests, migrations, operational tooling, and technical
documentation in the Actualis Elixir/Phoenix/PostgreSQL stack.

## Standards

- [Coding conventions](coding-conventions.md) — Elixir syntax and naming, the core/kernel
  architecture, OTP, Phoenix, Ecto, PostgreSQL, security, observability, and tests.
- [Documentation conventions](documentation-conventions.md) — code documentation, repository
  documentation, ADRs, runbooks, API documentation, writing style, and maintenance.
- [Enforcement](enforcement.md) — automated quality gates, review requirements, exceptions, and
  adoption criteria.

When the standards disagree with generated framework code, current code is not automatically
wrong. New or materially changed code follows these standards; generators are reviewed and adapted
before merge.

## Normative language

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHOULD**, **SHOULD NOT**, and **MAY** express
requirement levels:

- **MUST** and **MUST NOT** are merge requirements.
- **SHOULD** and **SHOULD NOT** require a documented reason when intentionally not followed.
- **MAY** identifies an allowed choice, not a preference.

Automated enforcement is preferred, but a rule remains normative when tooling cannot check it.

## Decision priority

When rules appear to compete, use this order:

1. Correctness, data integrity, and security.
2. Clear domain boundaries and public contracts.
3. Operability and safe change in production.
4. Readability and consistency.
5. Local brevity or cleverness.

## Version policy

The application repository MUST pin supported Elixir, Erlang/OTP, Phoenix, Ecto, PostgreSQL, and
Node.js versions in version-controlled files. A dependency or runtime upgrade MUST include:

1. release and migration note review;
2. formatting, compilation, tests, static analysis, documentation, and migration verification;
3. an update to these standards when a prescribed API is deprecated or its behavior changes.

The standards are based on primary documentation reviewed on 2026-07-18, including Elixir 1.20,
Phoenix 1.8, Ecto/Ecto SQL 3.14, and PostgreSQL 18. They do not require those exact versions unless
the application version policy says so.

## Changing a standard

A standards change requires a reviewed pull request that states the problem, the new rule, affected
code and tooling, adoption or migration work, and any compatibility impact. Actualis Engineering
owns approval. A framework upgrade does not silently override an Actualis rule; the upgrade pull
request must reconcile and update the rule explicitly.

Local precedent is useful evidence but is not an exception by itself. When code and the standard
disagree, either bring changed code into compliance or approve a standards change/exception through
the documented process.

## Actualis architecture references

These standards govern the implemented kernel described by:

- [ADR 0001: First constitutional kernel](../../architecture/adrs/0001-first-kernel.md)
- [Core-kernel technical reference](../technical/core-kernel.md)
- [Pallet-move threat model](../../architecture/threat-models/pallet-move.md)
- [Capability contract](../../contracts/capabilities/manufacturing.move_pallet.v0.json)
- [Event contract](../../contracts/events/manufacturing.pallet_moved.v1.json)

## Primary references

- [Elixir naming conventions](https://hexdocs.pm/elixir/naming-conventions.html)
- [Elixir library guidelines](https://hexdocs.pm/elixir/library-guidelines.html)
- [Elixir code anti-patterns](https://hexdocs.pm/elixir/code-anti-patterns.html)
- [Elixir design anti-patterns](https://hexdocs.pm/elixir/design-anti-patterns.html)
- [Elixir process anti-patterns](https://hexdocs.pm/elixir/process-anti-patterns.html)
- [Phoenix contexts](https://hexdocs.pm/phoenix/contexts.html)
- [Phoenix routing and verified routes](https://hexdocs.pm/phoenix/routing.html#verified-routes)
- [Phoenix security](https://hexdocs.pm/phoenix/security.html)
- [Ecto changesets](https://hexdocs.pm/ecto/Ecto.Changeset.html)
- [Ecto repositories and transactions](https://hexdocs.pm/ecto/Ecto.Repo.html)
- [Ecto SQL migrations](https://hexdocs.pm/ecto_sql/Ecto.Migration.html)
- [PostgreSQL SQL syntax](https://www.postgresql.org/docs/current/sql-syntax.html)
- [PostgreSQL data definition](https://www.postgresql.org/docs/current/ddl.html)
- [PostgreSQL indexes](https://www.postgresql.org/docs/current/indexes.html)
- [PostgreSQL concurrency control](https://www.postgresql.org/docs/current/mvcc.html)

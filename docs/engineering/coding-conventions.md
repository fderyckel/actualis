# Actualis coding conventions

Status: **Normative**  
Applies to: **Elixir, Phoenix, LiveView, Ecto, PostgreSQL, tests, and operational code**

## 1. Engineering principles

Actualis code MUST be optimized for correctness and changeability at business boundaries, not for
the fewest lines of code.

1. Make invalid states hard to represent and impossible to persist.
2. Keep business decisions in a functional core and side effects at explicit boundaries.
3. Treat public context functions, events, database constraints, and HTTP contracts as APIs.
4. Prefer explicit data flow, pattern matching, and small composable functions.
5. Use an OTP process only for a runtime property: concurrency, shared mutable state, resource
   ownership, scheduling, lifecycle, back-pressure, or failure isolation.
6. Make expected failure visible in return values. Let unexpected failures crash into a supervised
   boundary with useful context.
7. Design every database change for live production data and mixed-version deployments.
8. Add observability at domain and system boundaries without logging secrets or personal data.

## 2. Core/kernel architecture

### 2.1 Dependency direction

The standard dependency direction is:

```text
Phoenix / LiveView / controllers / APIs / jobs
                    |
                    v
          context public functions
                    |
           +--------+--------+
           |                 |
           v                 v
   pure domain modules   persistence/adapters
                             |
                             v
                    Ecto / PostgreSQL / external services
```

- The web layer MUST call context public functions. It MUST NOT contain business rules or call
  `Actualis.Repo` directly.
- Background jobs, scheduled tasks, CLI tasks, and message consumers MUST use the same context APIs
  or explicit application services as the web layer.
- A context is the public boundary for a cohesive business capability. Cross-context calls MUST go
  through the other context's public API, not its schemas, query modules, or private helpers.
- Persistence schemas and query modules are internal implementation details unless a context
  explicitly documents a returned schema struct as part of its contract.
- Domain modules SHOULD be plain modules operating on explicit values. They MUST NOT depend on
  `Plug.Conn`, `Phoenix.LiveView.Socket`, HTTP parameters, or template assigns.
- The deepest shared kernel MUST remain small and stable. Do not create `Utils`, `Helpers`,
  `Common`, or `Misc` dumping grounds. Name a module after the concept or capability it owns.
- A shared rule belongs in the kernel only when at least two business capabilities use the same
  concept with the same meaning and invariants. Similar-looking code is not sufficient.

Suggested structure (adapt to real domain names):

```text
lib/
  actualis/
    application.ex
    repo.ex
    accounts.ex                 # context public API
    accounts/                   # internal domain, schemas, queries, services
    core/                       # genuinely shared domain primitives only
    adapters/                   # external system implementations
  actualis_web/
    controllers/
    live/
    components/
```

Directory structure MUST follow ownership and boundaries. It MUST NOT add a technical layer for
every noun by default.

### 2.2 Functional core and effects

- Pure calculations MUST be plain functions. Do not wrap them in `GenServer`, `Agent`, or a process.
- Time, randomness, identifiers, environment, filesystem, network, and database access are effects.
  Pass their results into domain functions or access them through an explicit boundary.
- A function SHOULD perform either a decision/calculation or effect orchestration. If it does both,
  extract the calculation when that improves independent testing or reuse.
- Multi-step business operations MUST have one owner that defines transaction and compensation
  semantics.
- Side effects that cannot participate in a database transaction MUST be made retry-safe. Use a
  transactional outbox or equivalent durable handoff when database state and event delivery must
  agree. Do not make an external HTTP call while holding a database transaction open.

### 2.3 Actualis constitutional kernel

The first Actualis kernel establishes conventions that later capabilities MUST preserve unless an
accepted ADR replaces them.

#### Governed command boundary

- A capability command enters through one named application boundary. For the first vertical slice,
  that boundary is `Actualis.CapabilityRuntime.execute/1`.
- Capability identifiers use `<context>.<verb>_<object>`, for example
  `manufacturing.move_pallet`. They are stable contract values, not display labels.
- The transport adapter resolves the authenticated principal and device and selects the capability.
  A request body MUST NOT self-assert `principal_id`, `device_id`, roles, grants, or capability.
- Purpose, scope, expected aggregate version, and idempotency key are explicit command data. The
  boundary rejects missing, unknown, malformed, or out-of-contract data before effects begin.
- External string-keyed data MUST become a validated command struct or equally explicit canonical
  internal representation before domain rules run. Hashing and evidence use that canonical form.

#### Authority and policy

- Authorization is deny-by-default and evaluates the active principal, authenticated/trusted device,
  assignment, capability, purpose, scope, grant, policy version, expiry, permitted fields, and
  obligations.
- An authority decision is evidence-bearing data. It MUST contain a stable decision, explanation
  code, applicable policy version, permitted fields, and obligations.
- All reads of evidence, snapshots, and projection deltas MUST be reauthorized against current
  authority. Permission at write time does not grant permanent read access.
- Obligations MUST be enforced before an effect commits. `allow_with_obligations` is not equivalent to
  unconditional allow.
- Authorization explanation codes are stable machine contracts in `snake_case`. User-facing text is
  translated separately.

#### Transaction and concurrency order

A governed mutation MUST have one transaction owner and preserve this logical order:

1. validate and canonicalize the command;
2. claim the principal-scoped idempotency receipt;
3. evaluate current authority;
4. lock the affected aggregate rows in a documented deterministic order;
5. compare expected versions and evaluate domain invariants;
6. write the domain effect;
7. append evidence, a versioned outbox event, and purpose-specific projection deltas;
8. complete the receipt with the stable response;
9. commit once.

Multi-aggregate commands MUST define a global lock order. A governed rejection MAY persist its
receipt and evidence, but MUST NOT persist the rejected domain effect or success event.

#### Idempotency and receipts

- Idempotency is scoped to the authenticated principal and key and enforced by a unique database
  constraint.
- The receipt binds the key to a deterministic hash of the canonical command. Reusing the key with
  different content is a conflict; an identical completed request returns the stored response with a
  replay marker.
- Concurrent in-progress duplicates return a stable retryable/conflict result; they MUST NOT execute
  the effect twice.
- Receipt retention and pruning are product and audit decisions. Deleting receipts without an
  accepted retention policy is prohibited.

#### Evidence, events, and projections

- Evidence is append-only, purpose-aware, and sufficient to explain who requested what, using which
  device and authority, against which domain versions, with which decision and effects. It MUST NOT
  contain secrets or unnecessary personal data.
- Outbox events are facts named `<context>.<past_tense_fact>.v<major>`, for example
  `manufacturing.pallet_moved.v1`. Published event versions are immutable.
- An event includes its schema version, aggregate identifier/version, command/receipt identifier,
  evidence identifier, occurrence time, and the minimum payload consumers need.
- Writing the outbox row and domain effect atomically proves durable intent to publish; it does not
  prove delivery. Publishers MUST add acknowledgement, retry, reconciliation, and dead-letter
  behavior before production use.
- Operator, supervisor, or other projections are separate purpose-specific contracts, not one
  universal payload with client-side hiding. Fields are allowlisted from the active grant.
- Snapshot/catch-up protocols MUST return a durable cursor. Deltas are strictly ordered, bounded,
  expiry/revocation-aware, and safe to replay.
- The kernel MUST NOT introduce a universal resource table, generic workflow engine, or event-sourced
  claim without a demonstrated cross-context need and an accepted ADR.

## 3. Files, modules, and namespaces

- Source files use `snake_case.ex`; test files use `snake_case_test.exs`.
- A file SHOULD define one top-level module and match its module name:
  `Actualis.Accounts.PasswordPolicy` lives in `actualis/accounts/password_policy.ex`.
- Modules and aliases use `CamelCase`. Preserve acronym capitalization consistently, as in
  `Actualis.HTTPClient`; its filename remains `http_client.ex`.
- Test modules mirror the subject and end in `Test`.
- A module MUST have one cohesive responsibility and a public surface smaller than its private
  implementation.
- Nested modules MAY be used for small types inseparable from their parent. Reusable concepts MUST
  be top-level modules.
- `defmodule`, `use`, `require`, `import`, and `alias` declarations MUST remain easy to scan.
  Imports MUST be narrow; use `only:` except for an established DSL such as Ecto queries or tests.
- Prefer aliases to deeply qualified names when used repeatedly. Do not alias a module to a
  surprising name.
- Cyclic module or context dependencies are prohibited.

Within a module, use this order when the sections exist:

1. `@moduledoc`
2. `use`, `@behaviour`, `require`, `import`, `alias`
3. module attributes
4. types and opaque types
5. structs and exceptions
6. callbacks and public functions
7. private functions

Keep clauses of the same name and arity together.

## 4. Naming

### 4.1 Variables and attributes

- Variables, function names, module attributes, map keys, and atoms use `snake_case`.
- Names MUST express domain meaning: `subscription`, `invoice_total`, and `actor` are preferred to
  `data`, `item`, `obj`, and `value`.
- Very short names are allowed only in a tiny conventional scope: `x` in a mathematical transform,
  `acc` in a short reduction, or `id` for an unambiguous identifier.
- Include units in names where the type does not convey them: `timeout_ms`, `amount_cents`,
  `retention_days`.
- Use plural names for collections and singular names for elements.
- Use `_` for a value intentionally ignored. Use `_name` when the ignored value documents the shape
  of a pattern. Never use a leading underscore for a value that is later read.
- Rebinding is idiomatic when a value is transformed without changing meaning. Use a new name when
  meaning, unit, trust level, or lifecycle changes; for example, `params`, `validated_attrs`, then
  `account`.
- Module attributes are compile-time constants or metadata, not global mutable state. Name constants
  for meaning, not literal value: `@session_ttl_seconds`, not `@seconds_3600`.
- Never create atoms from untrusted or unbounded strings with `String.to_atom/1`.

### 4.2 Functions

- Functions and macros use verbs or verb phrases: `calculate_total/1`, `authorize/2`,
  `deliver_receipt/1`.
- Boolean predicates end in `?`: `active?/1`. Guard-safe type or property checks use the `is_`
  prefix: `is_account_id/1`.
- A trailing `!` means the function raises on failure. A bang function MUST NOT merely mean “does a
  mutation,” “is important,” or “is faster.” Prefer a non-bang form for expected failures.
- Use `new/1` to construct an in-memory value and `create_*` for a persisted business operation.
- Use `get_*` for direct retrieval, normally with `nil` for absence and a `get_*!` variant when a
  raising form is useful. Use `fetch_*` for `{:ok, value} | :error`; use `find_*` for search-like
  optional results. Document any context-specific departure.
- Names MUST reveal side effects when they are not obvious from the owning module.
- Private recursive workers paired with a public function use `do_` only when that relationship is
  useful: `sum/1` and `do_sum/2`. Prefer a domain name when the helper has a distinct meaning.
- Do not encode types in names (`user_map`, `name_string`) unless distinguishing representations is
  necessary (`raw_payload`, `decoded_payload`).

### 4.3 Database names

- PostgreSQL schemas, tables, columns, indexes, constraints, and SQL functions use unquoted,
  lowercase `snake_case` identifiers.
- Table names are plural; Ecto schema modules are singular.
- Foreign keys use `<singular_table>_id`.
- Boolean columns use a predicate or state name such as `active`, `verified`, or `archived_at`; do
  not prefix every boolean with `is_`.
- Constraint and index names MUST be deterministic and descriptive. Use these shapes unless Ecto's
  generated name is equally clear:

| Object | Convention | Example |
| --- | --- | --- |
| Primary key | `<table>_pkey` | `accounts_pkey` |
| Foreign key | `<table>_<column>_fkey` | `orders_account_id_fkey` |
| Unique constraint | `<table>_<columns>_unique` | `accounts_email_unique` |
| Check constraint | `<table>_<rule>_check` | `orders_total_non_negative_check` |
| Index | `<table>_<columns>_index` | `orders_account_id_inserted_at_index` |

Do not use quoted mixed-case SQL identifiers or PostgreSQL reserved words.

## 5. Functions and contracts

### 5.1 Arguments

- Put the primary data argument first so functions compose through `|>`.
- Required arguments are positional. Optional, non-essential behavior uses a final keyword list.
- Keyword options MUST have documented defaults and MUST NOT radically change a function's return
  type.
- Replace multiple booleans or confusable positional arguments with atoms, keyword options, or a
  named struct.
- Pattern-match in function heads when clauses represent genuinely different valid shapes. Do not
  expose internal representation through an overly specific public function head.
- Use guards for supported guard expressions that clarify accepted input. Do not reproduce complex
  business validation as guards.
- A public function with default arguments and multiple clauses MUST declare a function head.
- Do not use a default value to hide a required business decision.

### 5.2 Return values and errors

- Fallible public operations return `{:ok, value}` or `{:error, reason}`. Use `:ok` when no useful
  value exists.
- Expected “not found” behavior MUST be consistent within a context and documented: either `nil`,
  `:error`, or `{:error, :not_found}`. Mutation APIs SHOULD use tagged errors.
- Error reasons used by callers are stable atoms, tagged tuples, changesets, or documented error
  structs/maps—not presentation strings alone.
- Business-rule failures are data. Programmer errors, broken invariants, and unavailable required
  configuration MAY raise.
- A function MUST NOT return unrelated shapes based on hidden conditions or an option.
- Do not rescue all exceptions. Rescue only exceptions the current boundary can translate or
  recover from. Preserve the original stacktrace when re-raising.
- Do not use exceptions for ordinary branching, and do not silently convert unexpected exceptions
  to `{:error, :unknown}`.

### 5.3 Function size and visibility

- Default to `defp`. Make a function public only because another module has a legitimate contract
  with it, not to make private code directly testable.
- A function SHOULD operate at one level of abstraction. Extract a named function when a block has a
  distinct rule, repeated logic, complex branching, or a separately meaningful contract.
- Avoid arbitrary line-count targets. Reviewers MUST be able to state the function's responsibility
  in one sentence and follow its main path without decoding nested control flow.
- Prefer explicit, readable clauses to metaprogramming. A macro MUST remove unavoidable compile-time
  repetition or provide a real DSL; it MUST document generated behavior and caller requirements.

### 5.4 Types and behaviours

- Public context APIs, behaviours, boundary adapters, and reusable data structures MUST have
  typespecs unless the framework callback already provides the contract.
- Define and document public `@type`, `@opaque`, and `@typep` values near the top of the module.
- Use `@opaque` when callers must not rely on a representation.
- Callback implementations MUST use `@impl true` or `@impl Behaviour`.
- Struct modules SHOULD define `@type t() :: %__MODULE__{...}` when the struct crosses a module
  boundary.
- Typespecs MUST describe actual possible values. Do not add `term()` merely to silence Dialyzer.

## 6. Elixir syntax and idioms

### 6.1 Formatting

- `mix format` is authoritative. Formatted code is not manually aligned or reformatted to personal
  taste.
- The formatter line length is 98 unless an accepted repository-wide change updates it.
- Use parentheses for function calls with arguments. Omit them in idiomatic declarations and DSLs
  where the formatter and surrounding code do so.
- Do not align `=`, `=>`, or keyword values with manual whitespace.
- One-line function bodies are allowed for genuinely simple expressions. Multi-step logic uses
  `do`/`end` blocks.
- Semicolons are prohibited in application code.

### 6.2 Control flow

- Prefer pattern matching and multiple function clauses for structural distinctions.
- Use `case` when one value determines several branches.
- Use `cond` for multiple independent boolean conditions.
- Use `if`/`unless` only for a simple binary branch. Avoid `unless` with an `else` or a complex
  negative condition.
- Use `with` for a linear sequence of fallible operations sharing a success path. Every unmatched
  value MUST have a clear contract; use `else` only to translate errors, not to build a second large
  workflow.
- Do not nest `case`, `if`, or `with` deeply. Extract a function or add clauses when nesting obscures
  the main path.
- Use `Enum` for eager finite collections and `Stream` only when laziness or bounded memory is
  required.

### 6.3 Pipelines

- A pipeline MUST start with a real value and pass it as the first argument.
- Use a pipeline for a readable sequence of transformations. Do not pipe a single call solely for
  style, and do not create long pipelines that mix unrelated decisions and effects.
- Each stage SHOULD stay at a consistent abstraction level.
- Do not pipe into anonymous-function invocation or obscure argument reshuffling.
- Name an intermediate result when it aids debugging, documents a trust boundary, or is used more
  than once.

### 6.4 Data structures

- Use structs for domain values with a known shape and invariants; maps for dynamic keyed data;
  keyword lists for options; tuples for small tagged results.
- Access required map keys with dot syntax on structs or `map.key` where absence is a bug. Use
  `Map.fetch/2`, matching, or `Map.get/3` when absence is expected.
- External parameters keep string keys until explicitly cast. Never recursively atomize them.
- Prefer update syntax `%Struct{struct | field: value}` when the struct type and fields must already
  exist.
- Use `MapSet` for membership semantics instead of repeatedly scanning lists.
- Avoid process dictionaries for application data. Framework tracing metadata is an exception at a
  controlled boundary.

### 6.5 Comments and attributes

- Comments explain why, constraints, risk, or a non-obvious trade-off. They MUST NOT narrate clear
  code.
- TODO comments MUST include an issue reference and the condition for removal.
- Do not leave commented-out code; version control preserves history.
- Use module attributes for compile-time values. Do not hide environment-dependent runtime values in
  attributes.
- Suppression comments for static analysis follow the exception policy in
  [Enforcement](enforcement.md#exceptions-and-suppressions).

## 7. OTP, concurrency, and resilience

- Long-lived application processes MUST be in a supervision tree.
- `GenServer` state is ephemeral unless explicitly reconstructed from a durable source. It MUST NOT
  be the sole store for required business data.
- A process API MUST be encapsulated in its owning module. Callers MUST NOT scatter raw
  `GenServer.call/3`, `GenServer.cast/2`, or `Agent` access across the codebase.
- Use `call` when the caller requires success/failure or back-pressure. Use `cast` only when loss,
  ordering, and the absence of a reply are intentionally acceptable and documented.
- Every `call` MUST have a deliberate timeout. Infinite timeouts require a documented reason.
- `handle_call`, `handle_cast`, and `handle_info` SHOULD delegate business calculation to plain
  functions.
- Long or blocking work MUST NOT run inside a bottleneck process callback. Hand it to a supervised
  task or a durable job system as appropriate.
- Production tasks SHOULD run under `Task.Supervisor`. Every task must define ownership, timeout,
  failure propagation, and shutdown behavior.
- Never use `Process.sleep/1` for coordination. Use messages, monitors, timers, or explicit
  synchronization.
- Supervision strategy and restart intensity MUST reflect failure relationships. Do not use
  `:one_for_all` by habit.
- Child start order is a dependency declaration. Shutdown occurs in reverse order; resource owners
  MUST account for that lifecycle.
- Registry names MUST be scoped and intentional. Avoid globally named singleton processes when work
  can be partitioned or remain local.
- Distributed behavior MUST state consistency, partition, retry, and idempotency assumptions. Node
  connectivity alone is not a data-consistency design.

## 8. Phoenix and LiveView

### 8.1 Web boundaries

- Controllers, LiveViews, channels, and components translate transport data and delegate to
  contexts. They MUST NOT own business rules or direct database queries.
- Router pipelines own cross-cutting request concerns such as authentication, CSRF protection,
  secure headers, and content negotiation.
- GET and HEAD requests MUST be safe and MUST NOT change business state.
- Use verified routes (`~p`) for application paths and URLs.
- Renderers and templates MUST NOT perform database access, external calls, or hidden business
  calculations.
- HTTP status codes and error bodies are transport contracts. Translate domain errors once at the
  boundary and test the mapping.
- API input and output MUST use explicit serializers or JSON modules. Never expose a schema struct
  wholesale by convenience.

### 8.2 LiveView

- Every state-changing event MUST re-authorize the current actor and target resource. A hidden UI
  control is not authorization.
- Treat client event payloads, URL parameters, uploaded metadata, and reconnect state as untrusted.
- Use `assign_new/3`, temporary assigns, streams, and async work deliberately to control socket
  memory and rendering cost.
- `mount/3` and `handle_params/3` SHOULD load through contexts. `handle_event/3` SHOULD parse the
  command, call the context, and translate the result.
- Reusable function components MUST declare `attr` and `slot` contracts.
- Use HEEx attribute interpolation (`field={value}`), not string-built HTML. Raw HTML output requires
  explicit sanitization and security review.
- Stable DOM IDs are required for interactive or streamed elements.

### 8.3 Authentication and web security

- Authentication establishes identity; context-level authorization decides whether that identity
  may perform the requested operation. Both are required.
- Keep only minimal identifiers in sessions. Renew the session on privilege changes and login;
  clear it on logout.
- Keep Phoenix CSRF protection and secure browser headers enabled for browser pipelines. Any
  exception requires security review.
- Cookies carrying sensitive state MUST be signed or encrypted and configured with appropriate
  `Secure`, `HttpOnly`, and `SameSite` attributes.
- CORS origins MUST be an explicit allowlist. Wildcard or broad regular-expression origins are
  prohibited for credentialed or sensitive APIs.
- Outbound requests built from user-controlled URLs require SSRF defenses: allowed schemes,
  normalized host validation, DNS/IP checks, redirect revalidation, size/time limits, and blocked
  private or metadata networks unless explicitly required.
- File uploads require allowlisted types, server-generated names, size limits, and storage outside
  executable/static roots until validated.

## 9. Ecto conventions

### 9.1 Schemas and changesets

- Ecto schemas model persistence. Domain concepts that do not need persistence SHOULD use plain
  structs or data types.
- External input uses `cast/4` with an explicit allowlist of fields. Internal trusted changes use
  `change/2` or explicit struct construction.
- A client MUST NOT set ownership, authorization, audit, lifecycle, price, or other protected fields
  merely by submitting parameters. The server derives them from trusted context.
- Changesets validate input for useful feedback; PostgreSQL constraints enforce durable integrity.
  Race-sensitive rules such as uniqueness MUST have a database constraint and the matching Ecto
  constraint declaration.
- Split changesets by operation when permitted fields or invariants differ: for example,
  `registration_changeset/2` and `admin_changeset/2`.
- Use `prepare_changes/2` only for operations that must share the changeset transaction and cannot
  be expressed more clearly with constraints or `Ecto.Multi`.
- Associations are preloaded explicitly. Code MUST NOT rely on accidental preload state.
- Use `Ecto.Enum` or an explicit domain type for a closed state set. Storage representation and
  migration behavior MUST be documented; never let UI labels become stored state values.
- Store money as integer minor units or `Decimal` with an explicit currency. Never use floating
  point for monetary values.
- Use UTC instants for events and preserve a separate time-zone identifier when local civil time is
  a business input. Project schema and migration timestamp types MUST be consistent, normally
  `:utc_datetime_usec`/`timestamptz` semantics.

### 9.2 Queries and repositories

- `Actualis.Repo` access is limited to contexts and their internal persistence modules.
- Query functions SHOULD accept and return `Ecto.Queryable` values so filters compose.
- Bindings MUST be meaningfully named once a query has multiple joins. Use named bindings when
  composition depends on them.
- Select only the data needed for high-volume paths. Do not prematurely replace clear schema loads
  with partial maps on ordinary paths.
- Eliminate N+1 queries with deliberate joins, preloads, or batching. Query-count behavior for
  collection endpoints SHOULD be tested when regression risk is material.
- Every unbounded list exposed to a user or remote caller MUST be paginated or explicitly capped.
- Sort order MUST be deterministic when paginating.
- Dynamic identifiers or SQL fragments MUST use Ecto's supported parameter/identifier mechanisms.
  Never interpolate untrusted text into `fragment/1` or raw SQL.
- Raw SQL requires a documented reason, bound parameters, tests, and review of PostgreSQL-specific
  behavior.
- Query performance changes MUST be supported by representative `EXPLAIN (ANALYZE, BUFFERS)` evidence
  in a non-production environment when the query or data volume is material.

### 9.3 Transactions and consistency

- A transaction exists to protect one consistency boundary. Keep it short and free of network calls,
  sleeps, and expensive computation.
- Use `Repo.transact/2` for new code on Ecto versions that support it; use the version-pinned API
  consistently until an upgrade is complete.
- Use `Ecto.Multi` when named, composable operations and structured failure identify the workflow
  more clearly.
- Code MUST handle the documented transaction result, including the failed operation from a multi.
- Database constraint errors inside PostgreSQL abort the transaction. Model expected constraint
  failures through changeset constraint functions or roll back immediately; do not continue issuing
  queries in an aborted transaction.
- Choose optimistic locking, row locks, advisory locks, or serializable transactions based on the
  invariant. “Read, check, then write” without protection is not safe under concurrency.
- Operations that may be retried MUST be idempotent or have an idempotency key and a unique
  constraint that enforces it.

## 10. PostgreSQL conventions

### 10.1 Data integrity

- The database is the final authority for persisted invariants. Use `NOT NULL`, foreign keys,
  unique constraints, check constraints, exclusion constraints, and appropriate data types.
- Nullability MUST represent meaningful absence, not incomplete design.
- Every foreign key MUST declare intentional update/delete behavior. Application cascade callbacks
  are not a substitute for database integrity.
- Every referencing foreign-key column SHOULD have an index unless write cost and query evidence
  justify omission. PostgreSQL does not automatically create that index.
- Use `text` unless a real maximum length is a business invariant; then enforce the invariant in the
  database and changeset.
- Prefer `timestamptz` for instants, `date` for calendar dates, and `numeric` or integer minor units
  for exact quantities. Do not store dates or numbers as text.
- Use `jsonb` for genuinely flexible documents or external payload snapshots. Frequently filtered,
  joined, constrained, or independently updated fields belong in typed columns/tables.
- Primary-key strategy MUST be consistent across a bounded area. Any move to UUIDv7, bigint, or
  another scheme requires an ADR covering ordering, exposure, index locality, and migration.
- Tenant isolation MUST be enforced at every query boundary. If row-level security is used, policies,
  role privileges, owner bypass, and background-job behavior require dedicated tests.

### 10.2 Indexes and performance

- Create indexes from observed access paths, constraints, or a documented forecast. Every index has
  write and storage cost.
- Match multicolumn index order to equality, range, sorting, and selectivity needs. Do not assume two
  single-column indexes equal a purposeful composite index.
- Use unique constraints for uniqueness; use partial, expression, GIN, GiST, or covering indexes
  only with a documented query they serve.
- New or changed critical queries MUST be assessed with representative statistics and data volume.
- Production monitoring MUST cover slow queries, connection-pool saturation, lock waits, deadlocks,
  replication lag where applicable, and table/index growth.
- Do not add query hints through unsafe fragments as a default response to a planning problem.

### 10.3 Migrations

- A migration applied to any shared environment is immutable. Fix it with a new migration.
- Migrations MUST be safe for rolling deployment where old and new application versions overlap.
  Use expand/backfill/switch/contract for incompatible schema changes.
- Destructive changes—drop, rename, type rewrite, new non-null field with table rewrite, or constraint
  validation over large data—require an explicit rollout and rollback plan.
- Prefer reversible `change/0` only when Ecto can genuinely reverse the operation. Otherwise define
  and test `up/0` and `down/0`.
- A migration MUST NOT call evolving application context or schema code. Use migration-local modules
  or SQL so historical migrations remain executable.
- Separate schema change from large data backfill. Backfills MUST be bounded, resumable, observable,
  and safe to retry.
- Set deliberate `lock_timeout` and, where appropriate, `statement_timeout` for production
  migrations. Do not let a deployment wait indefinitely for a destructive lock.
- Build large-table indexes concurrently. With Ecto/PostgreSQL, isolate the index operation, disable
  its DDL transaction, and retain a safe single-run migration lock such as the supported PostgreSQL
  advisory strategy when infrastructure permits. Disabling the migration lock requires guaranteed
  single-node execution.
- Add expensive constraints as not-valid where supported, backfill, then validate separately. The
  rollout MUST still enforce new writes.
- Adding a required column usually follows: add nullable or safe default, deploy dual-compatible
  code, backfill, validate, then set `NOT NULL` and remove transitional behavior.
- Every migration PR MUST state lock risk, table size/traffic assumption, mixed-version compatibility,
  rollback/roll-forward path, and backfill plan.

## 11. Configuration, dependencies, and secrets

- Version control contains non-secret defaults. Production secrets and deployment-specific values
  are loaded at runtime and MUST NOT be committed, compiled into modules, logged, or embedded in
  images.
- Required configuration MUST fail fast with a specific error during startup.
- Use `Application.compile_env/3` only for values intentionally fixed at compile time. Runtime values
  use runtime configuration.
- Environment branches MUST stay in configuration files or boundary modules, not throughout domain
  code.
- Dependency additions require a stated purpose, maintenance/security review, license compatibility,
  and comparison with standard-library or existing-dependency capability.
- Pin reproducible dependency versions in `mix.lock`. Automated updates still require release-note,
  test, and migration review.
- Do not call undocumented dependency internals or pattern-match private struct fields.

## 12. Security and privacy in all code

- Validate at trust boundaries and encode at output boundaries. Validation does not replace output
  encoding.
- Authorization is deny-by-default and MUST cover reads, writes, exports, subscriptions, and
  background actions.
- Use parameterized Ecto queries. SQL, shell, HTML, path, URL, and header construction each require
  their context-appropriate safe API.
- Passwords, tokens, session material, authorization headers, private keys, secrets, and sensitive
  personal data MUST NOT appear in logs, telemetry metadata, exception messages, fixtures, or source
  control.
- Schemas containing sensitive fields SHOULD use Ecto redaction, and Logger metadata filters MUST be
  configured centrally.
- Use constant-time comparison for secrets where the library provides it.
- Cryptography MUST use established Erlang/Elixir libraries and approved algorithms. Do not design
  custom cryptographic formats.
- Error responses reveal only what the caller is authorized to learn. Internal logs keep diagnostic
  context without exposing secrets.
- Data collection, retention, deletion, and export behavior MUST follow documented privacy rules.

## 13. Logging, telemetry, and operations

- Logs are structured events with stable messages and metadata. Prefer `Logger` metadata to string
  interpolation of identifiers.
- Include correlation/request ID, operation, relevant safe entity IDs, outcome, and error class at
  boundaries where useful. Never log entire params, changesets, payloads, or structs by default.
- Log at the layer that can add meaning. Avoid logging and re-logging the same error at every layer.
- `:debug` is diagnostic detail; `:info` is a meaningful lifecycle or business event; `:warning` is
  degraded but handled behavior; `:error` requires investigation or represents failed service.
- Expected validation failures are not application errors.
- Emit Telemetry events for important latency, throughput, failure, queue, and business outcomes.
  Event names are stable lists of atoms; measurements are numeric; metadata cardinality is bounded.
- External calls MUST set connect and receive timeouts and define retry behavior. Retry only safe or
  idempotent operations, with bounded exponential backoff and jitter.
- Health checks MUST distinguish process liveness from dependency readiness.

## 14. Testing conventions

- Tests verify observable behavior and contracts, not private implementation steps.
- Every business rule MUST have tests for success, expected failure, boundary values, and relevant
  authorization or concurrency behavior.
- Context tests own business and persistence behavior. Web tests own routing, authentication,
  transport mapping, and rendering. Pure domain tests MUST NOT require the database.
- Use ExUnit names that describe behavior: `test "rejects activation after expiry"`.
- Test files mirror source ownership. Use `describe` with the public function and arity when that
  improves navigation.
- Prefer explicit setup data and small builders. Factories MUST produce valid minimal records and
  make important differences visible at the call site.
- Tests MUST be deterministic. Do not depend on wall-clock time, random ordering, external networks,
  global mutable state, or `Process.sleep/1`.
- Inject or freeze time/randomness at an explicit boundary when behavior depends on it.
- Use `async: true` whenever isolation permits. Database tests use the Ecto SQL sandbox correctly;
  tests requiring shared process ownership declare why they cannot be async.
- Assert messages with `assert_receive`/`refute_receive` and deliberate timeouts. Monitor process
  lifecycle rather than sleeping.
- Test both Ecto validation feedback and PostgreSQL constraint enforcement for critical invariants.
- Doctest public examples that are deterministic and valuable as executable contracts.
- Avoid exact assertion of unstable presentation details unless they are the contract.
- Bug fixes MUST include a regression test that fails for the defect.
- High-risk workflows SHOULD include property, state-machine, concurrency, or integration tests when
  example tests cannot cover the invariant convincingly.

## 15. Review checklist

Every reviewer checks, as applicable:

- Is the rule in the right context or kernel module, and is dependency direction preserved?
- Are names and contracts explicit, stable, and consistent with neighboring APIs?
- Are expected errors modeled and unexpected errors allowed to remain observable?
- Are authorization, untrusted input, secrets, and privacy handled at every boundary?
- Are database constraints, indexes, transaction semantics, and concurrency races addressed?
- Is a migration safe for real data, locks, and mixed-version deployment?
- Are process ownership, supervision, timeouts, and back-pressure deliberate?
- Are logs and telemetry useful, safe, and bounded in cardinality?
- Do tests demonstrate the important behavior and failure modes?
- Does documentation explain the contract, decision, and operational impact?

# Actualis documentation conventions

Status: **Normative**  
Applies to: **code documentation, Markdown, diagrams, APIs, ADRs, runbooks, and change notes**

## 1. Documentation principles

Actualis documentation is part of the product and the engineering contract. It MUST be correct,
owned, discoverable, secure, and updated in the same change as the behavior it describes.

Documentation MUST answer the reader's likely question before explaining background. It SHOULD be
as short as possible while still making correct use and safe operation clear.

### 1.1 Audience and purpose

Before writing, identify:

- the primary reader;
- the task or decision the document supports;
- prerequisites the reader can reasonably have;
- the owner and the condition that makes the document stale.

A document MUST NOT mix tutorial, reference, explanation, and operational procedure so heavily that
the reader cannot tell what to do. Split it or make the sections explicit.

### 1.2 Normative language

Use **MUST**, **SHOULD**, and **MAY** only for real requirements as defined in the
[engineering standards index](README.md#normative-language). Use ordinary prose elsewhere.

## 2. Required documentation set

The application repository MUST provide these artifacts when applicable:

| Artifact | Purpose | Update trigger |
| --- | --- | --- |
| `README.md` | First successful local run and map to deeper docs | Setup or entry-point change |
| Architecture overview | Boundaries, dependency direction, data flow, runtime topology | Material architecture change |
| Context/API docs | Supported business capabilities and contracts | Public contract change |
| ADRs | Durable record of consequential decisions and trade-offs | Decision accepted/superseded |
| Database/migration notes | Data model, risky migrations, backfills, recovery | Schema or rollout change |
| Runbooks | Detection, diagnosis, mitigation, recovery, verification | Operational behavior change |
| Security/privacy docs | Trust boundaries, sensitive data, retention, incident paths | Threat or control change |
| Changelog/release notes | User/operator-visible changes and required actions | Release |

Generated API reference complements narrative documentation; it does not replace it.

## 3. Repository organization

Use a predictable structure such as:

```text
README.md
docs/
  architecture/
    overview.md
    decisions/
      0001-short-decision-title.md
  development/
    setup.md
    testing.md
  operations/
    deployment.md
    runbooks/
  security/
  reference/
```

- Each topic has one canonical page. Other pages link to it rather than copying it.
- The root README is a concise gateway, not a complete manual.
- Documentation filenames use lowercase `kebab-case.md`. ADRs start with a zero-padded sequence.
- Images and diagrams live beside the owning document or in its local `assets/` directory.
- Links within the repository SHOULD be relative so they work in branches and local checkouts.
- A moved or renamed page MUST update inbound links in the same change.

## 4. Markdown style

### 4.1 Structure

- Use one level-one ATX heading (`#`) matching the document title.
- Use sentence case for headings. Do not skip heading levels.
- Begin with the outcome, purpose, or action. Do not open with a long history.
- Keep sections focused and independently linkable.
- Use numbered lists for ordered procedures and bullets for unordered sets.
- Use a table only when readers compare the same fields across several items.
- Use block quotes only for quoted material; use a `Note`, `Warning`, or `Danger` label for callouts.
- Add a table of contents only for long reference pages where it materially improves navigation.

### 4.2 Text and formatting

- Write in clear international English, active voice, and present tense.
- Address the reader as “you” in procedures. Use “we” only for Actualis decisions or shared actions.
- Prefer concrete verbs and domain terms over jargon, idioms, and marketing language.
- Define an acronym on first use unless it is universally familiar to the intended audience.
- Use one canonical spelling and capitalization for every product and domain concept.
- Wrap prose near 100 characters when manual editing makes that practical. Do not hard-wrap tables,
  URLs, or content where wrapping harms readability.
- Use **bold** sparingly for interface labels or critical emphasis, backticks for code identifiers,
  values, paths, commands, and configuration keys, and italics only when normal prose is unclear.
- Do not use all caps for emphasis.
- Avoid “simply,” “obviously,” “just,” and “easy”; they do not help a blocked reader.
- Examples MUST use safe, non-production domains, credentials, identifiers, and personal data.

### 4.3 Links and references

- Link descriptive text, not “here” or a bare URL.
- Link to the narrowest stable primary source.
- State the supported version when behavior is version-specific.
- Do not copy large passages from external documentation. Explain the Actualis decision and link to
  the source.
- External facts that can change SHOULD include a source and review date.
- Every link MUST resolve in continuous integration.

### 4.4 Code and command examples

- Fenced code blocks MUST declare a language such as `elixir`, `heex`, `sql`, `json`, `shell`, or
  `text`.
- Commands MUST distinguish shell input from output. Prefer separate blocks or comments that cannot
  be pasted accidentally.
- Examples MUST be minimal but complete enough to run or adapt without guessing omitted safety
  steps.
- Never use real secrets, production hostnames, customer information, or destructive production
  commands.
- Mark placeholders consistently with descriptive uppercase values such as `ACCOUNT_ID`; explain
  them before use.
- Show expected output when it confirms success or helps diagnose failure.
- Test code examples as doctests or through an example test whenever practical.
- An ellipsis (`...`) is allowed only when the omitted portion is irrelevant and omission cannot hide
  a required step.

## 5. Elixir code documentation

Elixir documentation is an API contract. Comments describe implementation decisions; they are not a
substitute for `@moduledoc`, `@doc`, `@typedoc`, or typespecs.

### 5.1 Modules

- Every production module MUST have a meaningful `@moduledoc` or an intentional
  `@moduledoc false`.
- Public contexts, domain modules, behaviours, adapters, and reusable components MUST have a
  meaningful `@moduledoc`.
- A module document begins with one concise summary paragraph. It then explains responsibility,
  boundaries, important invariants, and usage where needed.
- State what the module owns and what it deliberately does not own when boundary confusion is
  likely.
- `@moduledoc false` marks a module as outside the supported public documentation surface; it does
  not make public functions private. Use `defp` for functions that are not contracts.

Example:

```elixir
defmodule Actualis.Billing do
  @moduledoc """
  Provides the public API for invoicing and payment allocation.

  This context owns invoice lifecycle rules. It does not collect payment details or render
  customer-facing documents.
  """
end
```

### 5.2 Functions, callbacks, and types

- Every public context function and supported public API MUST have `@doc` and a typespec.
- A public function document starts with a concise verb phrase describing its outcome.
- Document accepted input, authorization assumptions, return values, expected errors, side effects,
  idempotency, ordering, and concurrency behavior when they are part of the contract.
- Do not repeat information already expressed clearly by the name and typespec.
- Refer to local functions as `function/arity`, external functions by full module and arity such as
  `Actualis.Billing.issue_invoice/2`, callbacks with `c:callback/arity`, and types with
  `t:type/arity`.
- Document a multi-clause function once, before its first clause. Add a public function head when
  needed to give documentation clear argument names.
- Callback implementations use `@impl true`; do not copy the behaviour's documentation unless the
  implementation adds material guarantees or limitations.
- Public types use `@typedoc`. Opaque types explain how callers create and use them without exposing
  representation.
- Deprecated APIs use both `@deprecated` and documentation metadata with the replacement and a
  migration path.
- Use documentation `:since` metadata for versioned reusable APIs when the project maintains that
  history.

### 5.3 Examples and doctests

- Include `## Examples` when an example clarifies normal use, transformations, edge cases, or a
  non-obvious return shape.
- Deterministic examples SHOULD be doctested.
- Doctests are contract examples, not a replacement for comprehensive tests.
- Do not doctest examples that rely on wall-clock time, random data, external systems, process timing,
  or unstable formatting unless those dependencies are controlled.
- Examples SHOULD demonstrate the safe public API, not private setup or direct persistence access.

Example:

```elixir
@doc """
Calculates the amount still due on an invoice.

Returns `{:error, :overallocated}` when allocations exceed the invoice total.

## Examples

    iex> Actualis.Billing.amount_due(1_000, [250, 300])
    {:ok, 450}

"""
@spec amount_due(non_neg_integer(), [non_neg_integer()]) ::
        {:ok, non_neg_integer()} | {:error, :overallocated}
```

### 5.4 Comments

- A comment explains intent, risk, a surprising constraint, or why the obvious approach is wrong.
- Comments MUST remain adjacent to the code they qualify.
- Write complete sentences for sentence-length comments.
- Do not duplicate tickets, narrate syntax, record authorship, or preserve disabled code in comments.
- TODO/FIXME comments require a tracked issue and an actionable removal condition.
- Security-sensitive workarounds and static-analysis suppressions MUST explain the threat or false
  positive and link to a decision or issue when the reason is not local.

## 6. Architecture documentation

The architecture overview MUST describe:

- business capabilities and context boundaries;
- dependency direction and the functional core/effect boundaries;
- runtime components, supervision ownership, queues, and external systems;
- authoritative data stores and consistency boundaries;
- authentication, authorization, and trust boundaries;
- important synchronous and asynchronous flows;
- deployment topology and major failure modes;
- links to ADRs and runbooks.

Diagrams MUST have a textual explanation, a clear scope, labeled boundaries and arrows, and a source
format stored in version control. A diagram is not useful if its symbols or ownership are implicit.

## 7. Architecture decision records

Create an ADR for a decision that is expensive to reverse, crosses boundaries, introduces a durable
dependency, changes data or consistency strategy, or establishes a standard.

Use this template:

```markdown
# NNNN: Decision title

Status: Proposed | Accepted | Superseded by ADR-NNNN | Deprecated
Date: YYYY-MM-DD
Owners: Team or role

## Context

What forces and constraints require a decision?

## Decision

What will we do? State the boundary and scope precisely.

## Consequences

What becomes easier, harder, risky, or deliberately unsupported?

## Alternatives considered

What credible alternatives were rejected, and why?

## Validation and review

How will we know the decision works, and what would trigger reconsideration?
```

- ADRs are immutable after acceptance except for status, links, and correction of obvious errors.
- A changed decision gets a new ADR that supersedes the old one.
- An ADR records the decision and trade-offs, not a transcript of discussion.

## 8. Runbooks

Every production-critical service or failure mode MUST have a runbook that contains:

1. purpose, scope, owner, and severity/impact;
2. prerequisites and access required;
3. alerts or symptoms and how to verify them;
4. safe diagnostic steps in order;
5. mitigation with explicit stop/escalation conditions;
6. recovery and rollback/roll-forward steps;
7. verification of user impact and data integrity;
8. communication and escalation contacts by role, not a fragile personal name;
9. follow-up evidence to capture;
10. last-tested date.

Commands MUST be safe to paste into the stated environment. Destructive steps require a warning,
exact target resolution, backup/recovery note, and explicit confirmation point.

Runbooks SHOULD offer read-only diagnosis before state-changing mitigation. They MUST NOT assume the
reader knows unstated cluster, tenant, region, or database context.

## 9. API and event documentation

HTTP APIs, messages, and domain events MUST document:

- purpose and owning context;
- authentication and authorization;
- request/event schema with required, optional, nullable, and constrained fields;
- response or consumer contract;
- stable error codes and retryability;
- idempotency and deduplication behavior;
- ordering, delivery, and versioning guarantees;
- examples with safe data;
- deprecation and migration policy.

OpenAPI, AsyncAPI, or generated schema files SHOULD be derived from or verified against executable
contracts. Generated files MUST NOT be hand-edited without a documented generation process.

### 9.1 Actualis contract files

- Capability contracts live under `contracts/capabilities/`; event contracts live under
  `contracts/events/`.
- Filenames use the stable contract identifier and major version, for example
  `manufacturing.move_pallet.v0.json` and `manufacturing.pallet_moved.v1.json`.
- JSON contracts use JSON Schema 2020-12 unless an accepted ADR changes the format. Every object
  schema MUST state `additionalProperties` deliberately, including nested objects.
- A contract MUST define field types, formats, required/optional status, nullability, bounds, enums,
  descriptions, and representative safe examples where applicable.
- Published event versions are immutable. Backward-compatible additions follow the contract's
  compatibility policy; a breaking change creates a new major version and documents consumer
  migration and coexistence.
- Capability `v0` means experimental and may change only while every caller is controlled and the
  change is coordinated. Promotion to `v1` freezes the compatibility contract.
- The OpenAPI document, JSON Schema files, runtime validation, and serialized examples MUST agree.
  CI SHOULD validate examples and detect drift between them.
- Contract documentation MUST state identity injection, purpose/scope authorization, idempotency,
  expected-version concurrency, stable error codes, evidence linkage, and retry/replay behavior.

## 10. Database and migration documentation

A schema-changing pull request MUST include:

- the invariant or access path being changed;
- affected tables, estimated size, and traffic assumption;
- lock and rewrite risk;
- old/new application compatibility during rolling deployment;
- backfill method, batch control, observability, pause/resume, and retry behavior;
- rollback or roll-forward plan;
- verification queries and data-integrity checks.

Data dictionaries SHOULD explain business meaning, units, null semantics, sensitivity class, source
of truth, and retention—not merely repeat SQL types.

## 11. Change and review discipline

- Code and its documentation MUST change together in one pull request.
- Reviewers verify commands, examples, links, versions, security, and operational claims—not only
  grammar.
- A document with a named owner MUST be reviewed by that owner or delegated role after a material
  change.
- Documentation debt uses the normal issue tracker with owner and priority; a TODO in prose is not a
  maintenance system.
- Scheduled reviews are REQUIRED for runbooks and security/privacy documents. Review frequency is
  risk-based, at least annually, and after every relevant incident.
- Stale documentation is fixed or deleted. Do not label it “outdated” indefinitely while leaving it
  discoverable as guidance.

## 12. Documentation review checklist

- Does the first paragraph state the outcome, purpose, or decision?
- Is the intended reader able to act without guessing prerequisites or omitted safety steps?
- Does one canonical page own the topic, with working links from related pages?
- Are domain terms, names, paths, versions, and commands exact?
- Are examples runnable, safe, and free of secrets or personal data?
- Are code contracts documented with `@moduledoc`, `@doc`, typespecs, and useful doctests?
- Are failure, authorization, concurrency, migration, and recovery semantics documented where
  relevant?
- Is the owner clear, and is there an objective trigger for updating the page?

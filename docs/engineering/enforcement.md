# Actualis standards enforcement

Status: **Normative**  
Applies to: **all changes merged into protected branches**

## 1. Enforcement model

Consistency comes from four layers:

1. the formatter removes syntax-style debate;
2. compilation and static analysis reject detectable defects;
3. tests and database checks verify behavior and integrity;
4. review checks architecture, semantics, production safety, and documentation that tools cannot
   understand.

A pull request MUST NOT merge with a failed required check. Direct pushes to protected branches are
prohibited. The same quality command MUST run locally and in continuous integration (CI).

The repository's current `mix quality` alias enforces formatting, unused-lock detection,
warnings-as-errors compilation, and tests. Credo, Dialyzer, ExDoc, dependency auditing, Sobelow,
Markdown, and link checks in the full contract below are REQUIRED before the production readiness
gate. Until each is installed and added to `mix quality`, its rule remains a mandatory review check.

## 2. Required local quality command

The application MUST expose one alias, normally `mix quality`, that performs the repository's full
merge gate without modifying tracked files.

At the production readiness gate, it runs the equivalent of:

```elixir
defp aliases do
  [
    quality: [
      "format --check-formatted",
      "deps.unlock --check-unused",
      "compile --warnings-as-errors",
      "credo --strict",
      "test",
      "dialyzer",
      "docs --warnings-as-errors"
    ]
  ]
end
```

The exact alias MAY use a project task or script to start PostgreSQL and combine frontend,
documentation, migration, dependency, and security checks. It MUST preserve the checks' failure
status and print which gate failed.

Commands that rewrite files, such as bare `mix format`, belong in a separate developer convenience
alias and MUST NOT hide a dirty working tree in CI.

## 3. Mandatory automated gates

| Gate | Required result | Typical enforcement |
| --- | --- | --- |
| Elixir format | All `.ex`, `.exs`, HEEx, and configured files are formatted | `mix format --check-formatted` |
| Compilation | No compiler or dependency usage warnings attributable to the app | `mix compile --warnings-as-errors` |
| Unit/integration tests | All tests pass with deterministic seed reporting | `mix test` |
| Static code analysis | No unapproved strict findings | `mix credo --strict` |
| Type analysis | No unexplained Dialyzer warnings | `mix dialyzer` |
| Dependency hygiene | No unused locks or prohibited vulnerable/retired dependencies | Mix/Hex audit tasks |
| Security analysis | No untriaged high-confidence Phoenix finding | Sobelow or approved equivalent |
| Documentation build | No unresolved application documentation warnings | `mix docs --warnings-as-errors` |
| Markdown quality | Style, duplicate heading, and broken link checks pass | markdownlint and link checker |
| Frontend quality | Formatter, lint, type check, and tests pass when assets exist | package-manager locked commands |
| Database migrations | Clean build and full historical upgrade succeed on supported PostgreSQL | ephemeral CI database |

The repository MUST pin tool versions. A tool upgrade is a code change and must be reviewed.

Security and dependency scanners do not independently decide whether a risk is acceptable. A human
must validate reachability, impact, compensating controls, and remediation deadline.

## 4. Formatter baseline

The application `.formatter.exs` MUST include every maintained Elixir, test, configuration, migration,
and HEEx path. For a standard Phoenix application, start from:

```elixir
[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  subdirectories: ["priv/*/migrations"],
  inputs: [
    "*.{ex,exs,heex}",
    "{config,lib,test}/**/*.{ex,exs,heex}",
    "priv/*/seeds.exs"
  ],
  line_length: 98
]
```

Dependency versions may require different plugin or `import_deps` settings. The pinned framework's
generated configuration is the starting point; the required outcome is complete, deterministic
coverage.

Generated code MUST be formatted before review.

## 5. Credo and boundary checks

Credo runs in strict mode with version-controlled configuration. The team MUST triage every enabled
check. Do not enable a stylistic rule that fights `mix format` or these standards.

At minimum, static policy MUST detect or review:

- cyclomatic/nesting complexity that obscures control flow;
- unsafe or unbounded atom creation;
- debug output and commented code;
- broad exception rescue and discarded errors;
- inconsistent names, predicates, and TODOs;
- direct `Repo` use from `ActualisWeb` and other interface layers;
- direct calls to another context's internal schema/query modules;
- unparameterized SQL or unsafe fragments;
- application processes started outside the supervision tree.

Credo does not know all architecture semantics. Use a small custom Mix task, architecture tests,
or `mix xref` analysis for dependency rules that can be expressed mechanically. Keep the allowlist
short and owned.

## 6. Test and coverage policy

- CI runs tests against every supported OTP/Elixir combination required by the version policy. The
  main protected check runs the production deployment combination.
- CI reports the random seed so failures can be reproduced.
- Changed code MUST have behavior-level tests proportional to risk.
- A project-wide numeric coverage target MAY be set, but it MUST NOT replace review of critical
  business, authorization, concurrency, and migration paths.
- Critical contexts SHOULD enforce a higher branch or mutation-testing expectation when ordinary
  line coverage gives false confidence.
- Flaky tests are defects. A test MAY be quarantined only with an owner, issue, evidence, and short
  removal deadline. Quarantine MUST remain visible in CI.
- Tests MUST NOT access uncontrolled public networks.

## 7. Database and migration gates

CI MUST create an empty database on the supported PostgreSQL version and apply the full migration
history. When the project maintains a structure dump, CI also verifies that regeneration produces no
unexpected diff.

For migration changes, CI or a pre-production rehearsal MUST verify as applicable:

1. upgrade from the current production schema and representative data;
2. old application compatibility after the expand step;
3. new application compatibility before the contract step;
4. rollback or documented roll-forward;
5. constraint validation and expected indexes;
6. bounded/resumable backfill behavior;
7. lock duration and query plan on representative table sizes.

A migration touching a large or hot table requires a human “migration safety” approval. The approver
checks the migration section of the [coding conventions](coding-conventions.md#103-migrations) and
the required [database documentation](documentation-conventions.md#10-database-and-migration-documentation).

## 8. Documentation gates

CI MUST:

- build ExDoc and fail on unresolved application references or documentation warnings;
- run doctests selected by the test suite;
- lint maintained Markdown with a version-controlled configuration;
- check internal links, anchors, and approved external links;
- reject secrets and known sensitive-data patterns in prose and examples;
- verify generated API specifications are current when generation is deterministic.

Review remains responsible for accuracy, audience fit, operational safety, and whether the document
actually describes the changed behavior.

## 9. Pull request requirements

Every pull request MUST state:

- the problem and user/operational outcome;
- the affected context or boundary;
- how the change was verified;
- security, privacy, authorization, data, concurrency, and observability impact, or “not applicable”
  with a credible reason;
- migration and rollout/rollback impact when state or contracts change;
- documentation added or updated.

Required reviewers are ownership-based. Changes to authentication/authorization, cryptography,
sensitive data, tenant isolation, money, irreversible migrations, or public contracts require the
corresponding domain/security/data owner.

Generated files, vendored assets, and mechanical formatting SHOULD be isolated from semantic changes
when practical so review remains trustworthy.

## 10. Exceptions and suppressions

An exception is allowed only when following the rule would reduce correctness, security,
operability, or clarity in the specific case.

- Use the narrowest possible suppression: one expression or one file, never a broad directory or
  global disable by convenience.
- The adjacent comment MUST identify the exact rule/tool, explain why it is a false positive or
  justified trade-off, and link to a tracking issue when temporary.
- Security, type, and migration suppressions require a second qualified reviewer.
- Temporary exceptions need an owner and expiry/removal condition.
- CI configuration MUST fail on newly introduced unowned baseline findings. Existing debt is tracked
  explicitly; it is not silently grandfathered.
- Repeated suppressions indicate a rule or design problem and trigger standards review.

Do not suppress compiler warnings. Fix them or deliberately change the version/configuration that
causes them.

## 11. Definition of done

A change is done only when:

1. behavior and failure modes meet the requested outcome;
2. context/kernel boundaries remain valid;
3. authorization, data integrity, concurrency, and operational risks are addressed;
4. formatter, compiler, tests, analysis, security, dependency, docs, and migration gates pass;
5. logs, telemetry, dashboards, and alerts are updated where operational behavior changes;
6. code docs, repository docs, ADRs, runbooks, API specs, and release notes are updated as applicable;
7. rollout, rollback/roll-forward, and verification are credible;
8. no unexplained warning, skipped test, suppression, TODO, or documentation gap remains.

## 12. Adoption sequence

When these standards are introduced into an existing repository:

1. pin runtime and tool versions;
2. add formatter coverage and make formatting a dedicated mechanical change;
3. establish a green compile-and-test baseline;
4. add Credo, Dialyzer, dependency, security, ExDoc, Markdown, and link gates one at a time;
5. record existing findings with owners rather than hiding them in global ignores;
6. add enforceable architecture and migration-safety checks;
7. protect the main branch and require the unified quality check;
8. remove the temporary baseline as findings are fixed.

New and changed code MUST comply from the first day of adoption. Legacy cleanup SHOULD be incremental
unless an active correctness or security issue requires immediate remediation.

# Phase 0 evaluations

These artifacts turn Phase 0 hypotheses into repeatable inputs. They contain synthetic data only and
must not be mixed with exported customer or production records.

## Command-path smoke benchmark

Prepare the test database, then run:

```sh
MIX_ENV=test mix test
MIX_ENV=test mix run evals/phase0/benchmark.exs --commands 100 --concurrency 4
```

The harness creates one isolated synthetic fixture per worker, alternates a pallet between two
locations, and measures the complete in-process governed command path. Results are printed as JSON.
The SQL sandbox rolls every worker's data back.

This does not measure HTTP connections, realtime fan-out, browser sync, telemetry ingest, external
delivery, backup, or recovery. Record those as `not_run` until representative adapters exist.

## Artifact rules

- Keep workload units explicit and versioned.
- Use only fictional identifiers and labels.
- Record environment and topology with every retained result.
- Never compare candidate technologies using different datasets or query mixes.
- Never convert a laptop smoke result into a production SLO claim.

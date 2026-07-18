# Contributing

## Before coding

Every change must name the operational journey, owner, failure mode, and quality scenario it serves. New platform components also require an ADR, an SLO, a security boundary, a recovery story, and an exit path.

## Change workflow

1. Add or update the relevant contract and ADR.
2. Implement the smallest vertical change that preserves module ownership.
3. Add positive, negative, boundary, idempotency, and authorization tests.
4. Verify migration compatibility and evidence output.
5. Run the affected quality scenario.
6. Open a pull request using the repository template.

## Required review perspectives

- Domain correctness and operational ownership
- Authority, privacy, and evidence
- Contract and migration compatibility
- Surface behavior, accessibility, and offline implications
- Reliability, observability, and recovery

Language-specific formatting, linting, testing, and supply-chain checks will be added to CI when each runtime is introduced.

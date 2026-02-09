# ADR-0012: Payment Finality Model (Deferred Enforcement)

## Status
Phase-0 ADR stub (roadmap-backed). No Phase-0 schema enforcement.

## Invariants
- Roadmap invariant: `INV-114` (alias: `INV-BOZ-04`)

## Decision
Symphony will model **payment finality** as an explicit, mechanically enforced state machine in Phase-1:
- Once an instruction is finalized on a settlement rail, the system must physically prevent cancel/void transitions.
- Only a regulated reversal workflow may alter the effective outcome, using ISO 20022 reversal semantics (e.g., camt.056).

Phase-0 declares the requirement and the activation criteria, but does not change the Phase-0 schema.

## Rationale
Finality is a P0-impact requirement (legal/regulatory exposure). However, enforcing finality requires:
- rail adapters that can assert "committed to rail" deterministically,
- a reversal workflow model (camt.056) and audit artifacts,
- and a phase boundary that avoids retrofitting legal semantics into Phase-0 foundation tables.

Declaring this as a roadmap invariant in Phase-0 provides audit line-of-sight without creating premature schema coupling.

## Phase-0 Boundary
Phase-0 guarantees:
- append-only attempt ledger history,
- deterministic idempotency and lease fencing,
- and migration immutability.

Phase-0 does not guarantee:
- legal payment finality semantics,
- cancel/void prevention (because cancel/void is not yet modeled),
- ISO 20022 reversal execution.

## Activation Preconditions (Phase-1)
Enforcement is promoted from roadmap -> implemented when all of the following exist:
- Rail adapter records a durable "rail accepted/committed" signal.
- A reversal workflow exists and is the only allowed mechanism to change the effective outcome.
- Mechanical DB enforcement exists (constraints/triggers) and CI tests prove it.

## Intended Phase-1 Enforcement (Design Outline)
Schema changes (forward-only, expand-first):
- Add a finality flag/state to the instruction/outbox domain (exact table to be decided in Phase-1 once rail adapters exist).
- Add mechanical constraints/triggers that prevent forbidden transitions.

Mechanical checks required for promotion:
- DB: constraint/trigger exists and blocks forbidden finality violations.
- DB: tests that attempt prohibited transitions fail closed.
- Integration: dispatch success records finality anchors and reversal workflow emits a new, auditable reversal record.

## Failure Modes (What Must Become Impossible)
- "Zombie reversals": cancel/void after rail-commit without reversal workflow.
- Liquidity mismatch caused by post-finality mutation of the canonical instruction outcome.
- Operator path that bypasses the reversal-only gate.

## Audit Artifacts (Phase-1+)
- Evidence pack showing:
  - finality enforcement definition,
  - reversal workflow execution evidence,
  - and detected breach reporting (should be zero).

## Open Questions (Phase-1)
- Which table represents the canonical instruction outcome: pending/outbox, a dedicated instruction ledger table, or an evidence pack anchor table?
- What constitutes "rail committed" for each rail profile (e.g., NFS/ZIPSS)?

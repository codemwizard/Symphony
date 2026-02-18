# Phase-1 Contract

This contract governs Phase-1 invariant delivery and evidence semantics.

## Scope
- Preserve all Phase-0 required gates.
- Add Phase-1 gates without regressing Phase-0 behavior.
- Enforce required contract rows only when `RUN_PHASE1_GATES=1`.

## Contract Rules
- Contract source: `docs/PHASE1/phase1_contract.yml`
- Verifier: `scripts/audit/verify_phase1_contract.sh`
- Control-plane gate: `INT-G28`

Required contract row fields:
- `invariant_id`
- `status`
- `required`
- `gate_id`
- `verifier`
- `evidence_path`

## Evidence Path Convention
- Phase-0 prerequisite invariants may keep `evidence/phase0/**`.
- New Phase-1 runtime invariants must use `evidence/phase1/**`.

## Status Semantics
- `phase0_prerequisite`: already enforced by Phase-0 gates.
- `planned`: gate/evidence path declared but not required yet.
- `implemented`: required and must pass with evidence present.
- `deferred_to_phase2`: outside Phase-1 scope.

## Enforcement Semantics
- `RUN_PHASE1_GATES=0`:
  - required Phase-1 runtime rows are not evaluated.
  - Phase-0 non-regression mode.
- `RUN_PHASE1_GATES=1`:
  - required rows fail closed if evidence is missing or schema-invalid.

## Gate Reservations
- `INT-G25`: INV-114
- `INT-G26`: INV-115
- `INT-G27`: INV-116
- `INT-G28`: Phase-1 contract verifier
- `SEC-G18`: .NET quality lint gate

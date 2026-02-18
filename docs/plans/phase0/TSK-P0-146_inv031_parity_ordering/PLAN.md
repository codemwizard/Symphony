# Implementation Plan (TSK-P0-146)

task_id: TSK-P0-146
title: Wire INV-031 gate ordering into pre-CI and CI parity runners
invariant_id: INV-031
gate_id: INT-G22

## Goal
Ensure the `INT-G22` verifier is executed under the same Phase-0 ordering contract in:
- local `scripts/dev/pre_ci.sh`
- CI runners (mechanical + DB jobs)

## Implementation approach
Because CI runs DB verifiers in a dedicated job, the ordering contract is:
- mechanical gates run via `scripts/audit/run_phase0_ordered_checks.sh`
- DB invariants run via `scripts/db/verify_invariants.sh`

This task wires `INT-G22` so it is:
- discoverable in control-plane drift checks
- executed in DB-capable contexts without producing conflicting evidence in DB-less contexts

## Verification
- Local: `scripts/dev/pre_ci.sh`
- CI: Phase-0 full workflow, then `contract_evidence_gate` job enforces merged evidence.

## Acceptance
- `INT-G22` runs in local pre-CI parity runner.
- CI produces `evidence/phase0/outbox_pending_indexes.json` deterministically.
- `scripts/audit/verify_phase0_contract_evidence_status.sh` passes.


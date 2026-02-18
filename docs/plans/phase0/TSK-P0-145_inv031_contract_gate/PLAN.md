# Implementation Plan (TSK-P0-145)

task_id: TSK-P0-145
title: Add INV-031 evidence path to Phase-0 contract (no SKIPPED traps)
invariant_id: INV-031
gate_id: INT-G22

## Goal
Require `evidence/phase0/outbox_pending_indexes.json` via `gate_ids: ["INT-G22"]` only after
the verifier emits deterministically in CI/pre-CI, to avoid "missing evidence" failures.

## Verification
- `bash scripts/audit/verify_phase0_contract_evidence_status.sh` (with merged artifacts in CI)
- Local: `scripts/dev/pre_ci.sh` (end-to-end parity runner)

## Acceptance
- Contract row references `INT-G22`.
- Contract evidence status check passes (no missing evidence for `INT-G22`).


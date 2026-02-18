# Implementation Plan (TSK-P0-143)

task_id: TSK-P0-143
title: Wire INV-031 performance gate into control-plane (INT-G22)
invariant_id: INV-031
gate_id: INT-G22

## Goal
Make `INV-031` first-class in the Phase-0 integrity control plane by pinning a non-colliding gate ID.

## Changes
- Add `INT-G22` mapping to `docs/control_planes/CONTROL_PLANES.yml`:
  - `INV-031`
  - verifier: `scripts/db/tests/test_outbox_pending_indexes.sh`
  - evidence: `evidence/phase0/outbox_pending_indexes.json`

## Verification
- `bash scripts/audit/verify_control_planes_drift.sh`

## Acceptance
- `INT-G22` exists in `docs/control_planes/CONTROL_PLANES.yml` and is drift-check clean.


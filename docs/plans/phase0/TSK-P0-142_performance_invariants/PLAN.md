# Implementation Plan (TSK-P0-142)

task_id: TSK-P0-142
title: Phase-0 performance invariants plan + docs alignment
invariant_id: INV-031

## Goal
Produce an audit-legible Phase-0 performance plan and close the documentation parity gap class:
- `docs/invariants/INVARIANTS_MANIFEST.yml` must match `docs/invariants/INVARIANTS_IMPLEMENTED.md`
- In particular, `INV-031` must be recorded as implemented with correct verifier and evidence linkage.

## Scope
In scope:
- Documentation and plan artifacts only.
- Invariants docs alignment for `INV-031`.

Out of scope:
- Adding new performance invariants.
- Adding new gates.
- Changing verifier behavior or evidence schema.

## Repro / Verification
- `bash scripts/audit/verify_task_plans_present.sh`

## Acceptance
- `docs/plans/phase0/TSK-P0-142_performance_invariants/PLAN.md` and `docs/plans/phase0/TSK-P0-142_performance_invariants/EXEC_LOG.md` exist and reference `INV-031`.
- `docs/invariants/INVARIANTS_IMPLEMENTED.md` includes `INV-031` with correct verifier + evidence reference.


# Execution Log (TSK-P0-147)

failure_signature: P0.INVARIANTS.ID_COLLISION.INV_106_108
origin_task_id: TSK-P0-125

repro_command: bash scripts/audit/run_invariants_fast_checks.sh

Plan: docs/plans/phase0/TSK-P0-147_inv106_116_canonicalization/PLAN.md

## change_applied
- Updated `docs/invariants/INVARIANTS_MANIFEST.yml` to reserve `INV-106..INV-108` for governance stubs, add `INV-109..INV-113`, and move the prior roadmap invariants to `INV-114..INV-116` while preserving aliases.
- Updated `docs/invariants/INVARIANTS_ROADMAP.md` and `docs/invariants/INVARIANTS_IMPLEMENTED.md` so doc-truth matches the manifest.
- Added `SEC-G17`, `INT-G23`, `INT-G24`, `GOV-G03` to `docs/control_planes/CONTROL_PLANES.yml` (non-colliding ranges).
- Added placeholder scripts for gates that are planned but not yet enforced (emit `SKIPPED` evidence deterministically).
- Wired the new gate scripts into canonical runners so `scripts/audit/verify_control_planes_drift.sh` passes.

## verification_commands_run
- bash scripts/audit/run_invariants_fast_checks.sh
- bash scripts/audit/run_security_fast_checks.sh
- bash scripts/audit/verify_control_planes_drift.sh
- scripts/dev/pre_ci.sh

## final_status
PASS

## final summary
- Control-plane gate IDs and scripts are non-colliding and drift-checked.
- INV-106..INV-110 are implemented as Phase-0 presence gates; INV-111..INV-113 are placeholders emitting deterministic SKIPPED until their owning tasks implement fail-closed enforcement.
- INV-BOZ-04 / INV-ZDPA-01 / INV-IPDR-02 are preserved as roadmap invariants under INV-114..INV-116.

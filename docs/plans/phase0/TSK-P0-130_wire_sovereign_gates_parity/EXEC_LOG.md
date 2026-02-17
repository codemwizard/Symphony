# Execution Log (TSK-P0-130)

failure_signature: P0.REG.SOVEREIGN_GATES.NOT_WIRED_PARITY
origin_task_id: TSK-P0-130
repro_command: bash scripts/dev/pre_ci.sh
Plan: docs/plans/phase0/TSK-P0-130_wire_sovereign_gates_parity/PLAN.md

## Change Applied
- Ensured sovereignty cluster gates are real and parity-executed:
  - `SEC-G17` runs `scripts/audit/lint_pii_leakage_payloads.sh` (PASS/FAIL evidence).
  - `INT-G23` runs `scripts/db/verify_boz_observability_role.sh` (PASS/FAIL evidence).
  - `INT-G24` runs `scripts/db/verify_anchor_sync_hooks.sh` (PASS/FAIL evidence).
- Wired DB verifiers into `scripts/db/verify_invariants.sh` so CI `db_verify_invariants` job exercises them.
- Confirmed local parity runner uses fresh ephemeral DB by default (`FRESH_DB=1`) and runs contract evidence status after DB checks.

## Verification Commands Run
verification_commands_run:
- bash scripts/audit/run_phase0_ordered_checks.sh
- bash scripts/dev/pre_ci.sh

## Status
final_status: PASS

## Final Summary
- Local pre-push/pre-CI parity is enforced via `scripts/dev/pre_ci.sh` (fresh ephemeral DB by default).
- CI parity is enforced by ensuring the same checks are reached through canonical entrypoints:
  - security plane: `scripts/audit/run_security_fast_checks.sh`
  - DB plane: `scripts/db/verify_invariants.sh`
- Contract evidence status gate runs after DB checks locally and after evidence aggregation in CI.

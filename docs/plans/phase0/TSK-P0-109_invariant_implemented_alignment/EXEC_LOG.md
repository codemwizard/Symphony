# EXEC_LOG — Align "Implemented" Invariants With Mechanical Verification

Plan: docs/plans/phase0/TSK-P0-109_invariant_implemented_alignment/PLAN.md

## Task IDs
- TSK-P0-109
- TSK-P0-110
- TSK-P0-111
- TSK-P0-112
- TSK-P0-113

## Log

### 2026-02-07 — Start
- Context: Remove stale TODO from implemented invariants by adding/verifying mechanical proof.
- Changes:
  - Added/verifed mechanical proof hooks for INV-007/011/012/013.
  - Added DB verifier: `scripts/db/verify_role_login_posture.sh` (INV-007).
  - Added DB tests + evidence: `scripts/db/tests/test_outbox_claim_semantics.sh` (INV-012) and `scripts/db/tests/test_outbox_lease_fencing.sh` (INV-013).
  - Wired tests into `scripts/dev/pre_ci.sh` and CI DB job (`.github/workflows/invariants.yml`).
  - Updated invariants docs/manifest to point at real verifiers (no TODO markers).
  - Fixed bash test harness issues:
    - Python evidence emission blocks used invalid escaping; corrected to valid Python dict strings.
    - Lease-fencing tests returned `CREATE FUNCTION\nPASS`; added `psql -q` so only `PASS` is captured.
- Commands:
  - `scripts/dev/pre_ci.sh`
- Result:
  - PASS (end-to-end Phase-0 local parity runner green, including DB verify + new DB tests).

## Final summary
- Completed. Implemented-invariants alignment now has deterministic mechanical verification and is wired into local + CI parity checks.

failure_signature: P0.INV_IMPLEMENTED_ALIGNMENT
origin_task_id: TSK-P0-109
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: PASS

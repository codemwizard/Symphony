# PLAN — Align "Implemented" Invariants With Mechanical Verification

## Task IDs
- TSK-P0-109
- TSK-P0-110
- TSK-P0-111
- TSK-P0-112
- TSK-P0-113

## Scope
Reconcile Phase-0 invariants that are marked implemented but whose documentation implies missing mechanical proof (TODO markers). Ensure each invariant meets the repo's implemented standard:
- a deterministic enforcement/verification hook exists (script/test/gate),
- it is wired into local/CI verification,
- and invariants docs reference the actual verifiers (no stale TODO).

Target invariants (from `docs/invariants/INVARIANTS_IMPLEMENTED.md` TODO markers):
- `INV-007` (runtime roles are NOLOGIN)
- `INV-011` (outbox enqueue idempotency)
- `INV-012` (outbox claim semantics, SKIP LOCKED + due/lease rules)
- `INV-013` (lease fencing on completion)

## Non-Goals
- No schema or business logic redesign.
- No concurrency-heavy tests; prefer deterministic, single-connection checks unless necessary.

## Approach
1. Add missing verifiers:
   - DB verifier for NOLOGIN role posture (`pg_roles.rolcanlogin=false`).
   - DB tests for outbox claim semantics and lease fencing (plus evidence emission).
2. Wire verifiers into:
   - local: `scripts/dev/pre_ci.sh` (pre-push hook calls this)
   - CI: `.github/workflows/invariants.yml` DB job (Phase-0 DB verify)
3. Update invariants manifest + implemented docs to remove TODO wording and reference the concrete verifiers.

## Files / Paths Touched
- `scripts/db/verify_role_login_posture.sh`
- `scripts/db/verify_invariants.sh`
- `scripts/db/tests/test_outbox_claim_semantics.sh`
- `scripts/db/tests/test_outbox_lease_fencing.sh`
- `scripts/dev/pre_ci.sh`
- `.github/workflows/invariants.yml`
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `docs/invariants/INVARIANTS_IMPLEMENTED.md`
- `docs/invariants/INVARIANTS_QUICK.md` (regenerated)
- `docs/tasks/PHASE0_TASKS.md`
- `docs/PHASE0/phase0_contract.yml` (if evidence artifacts become contract-required)
- `tasks/TSK-P0-109/meta.yml` ... `tasks/TSK-P0-113/meta.yml`

## Verification Commands
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/dev/pre_ci.sh`

## Remediation markers (required by INV-105 gate)
failure_signature: P0.INV_IMPLEMENTED_ALIGNMENT
origin_task_id: TSK-P0-109
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: PASS


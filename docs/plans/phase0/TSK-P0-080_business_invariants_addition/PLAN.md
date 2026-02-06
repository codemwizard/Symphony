# PLAN — Business invariants addition (Phase-0 hooks)

## Task IDs
- TSK-P0-080
- TSK-P0-081
- TSK-P0-082
- TSK-P0-083
- TSK-P0-084
- TSK-P0-085
- TSK-P0-086

## Scope
- Implement Phase-0 schema hooks for business invariants from `docs/PHASE0/BUSINESS_INVARIANTS_ADDITION_IMPLEMENTATION.md`.
- Add forward-only migrations for:
  - billing usage events (append-only)
  - external proofs (append-only)
  - correlation stitching columns
  - evidence pack primitives
  - billable client hierarchy hooks
  - multi-signature ingress hook
- Add/update schema-level invariant verification and evidence emission for the new hooks.
- Wire the new verification script(s) into existing invariant verification flow.

## Non-Goals
- Runtime pricing, invoicing, or billing policy logic.
- Runtime signature-subject matching and cryptographic validation workflows.
- External WORM anchoring execution.
- Phase-1/2 runtime integration behavior.

## Files / Paths Touched
- `schema/migrations/**`
- `scripts/db/verify_invariants.sh`
- `scripts/db/verify_business_foundation_hooks.sh` (new)
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `docs/invariants/INVARIANTS_IMPLEMENTED.md`
- `docs/tasks/PHASE0_TASKS.md`
- `tasks/TSK-P0-080/meta.yml`
- `tasks/TSK-P0-081/meta.yml`
- `tasks/TSK-P0-082/meta.yml`
- `tasks/TSK-P0-083/meta.yml`
- `tasks/TSK-P0-084/meta.yml`
- `tasks/TSK-P0-085/meta.yml`
- `tasks/TSK-P0-086/meta.yml`

## Gates / Verifiers
- `scripts/db/verify_business_foundation_hooks.sh` -> `evidence/phase0/business_foundation_hooks.json`
- `scripts/db/verify_invariants.sh` (must include new verifier)
- `scripts/audit/run_invariants_fast_checks.sh` (manifest/docs consistency)
- `scripts/ci/check_evidence_required.sh` (contract/evidence enforcement)

## Expected Failure Modes
- Migration adds mutable behavior to append-only business tables.
- Required columns/constraints/indexes for hooks are missing.
- Verifier script exists but is not wired into DB invariant flow.
- Invariants marked implemented without mechanical verification.
- Evidence file missing.

## Verification Commands
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/db/verify_invariants.sh`
- `scripts/db/tests/test_db_functions.sh`
- `scripts/ci/check_evidence_required.sh evidence/phase0`

## Dependencies
- TSK-P0-070 (plan/log scaffolding conventions)
- TSK-P0-071 (task meta schema update)
- TSK-P0-072 (plan/log verifier)
- TSK-P0-073 (CI/pre-CI wiring for plan/log checks)

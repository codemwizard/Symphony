# PLAN: Full Restoration Program (Post-Main Deletion Regression)

## Metadata
- plan_id: `TSK-P1-037_full_restoration_program`
- scope: Full functional restoration of deleted Phase-0/Phase-1 capabilities identified in `docs/audits/MAIN_PULL_DELETION_IMPACT_AUDIT_2026-02-18.md`
- target_outcome: Restore all previously deleted functionality (behavioral parity), with safe forward-only DB migration handling
- status: `completed`
- completed_on: `2026-02-18`

## Objective
Restore the full deleted pilot/hardening scope so that:
1. Mechanical gates and runtime checks previously removed are reintroduced.
2. Contract/control-plane/invariant mappings are restored and consistent.
3. Pilot harness, sandbox deployability posture, and product-readiness evidence flows are restored.
4. Phase-0 and Phase-1 gates remain fail-closed and pre-CI/CI parity is preserved.

## Completion summary
- PR-1 through PR-8 restoration stages are implemented and verified.
- Restored gates/invariants include timeout posture (`INV-117`/`INT-G32`), ingress hot-path indexes (`INV-118`/`INT-G33`), anchor operational invariant (`INT-G29`), pilot readiness/closeout verifiers, and sandbox manifest posture.
- Verification baseline: `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh` and `bash scripts/audit/verify_phase1_contract.sh` pass.

## Hard Constraints
- No direct push to `main`; use staged PRs.
- No direct pull from `main` into working branches outside PR flow.
- Forward-only migrations; no rewriting applied migration history.
- Approval metadata must precede production-affecting changes.
- All work must remain aligned with:
  - `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
  - `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md`
  - `docs/operations/AGENT_ROLE_RECONCILIATION.md`

## Restoration model
- Non-DB assets (scripts/docs/manifests/tests): restore 1:1 from pre-deletion baseline (`8d690b4`) where valid.
- DB operational behavior (deleted migrations `0032`, `0033`): restore via forward-safe equivalent migrations (new migration IDs) to avoid migration-history hazards.
- Gates/contracts: restore matching gate IDs/invariants/evidence references and then verify all call paths are wired.
- Restoration policy: default mode is **pure resurrection** (historical script names, gate semantics, and evidence filenames preserved). Any consolidation/renaming is out-of-scope unless explicitly declared as a follow-on refactor task.

## Staged PR plan

### PR-1: Governance + Contract Scaffolding + Approval Baseline
- purpose:
  - Establish restoration tracking and approval metadata foundations before production-affecting deltas.
- primary changes:
  - Add/update restoration program references in planning docs/tasks.
  - Prepare approval metadata workflow for subsequent PRs.
  - Remove or mark non-required any dangling references; do not add required contract entries for verifiers/evidence not present in the same PR.
- files:
  - `docs/operations/**`
  - `docs/PHASE1/phase1_contract.yml`
  - `docs/control_planes/CONTROL_PLANES.yml`
  - `docs/invariants/INVARIANTS_MANIFEST.yml`
  - `tasks/TSK-P1-037/**` ... `tasks/TSK-P1-045/**`
- verification:
  - `scripts/dev/pre_ci.sh`
  - confirm phase1 contract/approval checks remain green
- exit criteria:
  - Contract/control-plane changes compile with no dangling verifier paths.
  - No placeholder requirement exists for not-yet-restored verifiers/evidence.

### PR-2: Restore Phase-0 hardening gates (timeout + ingress hot path)
- purpose:
  - Reinstate deleted hardening checks tied to prior `INV-117` and `INV-118`.
- primary changes:
  - Restore:
    - `scripts/db/verify_timeout_posture.sh`
    - `scripts/db/tests/test_ingress_hotpath_indexes.sh`
  - Reinstate invariant + gate mappings:
    - `INV-117`, `INV-118`
    - `INT-G32`, `INT-G33`
  - Rewire `scripts/dev/pre_ci.sh` and any CI references.
- verification:
  - `scripts/dev/pre_ci.sh`
  - targeted:
    - `scripts/db/verify_timeout_posture.sh`
    - `scripts/db/tests/test_ingress_hotpath_indexes.sh`
- exit criteria:
  - Evidence emitted and required by contract.

### PR-3: Restore anchor-sync operational model via forward migrations
- purpose:
  - Recover deleted runtime operational semantics from removed migrations `0032/0033`.
- primary changes:
  - Add new forward migrations (new IDs) implementing equivalent behavior:
    - anchor operation table/state machine
    - lease claim/repair semantics
    - completion gating
  - Add explicit compatibility guards/idempotency strategy so environments that previously had 0032/0033-era schema remain safe (no double-apply hazards).
  - Restore deterministic schema baseline artifacts for reproducible fresh builds (using current baseline governance flow).
  - Ensure security posture (revoke-first, no broad grants).
- verification:
  - `scripts/dev/pre_ci.sh`
  - DB migration invariants + n-1 checks
- exit criteria:
  - New migrations apply cleanly to fresh DB and n-1 compatibility checks pass.

### PR-4: Restore anchor operational verifiers/tests and wire them
- purpose:
  - Reinstate removed operational invariant and runtime tests.
- primary changes:
  - Restore:
    - `scripts/db/verify_anchor_sync_operational_invariant.sh`
    - `scripts/db/tests/test_anchor_sync_operational.sh`
  - Rewire `pre_ci`/contract/control-plane for `INT-G29` evidence.
- verification:
  - `scripts/dev/pre_ci.sh`
  - targeted anchor sync checks
- exit criteria:
  - Operational anchor invariant and runtime semantics produce PASS evidence.

### PR-5: Restore pilot service self-tests + harness orchestration
- purpose:
  - Reinstate removed pilot runtime self-tests.
- primary changes:
  - Restore:
    - `scripts/services/test_exception_case_pack_generator.sh`
    - `scripts/services/test_pilot_authz_tenant_boundary.sh`
    - `scripts/dev/run_phase1_pilot_harness.sh`
  - Confirm dotnet self-test entrypoints still valid.
- verification:
  - `scripts/dev/pre_ci.sh`
  - targeted pilot harness command
- exit criteria:
  - Pilot harness replay can run deterministically and emit expected evidence.

### PR-6: Restore audit-level pilot readiness gates
- purpose:
  - Re-enable removed readiness and closeout verifiers.
- primary changes:
  - Restore:
    - `scripts/audit/verify_pilot_harness_readiness.sh`
    - `scripts/audit/verify_product_kpi_readiness.sh`
    - `scripts/audit/verify_phase1_demo_proof_pack.sh`
    - `scripts/audit/verify_phase1_closeout.sh`
  - Reintroduce docs:
    - `docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md`
    - `docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md`
    - `docs/operations/PHASE1_PRODUCT_KPI_DEFINITIONS.md`
    - `docs/security/PHASE1_PILOT_AUTHZ_MODEL.md`
- verification:
  - `scripts/dev/pre_ci.sh` with `RUN_PHASE1_GATES=1`
- exit criteria:
  - Demo pack, KPI report, and closeout evidence pass.

### PR-7: Restore sandbox deployability baseline + posture gate
- purpose:
  - Recover deleted sandbox deployment manifests and mechanical posture verification.
- primary changes:
  - Restore:
    - `infra/sandbox/k8s/*.yaml`
    - `scripts/security/verify_sandbox_deploy_manifest_posture.sh`
    - `docs/security/PHASE1_SANDBOX_DEPLOY_BASELINE.md`
  - Wire check into `pre_ci` / control-plane if required by contract.
- verification:
  - `scripts/dev/pre_ci.sh`
  - targeted sandbox posture verifier
- exit criteria:
  - Manifest posture evidence passes with fail-closed semantics.

### PR-8: Full reconciliation and closeout
- purpose:
  - Ensure all restored components are integrated and contracts are authoritative.
- primary changes:
  - Final pass across:
    - `docs/PHASE1/phase1_contract.yml`
    - `docs/control_planes/CONTROL_PLANES.yml`
    - `docs/invariants/INVARIANTS_MANIFEST.yml`
    - workflow/pre-ci parity references
  - Remove temporary compatibility shims if any.
- verification:
  - `scripts/dev/pre_ci.sh` (full)
  - Additional targeted checks as needed
- exit criteria:
  - No dangling references, all restored gates produce PASS evidence, closeout audit signed.

## Task backlog for this plan
- `TSK-P1-037` Program governance and approval scaffolding
- `TSK-P1-038` Restore timeout posture gate (`INV-117`/`INT-G32`)
- `TSK-P1-039` Restore ingress hot-path index gate (`INV-118`/`INT-G33`)
- `TSK-P1-040` Restore anchor operational model with forward migrations
- `TSK-P1-041` Restore anchor operational verifier/runtime tests and wiring
- `TSK-P1-042` Restore pilot service self-tests and harness orchestration
- `TSK-P1-043` Restore pilot readiness verifiers and closeout gates
- `TSK-P1-044` Restore sandbox deploy baseline and posture verifier
- `TSK-P1-045` Final contract/control-plane/invariants reconciliation and closeout

## Risk controls
- Use one PR per stage to isolate failures and make rollback surgical.
- For migrations:
  - Dry-run on fresh DB and n-1 path before merge.
  - Validate no runtime DDL in production paths.
  - Validate compatibility where prior environments may already contain 0032/0033-era objects.
- For governance:
  - Ensure approval metadata and agent conformance are always present for regulated surfaces.

## Restoration DoD (machine-verifiable)
Restoration is complete only when all are true:
1. `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh` returns PASS.
2. Restored hardening gates pass and emit expected evidence:
   - `scripts/db/verify_timeout_posture.sh` -> `evidence/phase0/db_timeout_posture.json`
   - `scripts/db/tests/test_ingress_hotpath_indexes.sh` -> `evidence/phase1/ingress_hotpath_indexes.json`
3. Restored anchor operational path passes:
   - `scripts/db/verify_anchor_sync_operational_invariant.sh` -> `evidence/phase1/anchor_sync_operational_invariant.json`
   - `scripts/db/tests/test_anchor_sync_operational.sh` -> `evidence/phase1/anchor_sync_resume_semantics.json`
4. Restored pilot/harness/readiness path passes:
   - `scripts/dev/run_phase1_pilot_harness.sh` -> `evidence/phase1/pilot_harness_replay.json`
   - `scripts/audit/verify_pilot_harness_readiness.sh` -> `evidence/phase1/pilot_onboarding_readiness.json`
   - `scripts/audit/verify_product_kpi_readiness.sh` -> `evidence/phase1/product_kpi_readiness_report.json`
   - `scripts/audit/verify_phase1_demo_proof_pack.sh` -> `evidence/phase1/regulator_demo_pack.json`, `evidence/phase1/tier1_pilot_demo_pack.json`
   - `scripts/audit/verify_phase1_closeout.sh` -> `evidence/phase1/phase1_closeout.json`
5. Restored sandbox posture passes:
   - `scripts/security/verify_sandbox_deploy_manifest_posture.sh` -> `evidence/phase1/sandbox_deploy_manifest_posture.json`
6. Contract/control-plane/invariant files have no dangling verifier/evidence references.

## Rollback strategy
- If a stage fails:
  - revert that PR only; do not roll back prior stable stages.
- Keep each PR independently releasable and gate-clean.

## Review checklist (for approval)
1. Does staged sequence match your desired “full restoration” scope?
2. Do you want strict 1:1 restoration of file contents where possible, with only migration-ID modernization?
3. Should PR-2 and PR-3 be merged together or remain separate for safety?
4. Confirm whether to require `RUN_PHASE1_GATES=1` in local pre-merge checks for PRs 5-8.

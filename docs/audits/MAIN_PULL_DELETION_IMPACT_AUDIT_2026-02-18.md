# Main Pull Deletion Impact Audit (2026-02-18)

## Scope and method
- Repository: `Symphony`
- Branch audited: `main`
- Pull event audited: `git pull origin main` fast-forward on 2026-02-18
- Compared commits:
  - Pre-pull local main: `8d690b4`
  - Post-pull main/origin main: `6ffb241`
- Commands used:
  - `git diff --name-status 8d690b4..6ffb241`
  - `git diff --diff-filter=D --name-only 8d690b4..6ffb241`
  - `git diff --stat 8d690b4..6ffb241`
  - `scripts/dev/pre_ci.sh` on post-pull `main`
  - `git show 8d690b4:<path>` for deleted scripts/migrations/docs to recover removed behavior

## Executive summary
- Deleted files in pull: **36**
- Net repo delta in pull: **+3906 / -8791** lines
- Immediate build/gate health on post-pull `main`: **`scripts/dev/pre_ci.sh` PASS**
- The deletions are mostly **coordinated de-scope/removal** of a Phase-1 pilot/sandbox/operational-hardening slice, not random corruption.
- Key regression area:
  - Prior enforced checks for DB timeout posture and ingress hot-path index posture (`INV-117`, `INV-118`) are no longer implemented/enforced in current `main`.
- Key non-regression area:
  - Current Phase-0 and retained Phase-1 contract checks still execute and pass on current `main`.

## Full deleted file inventory (nothing omitted)
1. `Initial-AppArmor-Profile-Creation_and_Fixes.md`
2. `PostgreSQL-18-Installation-and-Configuration-on-Ubuntu-Server_24.md`
3. `docs/invariants/exceptions/exception_change-rule_ddl_2026-02-14.md`
4. `docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md`
5. `docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md`
6. `docs/operations/PHASE1_PRODUCT_KPI_DEFINITIONS.md`
7. `docs/plans/phase0/TSK-P0-156_db_timeout_posture_gate/EXEC_LOG.md`
8. `docs/plans/phase0/TSK-P0-156_db_timeout_posture_gate/PLAN.md`
9. `docs/plans/phase1/TSK-P1-027_ingress_hotpath_index_performance_gate/EXEC_LOG.md`
10. `docs/plans/phase1/TSK-P1-027_ingress_hotpath_index_performance_gate/PLAN.md`
11. `docs/security/PHASE1_PILOT_AUTHZ_MODEL.md`
12. `docs/security/PHASE1_SANDBOX_DEPLOY_BASELINE.md`
13. `infra/sandbox/k8s/executor-worker-deployment.yaml`
14. `infra/sandbox/k8s/kustomization.yaml`
15. `infra/sandbox/k8s/ledger-api-deployment.yaml`
16. `infra/sandbox/k8s/namespace.yaml`
17. `infra/sandbox/k8s/secrets-bootstrap.yaml`
18. `schema/baselines/2026-02-14/0001_baseline.sql`
19. `schema/baselines/2026-02-14/baseline.cutoff`
20. `schema/baselines/2026-02-14/baseline.meta.json`
21. `schema/baselines/2026-02-14/baseline.normalized.sql`
22. `schema/migrations/0032_anchor_sync_operational_enforcement.sql`
23. `schema/migrations/0033_anchor_sync_operational_fix_append_only_and_lease_time.sql`
24. `scripts/audit/tests/__pycache__/test_detect_structural_sql_changes.cpython-311-pytest-8.2.2.pyc`
25. `scripts/audit/verify_phase1_closeout.sh`
26. `scripts/audit/verify_phase1_demo_proof_pack.sh`
27. `scripts/audit/verify_pilot_harness_readiness.sh`
28. `scripts/audit/verify_product_kpi_readiness.sh`
29. `scripts/db/tests/test_anchor_sync_operational.sh`
30. `scripts/db/tests/test_ingress_hotpath_indexes.sh`
31. `scripts/db/verify_anchor_sync_operational_invariant.sh`
32. `scripts/db/verify_timeout_posture.sh`
33. `scripts/dev/run_phase1_pilot_harness.sh`
34. `scripts/security/verify_sandbox_deploy_manifest_posture.sh`
35. `scripts/services/test_exception_case_pack_generator.sh`
36. `scripts/services/test_pilot_authz_tenant_boundary.sh`

## What functionality each deleted area provided

### A) Deleted DB runtime enforcement and verification
- `schema/migrations/0032_anchor_sync_operational_enforcement.sql`
  - Added `public.anchor_sync_operations` operational state machine for anchoring.
  - Added claim/lease/repair lifecycle DB functions:
    - `ensure_anchor_sync_operation`
    - `claim_anchor_sync_operation`
    - `mark_anchor_sync_anchored`
    - `complete_anchor_sync_operation`
    - `repair_expired_anchor_sync_leases`
  - Added queue-like index and revoke posture on the new table.
- `schema/migrations/0033_anchor_sync_operational_fix_append_only_and_lease_time.sql`
  - Hardened above logic using `clock_timestamp()` lease expiry semantics.
  - Added `anchor_type` and tightened completion/lease checks.
- `scripts/db/verify_anchor_sync_operational_invariant.sh`
  - Mechanical invariant gate for operational anchor-sync objects.
- `scripts/db/tests/test_anchor_sync_operational.sh`
  - Runtime semantics test for:
    - completion blocked before anchoring
    - anchored completion path
    - deterministic lease-expiry resume behavior
- `scripts/db/verify_timeout_posture.sh`
  - Mechanical DB timeout guardrail (fail-closed) for lock/statement/idle-in-tx posture.
- `scripts/db/tests/test_ingress_hotpath_indexes.sh`
  - Mechanical index posture test for ingress hot-path lookups (tenant/instruction/correlation).

### B) Deleted Phase-1 pilot/demo readiness gates and orchestration
- `scripts/audit/verify_phase1_demo_proof_pack.sh`
  - Generated/validated regulator and Tier-1 demo evidence pack claims from machine evidence.
- `scripts/audit/verify_pilot_harness_readiness.sh`
  - Validated replay readiness and onboarding readiness evidence composition.
- `scripts/audit/verify_product_kpi_readiness.sh`
  - Derived KPI readiness metrics from deterministic evidence; failed closed on stale/missing/non-pass.
- `scripts/audit/verify_phase1_closeout.sh`
  - End-to-end closeout verifier requiring a set of Phase-0+Phase-1 evidence and deferred invariant consistency.
- `scripts/dev/run_phase1_pilot_harness.sh`
  - Single command to run pilot self-tests and readiness verification.
- `scripts/services/test_exception_case_pack_generator.sh`
  - Dotnet self-test for exception case-pack generation path.
- `scripts/services/test_pilot_authz_tenant_boundary.sh`
  - Dotnet self-test for API-key tenant/participant authorization boundary.

### C) Deleted sandbox deployment posture artifacts
- `infra/sandbox/k8s/*.yaml` + `scripts/security/verify_sandbox_deploy_manifest_posture.sh`
  - Baseline pilot K8s deployment model:
    - namespace, kustomization
    - API/worker deployments
    - secret bootstrap pattern
    - anti-affinity/topology spread
    - run-as-non-root + no privilege escalation posture checks
  - Mechanical verification for manifest security and redundancy posture.

### D) Deleted docs and plan evidence that described the above
- `docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md`
- `docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md`
- `docs/operations/PHASE1_PRODUCT_KPI_DEFINITIONS.md`
- `docs/security/PHASE1_PILOT_AUTHZ_MODEL.md`
- `docs/security/PHASE1_SANDBOX_DEPLOY_BASELINE.md`
- `docs/plans/phase0/TSK-P0-156_db_timeout_posture_gate/*`
- `docs/plans/phase1/TSK-P1-027_ingress_hotpath_index_performance_gate/*`
- Plus one removed exception record and two environment setup docs.

## Contract/control-plane alignment changes observed in same pull

### Removed from control plane
- In `docs/control_planes/CONTROL_PLANES.yml`, these gates were removed:
  - `INT-G29` anchor-sync operational invariant
  - `INT-G30` phase1 demo proof pack
  - `INT-G31` phase1 closeout
  - `INT-G32` DB timeout posture
  - `INT-G33` ingress hot-path index posture

### Removed from invariants/phase contracts
- In `docs/invariants/INVARIANTS_MANIFEST.yml`:
  - removed `INV-117` (DB timeout posture)
  - removed `INV-118` (ingress hot-path indexes)
- In `docs/PHASE1/phase1_contract.yml`:
  - removed `INV-118` entry
  - retained/expanded agent conformance evidence requirements (split by role)

### Pre-CI flow changed accordingly
- `scripts/dev/pre_ci.sh` no longer calls removed pilot/operational verifiers/tests.
- Added DB port fallback logic (`5432` -> `55432`) for local parity resilience.

## Mapping deleted functionality to Phase-0 and Phase-1 goals

### Phase-0 goals impact
- Phase-0 contract currently emphasizes deterministic foundational checks (structure, evidence schema, DB invariants, security checks, parity).
- Deleted items with direct Phase-0 impact:
  - `scripts/db/verify_timeout_posture.sh` and its plan artifacts (`TSK-P0-156` docs).
- Impact classification:
  - **Regression relative to prior extended Phase-0 hardening** (timeout posture guard removed).
  - **No break of current Phase-0 contract execution**: current `pre_ci` still passes with remaining required Phase-0 gates.

### Phase-1 goals impact
- Current retained Phase-1 contract still enforces:
  - `INV-114` instruction finality
  - `INV-115` PII decoupling/purge
  - `INV-116` rail sequence truth anchor
  - `INV-105` agent conformance
  - `INV-077` approval metadata
  - `INV-081` .NET quality
- Deleted Phase-1 functionality mapped to prior goals:
  - Pilot integration contract/onboarding readiness orchestration
  - Demo-proof pack generation and closeout gating
  - Pilot KPI readiness gate
  - API key tenant boundary and exception case-pack service self-tests
  - Sandbox deployability posture checks
  - Anchor-sync **operational** enforcement (beyond structural hooks)
  - Ingress hot-path index performance gate
- Impact classification:
  - **Regression vs previously implemented pilot-readiness and operational-hardening scope**.
  - **No regression vs current declared Phase-1 contract on main** because those items were de-scoped from control-plane and contract files in the same change.

## Regression matrix

| Removed capability | Previously implemented? | Present on current `main`? | Contracted today? | Regression status |
|---|---:|---:|---:|---|
| DB timeout posture hard gate (`INV-117`/`INT-G32`) | Yes | No | No | Regression vs previous hardening scope; de-scoped in contracts |
| Ingress hot-path index gate (`INV-118`/`INT-G33`) | Yes | No | No | Regression vs previous hardening scope; de-scoped in contracts |
| Anchor-sync operational state machine (migrations 0032/0033 + tests) | Yes | No | No (`INV-113` now structural prerequisite only) | Regression of operational layer; structural layer still present |
| Pilot demo-proof pack gate (`INT-G30`) | Yes | No | No | Functional de-scope |
| Phase-1 closeout gate (`INT-G31`) | Yes | No | No | Functional de-scope |
| Pilot KPI readiness gate | Yes | No | No | Functional de-scope |
| Pilot harness orchestration command | Yes | No | No | Functional de-scope |
| Pilot authz/case-pack service self-tests | Yes | No | No | Functional de-scope |
| Sandbox k8s deploy posture verification | Yes | No | No | Functional de-scope |
| Sandbox k8s manifests | Yes | No | No | Deployability de-scope |

## Current-state risk assessment

### What remains healthy (verified)
- `scripts/dev/pre_ci.sh` passes on current `main`.
- Retained Phase-0 and contracted Phase-1 gates execute and produce evidence.
- No dangling script references were found to deleted paths in active workflow/pre-ci flow.

### What risk increased due to deletions
- No mechanical guard currently checks DB timeout posture bounds in local/CI.
- No mechanical guard currently checks ingress hot-path index posture.
- No operational anchor-sync DB lifecycle enforcement remains from deleted migrations.
- No built-in pilot harness for regulator/Tier-1 demo-readiness evidence production.
- No repo-tracked sandbox k8s baseline for Phase-1 pilot deploy posture.

## Conclusion
- The deletions are **intentional/paired de-scope changes**, not accidental file loss.
- There is **no immediate pipeline breakage** on current `main`.
- There **is** a meaningful **capability regression** from previously implemented pilot and operational hardening features.
- Regression is mostly governance/assurance and pilot-readiness scope reduction, not core runtime failure for currently contracted checks.

## Optional remediation tracks (if you want to restore lost guarantees)
1. Restore hardening-only subset:
   - `scripts/db/verify_timeout_posture.sh`
   - `scripts/db/tests/test_ingress_hotpath_indexes.sh`
   - Reinstate `INV-117/INV-118` + control-plane gates.
2. Restore anchor-sync operational enforcement:
   - migrations `0032`/`0033` + operational invariant/test scripts.
3. Restore pilot readiness package:
   - pilot harness script, proof-pack/KPI/closeout verifiers, service self-tests, and pilot docs.
4. Restore sandbox deploy baseline:
   - `infra/sandbox/k8s/*` and manifest posture verification script.



## Verbatim Append: Master Staged-PR Restoration Plan and Planned Tasks (TSK-P1-037 onward)

# PLAN: Full Restoration Program (Post-Main Deletion Regression)

## Metadata
- plan_id: `TSK-P1-037_full_restoration_program`
- scope: Full functional restoration of deleted Phase-0/Phase-1 capabilities identified in `docs/audits/MAIN_PULL_DELETION_IMPACT_AUDIT_2026-02-18.md`
- target_outcome: Restore all previously deleted functionality (behavioral parity), with safe forward-only DB migration handling
- status: `proposed`

## Objective
Restore the full deleted pilot/hardening scope so that:
1. Mechanical gates and runtime checks previously removed are reintroduced.
2. Contract/control-plane/invariant mappings are restored and consistent.
3. Pilot harness, sandbox deployability posture, and product-readiness evidence flows are restored.
4. Phase-0 and Phase-1 gates remain fail-closed and pre-CI/CI parity is preserved.

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

## Staged PR plan

### PR-1: Governance + Contract Scaffolding + Approval Baseline
- purpose:
  - Establish restoration tracking and approval metadata foundations before production-affecting deltas.
- primary changes:
  - Add/update restoration program references in planning docs/tasks.
  - Prepare approval metadata workflow for subsequent PRs.
  - Reintroduce contract placeholders for restored scope (without enabling missing verifiers yet).
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
- For governance:
  - Ensure approval metadata and agent conformance are always present for regulated surfaces.

## Rollback strategy
- If a stage fails:
  - revert that PR only; do not roll back prior stable stages.
- Keep each PR independently releasable and gate-clean.

## Review checklist (for approval)
1. Does staged sequence match your desired “full restoration” scope?
2. Do you want strict 1:1 restoration of file contents where possible, with only migration-ID modernization?
3. Should PR-2 and PR-3 be merged together or remain separate for safety?
4. Confirm whether to require `RUN_PHASE1_GATES=1` in local pre-merge checks for PRs 5-8.



phase: "1"
task_id: "TSK-P1-037"
title: "Launch full restoration program governance and staged PR scaffolding"
owner_role: "SUPERVISOR"
status: "planned"

depends_on: []

touches:
  - "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
  - "docs/PHASE1/phase1_contract.yml"
  - "docs/control_planes/CONTROL_PLANES.yml"
  - "docs/invariants/INVARIANTS_MANIFEST.yml"
  - "tasks/TSK-P1-037/meta.yml"

invariants:
  - "Restoration must be staged, fail-closed, and contract-aligned before runtime enforcement changes."

work:
  - "Create the staged PR plan and restoration task chain."
  - "Ensure approval metadata and regulated-surface governance preconditions are explicit."
  - "Prepare contract/control-plane scaffolding for restoration sequence without dangling refs."

acceptance_criteria:
  - "Staged PR plan exists and maps all deleted capability families to restoration stages."
  - "Task chain TSK-P1-037..TSK-P1-045 is defined with dependencies."
  - "No governance stop-condition is violated by planning artifacts."

verification:
  - "scripts/dev/pre_ci.sh"

evidence:
  - "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"

failure_modes:
  - "Restoration proceeds without approval/contract sequencing."
  - "Later PRs introduce dangling gate references."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"
  - "docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md"
  - "docs/operations/AGENT_ROLE_RECONCILIATION.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Planning-only anchor task for full restoration."
client: "codex_cli"
assigned_agent: "supervisor"
model: "gpt-5-codex"

## Restoration completion update (2026-02-18)

This audit originally captured de-scope regressions on `main`. The restoration program (`TSK-P1-037` through `TSK-P1-045`) has now been executed in staged PR batches and re-established the deleted capability families.

### Restored capability families
- DB timeout posture gate restored: `scripts/db/verify_timeout_posture.sh` with evidence `evidence/phase0/db_timeout_posture.json` (`INV-117` / `INT-G32`).
- Ingress hot-path index gate restored: `scripts/db/tests/test_ingress_hotpath_indexes.sh` with evidence `evidence/phase1/ingress_hotpath_indexes.json` (`INV-118` / `INT-G33`).
- Anchor operational model restored with forward-safe migrations and operational runtime verification:
  - `schema/migrations/0033_anchor_sync_operational_enforcement.sql`
  - `schema/migrations/0034_anchor_sync_operational_fix_append_only_and_lease_time.sql`
  - `scripts/db/verify_anchor_sync_operational_invariant.sh`
  - `scripts/db/tests/test_anchor_sync_operational.sh`
- Pilot harness and service self-tests restored:
  - `scripts/dev/run_phase1_pilot_harness.sh`
  - `scripts/services/test_exception_case_pack_generator.sh`
  - `scripts/services/test_pilot_authz_tenant_boundary.sh`
- Pilot readiness and closeout verifiers restored:
  - `scripts/audit/verify_pilot_harness_readiness.sh`
  - `scripts/audit/verify_product_kpi_readiness.sh`
  - `scripts/audit/verify_phase1_demo_proof_pack.sh`
  - `scripts/audit/verify_phase1_closeout.sh`
- Sandbox deployability baseline and posture verifier restored:
  - `infra/sandbox/k8s/*.yaml`
  - `scripts/security/verify_sandbox_deploy_manifest_posture.sh`
  - `docs/security/PHASE1_SANDBOX_DEPLOY_BASELINE.md`

### Contract and gate reconciliation status
- `docs/PHASE1/phase1_contract.yml` is aligned with restored invariant evidence paths.
- `docs/control_planes/CONTROL_PLANES.yml` declares restored gates (`INT-G29`, `INT-G32`, `INT-G33`) with valid verifier/evidence pairs.
- `docs/invariants/INVARIANTS_MANIFEST.yml` includes restored implemented entries for `INV-117` and `INV-118`.
- No dangling verifier/evidence references remain in the reconciled Phase-1 path.

### Closeout verification
- `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh` passes.
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh` passes.

Conclusion update: the previously documented deletion regressions are now addressed by restoration implementation; residual risk returns to normal operational drift risk managed by the restored mechanical gates.



phase: "1"
task_id: "TSK-P1-038"
title: "Restore DB timeout posture invariant and gate wiring"
owner_role: "DB_FOUNDATION"
status: "planned"

depends_on:
  - "TSK-P1-037"

touches:
  - "scripts/db/verify_timeout_posture.sh"
  - "docs/invariants/INVARIANTS_MANIFEST.yml"
  - "docs/control_planes/CONTROL_PLANES.yml"
  - "scripts/dev/pre_ci.sh"
  - "tasks/TSK-P1-038/meta.yml"

invariants:
  - "DB timeout posture remains bounded and fail-closed."

work:
  - "Restore timeout posture verifier script."
  - "Reinstate INV-117 and INT-G32 mapping in invariants/control-plane."
  - "Wire verifier invocation into pre_ci/phase gates."

acceptance_criteria:
  - "Timeout posture verifier runs and emits PASS evidence when posture is compliant."
  - "Contract/control-plane references are consistent and non-dangling."
  - "Failure mode remains fail-closed."

verification:
  - "scripts/dev/pre_ci.sh"
  - "scripts/db/verify_timeout_posture.sh"

evidence:
  - "evidence/phase0/db_timeout_posture.json"

failure_modes:
  - "No mechanical enforcement of timeout posture."
  - "Verifier is wired but non-fail-closed."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Functional restoration of deleted hardening capability."
client: "codex_cli"
assigned_agent: "db_foundation"
model: "gpt-5-codex"



phase: "1"
task_id: "TSK-P1-039"
title: "Restore ingress hot-path index invariant and verification gate"
owner_role: "DB_FOUNDATION"
status: "planned"

depends_on:
  - "TSK-P1-038"

touches:
  - "scripts/db/tests/test_ingress_hotpath_indexes.sh"
  - "docs/invariants/INVARIANTS_MANIFEST.yml"
  - "docs/PHASE1/phase1_contract.yml"
  - "docs/control_planes/CONTROL_PLANES.yml"
  - "scripts/dev/pre_ci.sh"
  - "tasks/TSK-P1-039/meta.yml"

invariants:
  - "Ingress hot-path query/index posture is mechanically verified."

work:
  - "Restore ingress hot-path index test script."
  - "Reinstate INV-118 and INT-G33 references."
  - "Wire invocation and evidence path into contract/gates."

acceptance_criteria:
  - "Ingress index test runs and emits deterministic evidence."
  - "Gate fails closed on missing/mismatched indexes."
  - "All references are present and consistent."

verification:
  - "scripts/dev/pre_ci.sh"
  - "scripts/db/tests/test_ingress_hotpath_indexes.sh"

evidence:
  - "evidence/phase1/ingress_hotpath_indexes.json"

failure_modes:
  - "Ingress index posture drifts without detection."
  - "Contract references evidence that is not produced."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Completes restoration of deleted performance hardening gate."
client: "codex_cli"
assigned_agent: "db_foundation"
model: "gpt-5-codex"



phase: "1"
task_id: "TSK-P1-040"
title: "Restore anchor-sync operational model using forward-safe migrations"
owner_role: "DB_FOUNDATION"
status: "planned"

depends_on:
  - "TSK-P1-039"

touches:
  - "schema/migrations/**"
  - "scripts/db/migrate.sh"
  - "tasks/TSK-P1-040/meta.yml"

invariants:
  - "Anchor-sync operational lifecycle remains deterministic, lease-fenced, and fail-closed."

work:
  - "Implement new migration IDs restoring behavior from deleted 0032/0033."
  - "Restore anchor operation state machine, claim/repair, and completion gating."
  - "Preserve revoke-first and SECURITY DEFINER hardening rules."

acceptance_criteria:
  - "Fresh DB apply succeeds."
  - "N-1 compatibility remains green."
  - "No runtime DDL policy violations are introduced."

verification:
  - "scripts/dev/pre_ci.sh"
  - "scripts/db/verify_invariants.sh"
  - "scripts/db/tests/test_db_functions.sh"

evidence:
  - "evidence/phase0/n_minus_one.json"

failure_modes:
  - "Migration chain conflicts or non-forward-safe changes."
  - "Lease/anchor transitions become non-deterministic."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Do not rewrite deleted migration IDs; restore behavior with new forward migrations."
client: "codex_cli"
assigned_agent: "db_foundation"
model: "gpt-5-codex"



phase: "1"
task_id: "TSK-P1-041"
title: "Restore anchor-sync operational invariant verifier and runtime tests"
owner_role: "DB_FOUNDATION"
status: "planned"

depends_on:
  - "TSK-P1-040"

touches:
  - "scripts/db/verify_anchor_sync_operational_invariant.sh"
  - "scripts/db/tests/test_anchor_sync_operational.sh"
  - "docs/control_planes/CONTROL_PLANES.yml"
  - "scripts/dev/pre_ci.sh"
  - "tasks/TSK-P1-041/meta.yml"

invariants:
  - "Operational anchor-sync behavior must be mechanically verified and runtime-tested."

work:
  - "Restore operational invariant script and runtime test."
  - "Rewire INT-G29 control-plane and evidence paths."
  - "Ensure pre_ci includes these checks in Phase-1 gate path."

acceptance_criteria:
  - "Anchor operational invariant evidence is produced and PASS."
  - "Runtime tests verify completion gate and resume semantics."
  - "No dangling references in control-plane or pre_ci."

verification:
  - "scripts/dev/pre_ci.sh"
  - "scripts/db/verify_anchor_sync_operational_invariant.sh"
  - "scripts/db/tests/test_anchor_sync_operational.sh"

evidence:
  - "evidence/phase1/anchor_sync_operational_invariant.json"
  - "evidence/phase1/anchor_sync_resume_semantics.json"

failure_modes:
  - "Anchor-sync operational drift undetected."
  - "Operational semantics pass structurally but fail at runtime."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Restores deleted operational test layer."
client: "codex_cli"
assigned_agent: "db_foundation"
model: "gpt-5-codex"



phase: "1"
task_id: "TSK-P1-042"
title: "Restore pilot service self-tests and harness orchestration"
owner_role: "SECURITY_GUARDIAN"
status: "planned"

depends_on:
  - "TSK-P1-041"

touches:
  - "scripts/services/test_exception_case_pack_generator.sh"
  - "scripts/services/test_pilot_authz_tenant_boundary.sh"
  - "scripts/dev/run_phase1_pilot_harness.sh"
  - "scripts/dev/pre_ci.sh"
  - "tasks/TSK-P1-042/meta.yml"

invariants:
  - "Pilot authz boundaries and case-pack generation remain deterministic and fail-closed."

work:
  - "Restore deleted service-level pilot self-tests."
  - "Restore phase1 pilot harness command."
  - "Integrate harness/self-tests into validated gate flow."

acceptance_criteria:
  - "Pilot authz self-test passes."
  - "Exception case-pack generation self-test passes."
  - "Harness command executes end-to-end without missing script errors."

verification:
  - "scripts/dev/pre_ci.sh"
  - "scripts/dev/run_phase1_pilot_harness.sh"

evidence:
  - "evidence/phase1/authz_tenant_boundary.json"
  - "evidence/phase1/exception_case_pack_generation.json"
  - "evidence/phase1/pilot_harness_replay.json"

failure_modes:
  - "Pilot harness replay path is no longer executable."
  - "Tenant boundary checks regress without detection."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Reinstates deleted pilot runtime harness path."
client: "codex_cli"
assigned_agent: "security_guardian"
model: "gpt-5-codex"



phase: "1"
task_id: "TSK-P1-043"
title: "Restore pilot readiness verifiers, KPI gate, demo pack, and closeout"
owner_role: "INVARIANTS_CURATOR"
status: "planned"

depends_on:
  - "TSK-P1-042"

touches:
  - "scripts/audit/verify_pilot_harness_readiness.sh"
  - "scripts/audit/verify_product_kpi_readiness.sh"
  - "scripts/audit/verify_phase1_demo_proof_pack.sh"
  - "scripts/audit/verify_phase1_closeout.sh"
  - "docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md"
  - "docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md"
  - "docs/operations/PHASE1_PRODUCT_KPI_DEFINITIONS.md"
  - "docs/security/PHASE1_PILOT_AUTHZ_MODEL.md"
  - "scripts/dev/pre_ci.sh"
  - "tasks/TSK-P1-043/meta.yml"

invariants:
  - "Phase-1 pilot readiness evidence chain is deterministic and fails closed on stale/missing inputs."

work:
  - "Restore deleted audit/readiness scripts."
  - "Restore deleted pilot contract/onboarding/KPI/authz docs."
  - "Re-enable Phase-1 closeout and demo-proof evidence generation."

acceptance_criteria:
  - "Pilot readiness, KPI, demo-pack, and closeout verifiers execute and pass."
  - "All required source evidence paths exist and are contract-aligned."
  - "RUN_PHASE1_GATES=1 path in pre_ci is stable."

verification:
  - "scripts/dev/pre_ci.sh"
  - "RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh"

evidence:
  - "evidence/phase1/pilot_onboarding_readiness.json"
  - "evidence/phase1/product_kpi_readiness_report.json"
  - "evidence/phase1/regulator_demo_pack.json"
  - "evidence/phase1/tier1_pilot_demo_pack.json"
  - "evidence/phase1/phase1_closeout.json"

failure_modes:
  - "Pilot readiness appears green without deterministic evidence chain."
  - "Closeout passes without required evidence coverage."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Restores deleted phase1 readiness and closeout governance path."
client: "codex_cli"
assigned_agent: "invariants_curator"
model: "gpt-5-codex"



phase: "1"
task_id: "TSK-P1-044"
title: "Restore sandbox deployment baseline manifests and posture verifier"
owner_role: "SECURITY_GUARDIAN"
status: "planned"

depends_on:
  - "TSK-P1-043"

touches:
  - "infra/sandbox/k8s/kustomization.yaml"
  - "infra/sandbox/k8s/namespace.yaml"
  - "infra/sandbox/k8s/ledger-api-deployment.yaml"
  - "infra/sandbox/k8s/executor-worker-deployment.yaml"
  - "infra/sandbox/k8s/secrets-bootstrap.yaml"
  - "scripts/security/verify_sandbox_deploy_manifest_posture.sh"
  - "docs/security/PHASE1_SANDBOX_DEPLOY_BASELINE.md"
  - "scripts/dev/pre_ci.sh"
  - "tasks/TSK-P1-044/meta.yml"

invariants:
  - "Pilot sandbox manifests satisfy redundancy and least-privilege deploy posture."

work:
  - "Restore deleted sandbox manifests."
  - "Restore deploy posture verifier and wire to gate flow."
  - "Validate no inline secret regressions in manifests."

acceptance_criteria:
  - "Sandbox posture verifier passes."
  - "Manifest security/redundancy controls are mechanically checked."
  - "Evidence path is emitted and contract-aligned."

verification:
  - "scripts/dev/pre_ci.sh"
  - "scripts/security/verify_sandbox_deploy_manifest_posture.sh"

evidence:
  - "evidence/phase1/sandbox_deploy_manifest_posture.json"

failure_modes:
  - "Pilot deployment posture drifts without checks."
  - "Inline secrets introduced into manifests."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Restores deleted Phase-1 sandbox deployability baseline."
client: "codex_cli"
assigned_agent: "security_guardian"
model: "gpt-5-codex"



phase: "1"
task_id: "TSK-P1-045"
title: "Finalize full restoration with contract/control-plane/invariant reconciliation"
owner_role: "SUPERVISOR"
status: "planned"

depends_on:
  - "TSK-P1-044"

touches:
  - "docs/PHASE1/phase1_contract.yml"
  - "docs/control_planes/CONTROL_PLANES.yml"
  - "docs/invariants/INVARIANTS_MANIFEST.yml"
  - ".github/workflows/invariants.yml"
  - "scripts/dev/pre_ci.sh"
  - "tasks/TSK-P1-045/meta.yml"
  - "docs/audits/MAIN_PULL_DELETION_IMPACT_AUDIT_2026-02-18.md"

invariants:
  - "All restored enforcement/verification paths must be contract-authoritative and non-dangling."

work:
  - "Reconcile all restored gates, invariants, and evidence paths."
  - "Run full end-to-end verification including phase1 gates."
  - "Publish closeout summary of restored scope and residual risk."

acceptance_criteria:
  - "No dangling verifier/evidence references in contracts or control plane."
  - "Full pre_ci passes with restoration scope enabled."
  - "Restoration audit marks deleted capability families as restored."

verification:
  - "scripts/dev/pre_ci.sh"
  - "RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh"

evidence:
  - "evidence/phase0/phase0_contract_evidence_status.json"
  - "evidence/phase1/phase1_contract_status.json"

failure_modes:
  - "Restored code exists but is not contract-wired."
  - "Control-plane still reflects de-scoped state."

must_read:
  - "docs/operations/AI_AGENT_OPERATION_MANUAL.md"
  - "docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md"
  - "docs/operations/AGENT_ROLE_RECONCILIATION.md"

implementation_plan: "docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md"
implementation_log: "docs/plans/phase1/TSK-P1-037_full_restoration_program/EXEC_LOG.md"

notes: "Final reconciliation and release-readiness signoff task."
client: "codex_cli"
assigned_agent: "supervisor"
model: "gpt-5-codex"


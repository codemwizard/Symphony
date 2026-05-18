# TSK-P3-SUPPORT-DB-003 PLAN — Fail-closed DB verifier bootstrap and connection diagnostics for scripts/db verifiers

Task: TSK-P3-SUPPORT-DB-003
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-DB-003.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Database Connection Context (CRITICAL)

- **Requirement**: All database interactions in verification scripts MUST use the `DATABASE_URL` environment variable.
- **Example Export**: `set -a && source infra/docker/.env && set +a && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${HOST_POSTGRES_PORT}/symphony"`
- **Docker Context**: The container is `symphony-postgres`.

---

## Objective

Fail-closed DB verifier bootstrap and connection diagnostics for scripts/db verifiers. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

- [ ] `docs/operations/TASK_ID_NOMENCLATURE.md` reviewed for task-family and wave rules.
- [ ] `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` reviewed for scope boundaries.
- [ ] `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` reviewed for invariant references.


---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_p3_typed_dependency_graph.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative Phase 3 DB verifier |
| `scripts/db/verify_p3_recursive_legitimacy_engine.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative Phase 3 DB verifier |
| `scripts/db/verify_p3_policy_authority_lineage.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative Phase 3 DB verifier |
| `scripts/db/verify_p3_authority_scope_engine.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative Phase 3 DB verifier |
| `scripts/db/verify_p3_conflict_of_interest_enforcement.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative Phase 3 DB verifier |
| `scripts/db/verify_p3_spatial_legality_dnsh_gates.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative Phase 3 DB verifier |
| `scripts/db/verify_p3_contradiction_detection.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative Phase 3 DB verifier |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance canonical migration head when DB task lands |
| `schema/baseline.sql` | MODIFY | Maintain stable baseline pointer after DB closure work |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Refresh current baseline cutoff metadata |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh current baseline metadata |
| `schema/baselines/2026-05-18/0001_baseline.sql` | MODIFY | Record dated baseline snapshot |
| `schema/baselines/2026-05-18/baseline.normalized.sql` | MODIFY | Record dated normalized baseline snapshot |
| `schema/baselines/2026-05-18/baseline.cutoff` | MODIFY | Record dated baseline cutoff |
| `schema/baselines/2026-05-18/baseline.meta.json` | MODIFY | Record dated baseline metadata |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Document baseline-governance closure |
| `docs/contracts/sqlstate_map.yml` | MODIFY | Register any new SQLSTATE codes introduced by the DB task |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register task in Phase 3 registry |
| `docs/tasks/PHASE3_TASKS.md` | MODIFY | Register task in the human Phase 3 task index |
| `scripts/db/verify_tsk_p3_support_db_003_fail_closed_db_probes.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_db_003_fail_closed_db_probes.json` | CREATE | Output artifact |
| `tasks/TSK-P3-SUPPORT-DB-003/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-DB-003/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_db_003_w01] Replace DB probe patterns in representative Phase 3 scripts/db verifiers so connection/bootstrap failures and invalid DATABASE_URL states are surfaced as explicit FAIL conditions instead of being swallowed and reinterpreted as missing schema objects.
- [ID tsk_p3_support_db_003_w02] Add a shared fail-closed probe discipline for scripts/db verifier authoring so DB-facing checks distinguish environment/bootstrap failure, object absence, and semantic mismatch without using silent fallback patterns.
- [ID tsk_p3_support_db_003_w03] Add a deterministic verifier that proves a representative scripts/db verifier now fails closed with explicit DB/bootstrap diagnostics under broken DATABASE_URL conditions and still passes under valid proof-DB conditions.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_tsk_p3_support_db_003_fail_closed_db_probes.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_tsk_p3_support_db_003_fail_closed_db_probes.sh > evidence/phase3/tsk_p3_support_db_003_fail_closed_db_probes.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Rebaseline (CRITICAL for DB_SCHEMA tasks)
**What:** Regenerate the physical baseline and satisfy ADR-0010 governance.
**How:**
1. Connect to DB: `set -a && source infra/docker/.env && set +a && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${HOST_POSTGRES_PORT}/symphony"`
2. Regenerate: `bash scripts/db/generate_baseline_snapshot.sh 2026-05-18`
3. Register any new SQLSTATE codes in `docs/contracts/sqlstate_map.yml`.
4. Audit Log: Append an entry to `docs/decisions/ADR-0010-baseline-policy.md` citing the new MIGRATION_HEAD and the specific changes made.
**Done when:** `scripts/db/check_baseline_drift.sh` exits 0.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/db/verify_tsk_p3_support_db_003_fail_closed_db_probes.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-DB-003 --evidence evidence/phase3/tsk_p3_support_db_003_fail_closed_db_probes.json

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-SUPPORT-DB-003
```

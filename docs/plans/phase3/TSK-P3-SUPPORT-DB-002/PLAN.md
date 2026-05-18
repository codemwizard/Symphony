# TSK-P3-SUPPORT-DB-002 PLAN — Make privilege-only migration effects visible to canonical baseline and drift governance

Task: TSK-P3-SUPPORT-DB-002
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-DB-002.PROOF_FAIL
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
- **Example Export**: `export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"`
- **Docker Context**: The container is `symphony-postgres`.

---

## Objective

Make privilege-only migration effects visible to canonical baseline and drift governance. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

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
| `scripts/db/generate_baseline_snapshot.sh` | MODIFY | Make privilege-state visible to canonical baseline governance |
| `scripts/db/check_baseline_drift.sh` | MODIFY | Detect privilege-only baseline drift |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Record the canonical baseline cutover when required |
| `schema/baseline.sql` | MODIFY | Keep stable baseline truth aligned if the repair changes canonical baseline shape |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Maintain stable baseline pointer artifacts |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Maintain stable baseline cutoff metadata |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Maintain stable baseline metadata |
| `schema/baselines/2026-05-17/0001_baseline.sql` | MODIFY | Record dated baseline truth for the remediation date |
| `schema/baselines/2026-05-17/baseline.normalized.sql` | MODIFY | Record dated normalized baseline truth for deterministic privilege hashing |
| `schema/baselines/2026-05-17/baseline.cutoff` | MODIFY | Record dated baseline cutoff metadata |
| `schema/baselines/2026-05-17/baseline.meta.json` | MODIFY | Record dated baseline metadata |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Record repaired privilege-visibility governance contract |
| `docs/tasks/PHASE3_TASKS.md` | MODIFY | Register the follow-up DB support repair task |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Reconcile completed status in Phase 3 machine registry |
| `docs/PHASE3/PHASE3_TASK_DAG.md` | MODIFY | Reconcile completed status in human DAG truth |
| `docs/PHASE3/phase3_task_dag.yml` | MODIFY | Reconcile completed status in machine DAG truth |
| `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | MODIFY | Reconcile completed status in master plan truth |
| `scripts/db/verify_tsk_p3_support_db_002_privilege_baseline_visibility.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_db_002_privilege_baseline_visibility.json` | CREATE | Output artifact |
| `tasks/TSK-P3-SUPPORT-DB-002/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-DB-002/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_support_db_002_w01] Extend the canonical baseline snapshot process so privilege-bearing schema state is captured in an admissible deterministic artifact instead of being erased by --no-privileges.
- [ID tsk_p3_support_db_002_w02] Update baseline drift governance so privilege-only migrations cannot pass drift equivalence silently when runtime GRANT/REVOKE state changes.
- [ID tsk_p3_support_db_002_w03] Record the updated baseline-governance contract in ADR-0010 and provide a deterministic verifier proving that a privilege-only change becomes visible to the baseline or its companion governance artifact.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_tsk_p3_support_db_002_privilege_baseline_visibility.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_tsk_p3_support_db_002_privilege_baseline_visibility.sh > evidence/phase3/tsk_p3_support_db_002_privilege_baseline_visibility.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Rebaseline (CRITICAL for DB_SCHEMA tasks)
**What:** Regenerate the physical baseline and satisfy ADR-0010 governance.
**How:**
1. Connect to DB: `export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"`
2. Regenerate: `bash scripts/db/generate_baseline_snapshot.sh`
3. Audit Log: Append an entry to `docs/decisions/ADR-0010-baseline-policy.md` citing the new MIGRATION_HEAD and the specific changes made.
**Done when:** `scripts/db/check_baseline_drift.sh` exits 0.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/db/verify_tsk_p3_support_db_002_privilege_baseline_visibility.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-DB-002 --evidence evidence/phase3/tsk_p3_support_db_002_privilege_baseline_visibility.json

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-SUPPORT-DB-002
```

# TSK-P3-W1-DB-007 PLAN — Add constitutional_data_class ENUM and data_class column to evidence_nodes with monotonicity trigger

Task: TSK-P3-W1-DB-007
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-W1-DB-007.PROOF_FAIL
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

Add constitutional_data_class ENUM and data_class column to evidence_nodes with monotonicity trigger. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_p3_evidence_nodes_data_class.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_w1_db_007_data_class.json` | CREATE | Output artifact |
| `tasks/TSK-P3-W1-DB-007/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-W1-DB-007/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_w1_db_007_work_item_01] Create migration 0205_evidence_nodes_data_class.sql defining constitutional_data_class ENUM with six values: identity, evidentiary, provenance, replay, regulator, operational — per DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md §3 and MRV-AMRC Tables 1-4.
- [ID tsk_p3_w1_db_007_work_item_02] Add data_class column to evidence_nodes with NOT NULL DEFAULT 'operational' and create enforce_data_class_monotonicity() SECURITY DEFINER trigger preventing downgrade of evidentiary/provenance/replay classifications (ERRCODE P3101).
- [ID tsk_p3_w1_db_007_work_item_03] Create docs/constitutional/data_class_registry.yml as machine-readable companion registry materialising the six classes with deletion_permission, replay_obligation, redaction_permission, retention_floor, and monotonicity_rank fields.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_p3_evidence_nodes_data_class.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_p3_evidence_nodes_data_class.sh > evidence/phase3/tsk_p3_w1_db_007_data_class.json
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
bash scripts/db/verify_p3_evidence_nodes_data_class.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```

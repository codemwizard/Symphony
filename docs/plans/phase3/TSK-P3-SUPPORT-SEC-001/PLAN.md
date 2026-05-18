# TSK-P3-SUPPORT-SEC-001 PLAN — Access-control and privilege model for lineage surfaces

Task: TSK-P3-SUPPORT-SEC-001
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-SEC-001.PROOF_FAIL
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

Access-control and privilege model for lineage surfaces. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: define one shared forward-only
access-control task for dependency, policy, and authority lineage surfaces,
preserving runtime-writer and verifier-reader separation without importing
product authorization, sovereignty runtime semantics, or broader application
auth redesign.

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
| `schema/migrations/0210_p3_lineage_access_control.sql` | CREATE | Forward-only privilege-structure migration path for the shared lineage surfaces |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance canonical migration head to 0210 |
| `schema/baseline.sql` | MODIFY | Refresh stable baseline pointer after canonical baseline regeneration |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot after 0210 |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Refresh current baseline cutoff after 0210 |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh current baseline metadata after 0210 |
| `schema/baselines/2026-05-17/0001_baseline.sql` | CREATE_OR_MODIFY | Dated baseline snapshot emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.normalized.sql` | CREATE_OR_MODIFY | Dated normalized baseline snapshot emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.cutoff` | CREATE_OR_MODIFY | Dated baseline cutoff emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.meta.json` | CREATE_OR_MODIFY | Dated baseline metadata emitted by canonical baseline tool |
| `scripts/db/verify_p3_lineage_access_control.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_sec_001_access_control.json` | CREATE | Output artifact |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Record required baseline governance note for MIGRATION_HEAD 0210 |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-SUPPORT-SEC-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-SEC-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into product authorization, sovereignty runtime semantics, or generalized auth redesign** -> STOP
- **If the privilege structure is frozen for only one owning surface** -> STOP

---

## Non-Goals

- No legitimacy evaluation or contradiction logic.
- No product authorization or external integration auth semantics.
- No regulator hierarchy or sovereignty runtime semantics.
- No collapse between runtime lineage writers and verifier observers.
- No unilateral privilege design finalization for only one owning surface.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one shared access-control task exists.
  - The verifier can prove that the task declares lineage-surface privilege
    structure, verifier-read separation, and replay-safe observation
    expectations for both owning surfaces where inspected.
- Limitations:
  - The verifier cannot prove runtime implementation of grants or roles.
  - The verifier cannot prove legitimacy, regulator, or product-authorization
    semantics.
  - The verifier cannot prove complete operational hardening beyond the
    declared lineage-surface privilege model.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_sec_001_w01] Define one forward-only access-control task for dependency, policy, and authority lineage surfaces that preserves lineage-write separation and verifier-read separation without importing product-authorization or future-phase sovereignty semantics.
- [ID tsk_p3_support_sec_001_w02] Declare grant boundaries, write-path restrictions, replay-read constraints, and no-runtime-verifier trust-collapse requirements for the shared lineage surfaces.
- [ID tsk_p3_support_sec_001_w03] Bind the access-control task to replay-safe verifier observation requirements and non-destructive privilege posture for historical lineage truth.
- [ID tsk_p3_support_sec_001_w04] Add a deterministic verifier path and evidence contract for the shared access-control model and register the generated task pack in the active Phase 3 runtime task index and registry.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_p3_lineage_access_control.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_p3_lineage_access_control.sh > evidence/phase3/tsk_p3_support_sec_001_access_control.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active human index and
Phase 3 runtime registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to
`tasks/TSK-P3-SUPPORT-SEC-001/meta.yml` as the live runtime task-pack source.

### Step 5: Rebaseline (CRITICAL for DB_SCHEMA tasks)
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
bash scripts/db/verify_p3_lineage_access_control.sh

# 2. Migration lint
bash scripts/db/lint_migrations.sh

# 3. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-SEC-001 --evidence evidence/phase3/tsk_p3_support_sec_001_access_control.json

# 4. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```

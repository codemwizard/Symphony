# TSK-P3-SUPPORT-DB-001 PLAN — Persistence model for dependency, policy, and authority lineage surfaces

Task: TSK-P3-SUPPORT-DB-001
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-DB-001.PROOF_FAIL
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

Persistence model for dependency, policy, and authority lineage surfaces. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: define one shared forward-only
persistence-model task for dependency, policy, and authority lineage surfaces,
including replay-stable provenance requirements, without importing legitimacy,
product-authorization, or future-phase runtime semantics.

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
| `schema/migrations/0209_p3_lineage_persistence_model.sql` | CREATE | Forward-only persistence-model migration path for the shared lineage surfaces |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance canonical migration head to 0209 |
| `schema/baseline.sql` | MODIFY | Refresh stable baseline pointer after canonical baseline regeneration |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot after 0209 |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Refresh current baseline cutoff after 0209 |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh current baseline metadata after 0209 |
| `schema/baselines/2026-05-17/0001_baseline.sql` | CREATE_OR_MODIFY | Dated baseline snapshot emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.normalized.sql` | CREATE_OR_MODIFY | Dated normalized baseline snapshot emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.cutoff` | CREATE_OR_MODIFY | Dated baseline cutoff emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.meta.json` | CREATE_OR_MODIFY | Dated baseline metadata emitted by canonical baseline tool |
| `scripts/db/verify_p3_lineage_persistence_model.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_db_001_persistence_model.json` | CREATE | Output artifact |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Record required baseline governance note for MIGRATION_HEAD 0209 |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-SUPPORT-DB-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-DB-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into legitimacy, product-authorization, or future-phase runtime semantics** -> STOP
- **If the persistence model is frozen for only one owning surface** -> STOP

---

## Non-Goals

- No legitimacy evaluation or contradiction logic.
- No product authorization or external integration persistence semantics.
- No regulator hierarchy or sovereignty runtime semantics.
- No destructive mutation of historical lineage truth.
- No unilateral persistence design finalization for only one owning surface.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one shared persistence-model task exists.
  - The verifier can prove that the task declares lineage-only migration,
    verifier, and evidence paths with replay-stable provenance expectations for
    both owning surfaces where inspected.
- Limitations:
  - The verifier cannot prove runtime implementation of the persistence model.
  - The verifier cannot prove legitimacy, regulator, or product-authorization
    semantics.
  - The verifier cannot prove full Phase 2 replay equality beyond declared
    compatibility intent.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_db_001_w01] Define one forward-only persistence-model task for immutable dependency lineage and replay-authoritative policy and authority lineage without introducing legitimacy, product-authorization, or future-phase semantics.
- [ID tsk_p3_support_db_001_w02] Declare canonical persistence requirements for typed dependency edges, policy artifact lineage, authority-source lineage, immutable provenance identifiers, and cross-system evidence continuity preparation needed by later INV-305 enforcement.
- [ID tsk_p3_support_db_001_w03] Bind the persistence-model task to non-destructive replay compatibility expectations for the admissible Phase 2 proof substrate and deterministic reconstruction requirements for later verifier use.
- [ID tsk_p3_support_db_001_w04] Add a deterministic verifier path and evidence contract for the persistence model and register the generated task pack in the active Phase 3 runtime task index and registry.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_p3_lineage_persistence_model.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_p3_lineage_persistence_model.sh > evidence/phase3/tsk_p3_support_db_001_persistence_model.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active human index and
Phase 3 runtime registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to
`tasks/TSK-P3-SUPPORT-DB-001/meta.yml` as the live runtime task-pack source.

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
bash scripts/db/verify_p3_lineage_persistence_model.sh

# 2. Migration lint
bash scripts/db/lint_migrations.sh

# 3. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-DB-001 --evidence evidence/phase3/tsk_p3_support_db_001_persistence_model.json

# 4. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```

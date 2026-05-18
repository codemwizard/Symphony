# TSK-P3-WP-005 PLAN — Failure composition and cross-system evidence continuity

Task: TSK-P3-WP-005
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-WP-005.PROOF_FAIL
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

Failure composition and cross-system evidence continuity. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the machine-readable
failure composition and replay-independent internal provenance continuity
substrate required by `P3-SURF-005` and `INV-305`, without importing
contradiction classification ownership, external MADD/MAIN integration,
regulator workflow, product authorization, or future-phase orchestration
semantics.

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
| `schema/migrations/0214_p3_failure_composition_engine.sql` | CREATE | Forward-only failure composition and continuity substrate |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance canonical migration head after success |
| `schema/baseline.sql` | MODIFY | Refresh stable baseline pointer after rebaseline |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot |
| `schema/baselines/current/baseline.normalized.sql` | MODIFY | Refresh normalized current baseline snapshot |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Refresh current baseline cutoff |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh current baseline metadata |
| `schema/baselines/2026-05-18/0001_baseline.sql` | CREATE | Dated baseline snapshot |
| `schema/baselines/2026-05-18/baseline.normalized.sql` | CREATE | Dated normalized baseline snapshot |
| `schema/baselines/2026-05-18/baseline.cutoff` | CREATE | Dated baseline cutoff |
| `schema/baselines/2026-05-18/baseline.meta.json` | CREATE | Dated baseline metadata |
| `scripts/audit/verify_p3_failure_composition_engine.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_005_failure_composition_engine.json` | CREATE | Output artifact |
| `docs/contracts/sqlstate_map.yml` | MODIFY | Register contradiction/failure SQLSTATEs used by the substrate/verifier |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Record rebaseline governance closure for this migration |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-005/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-005/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into contradiction classification ownership, external integration, or product-authorization semantics** -> STOP
- **If the implementation needs more than one forward-only migration for the declared failure-composition-only objective** -> STOP
- **If provenance continuity depends on runtime-only state, cache state, or live service references** -> STOP

---

## Non-Goals

- No contradiction classification semantics or contradiction-severity ownership.
- No policy or authority lineage definition, or projection-universe ownership.
- No external MADD/MAIN integration, regulator workflow execution, or product authorization semantics.
- No operational derivation of failure attributes from contradiction semantic content.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that machine-readable failure composition and
    internal provenance continuity structures exist and are machine-inspectable
    where inspected.
  - The verifier can prove that internal system boundary continuity is
    independently testable and that contradiction findings are consumed as
    read-only immutable-lineage references under the declared substrate.
- Limitations:
  - The verifier cannot prove contradiction classification semantics or
    external integration behavior.
  - The verifier cannot prove the substantive correctness of the failure
    taxonomy itself.
  - The verifier cannot prove runtime API integration or downstream
    migration/backfill behavior beyond declared structural constraints.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_005_w01] Define a single forward-only Phase 3 schema mutation that establishes machine-readable append-only failure composition and internal cross-system provenance continuity structures without importing contradiction classification ownership, external MADD/MAIN integration, regulator workflow, or product-authorization semantics.
- [ID tsk_p3_wp_005_w02] Bind failure and continuity records to explicit artifact-level mutability classes, deterministic canonical ordering and tie-break rules, immutable provenance continuity where required, and replay-independent reconstruction rules that exclude runtime-only state, cache dependence, and live service references.
- [ID tsk_p3_wp_005_w03] Add a deterministic verifier that proves internal system boundary continuity is independently testable with negative-test coverage aligned to INV-305, and that contradiction findings are consumed as read-only immutable-lineage references under declared structural constraints.
- [ID tsk_p3_wp_005_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 3 contradiction semantics, migration-share scope, or future-phase orchestration surfaces.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_p3_failure_composition_engine.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_p3_failure_composition_engine.sh > evidence/phase3/tsk_p3_wp_005_failure_composition_engine.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Rebaseline (CRITICAL for DB_SCHEMA tasks)
**What:** Regenerate the physical baseline and satisfy ADR-0010 governance.
**How:**
1. Connect to DB: `export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"`
2. Regenerate: `bash scripts/db/generate_baseline_snapshot.sh`
3. Audit Log: Append an entry to `docs/decisions/ADR-0010-baseline-policy.md` citing the new MIGRATION_HEAD and the specific changes made.
**Done when:** `scripts/db/check_baseline_drift.sh` exits 0.

### Step 5: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-005/meta.yml` as the live runtime task-pack source.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_p3_failure_composition_engine.sh

# 2. Migration lint
bash scripts/db/lint_migrations.sh

# 3. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-005 --evidence evidence/phase3/tsk_p3_wp_005_failure_composition_engine.json

# 4. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```

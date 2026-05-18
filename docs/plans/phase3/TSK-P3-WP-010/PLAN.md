# TSK-P3-WP-010 PLAN — Dwell-time forensic findings under temporal replay doctrine

Task: TSK-P3-WP-010
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-WP-010.PROOF_FAIL
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

Dwell-time forensic findings under temporal replay doctrine. This task forms a
closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the deterministic
replay-derived dwell-time forensic substrate required by `P3-SURF-010` and
`INV-310`, grounded in persisted constitutional records and declared temporal
policy inputs, without importing contradiction ownership, failure taxonomy
ownership, regulator routing, user-facing workflow timer semantics, or
historical-record mutation.

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
| `schema/migrations/0218_p3_dwell_time_forensic_enforcement.sql` | CREATE | Forward-only dwell-time forensic substrate |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance canonical migration head when DB task lands |
| `schema/baseline.sql` | MODIFY | Maintain stable baseline pointer after DB closure work |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Refresh current baseline cutoff metadata |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh current baseline metadata |
| `schema/baselines/2026-05-18/0001_baseline.sql` | MODIFY | Record dated baseline snapshot |
| `schema/baselines/2026-05-18/baseline.normalized.sql` | MODIFY | Record dated normalized baseline snapshot |
| `schema/baselines/2026-05-18/baseline.cutoff` | MODIFY | Record dated baseline cutoff |
| `schema/baselines/2026-05-18/baseline.meta.json` | MODIFY | Record dated baseline metadata |
| `scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_010_dwell_time_forensic_enforcement.json` | CREATE | Output artifact |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Document baseline-governance closure |
| `docs/contracts/sqlstate_map.yml` | MODIFY | Register any new SQLSTATE codes introduced by the DB task |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-010/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-010/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into contradiction ownership, failure taxonomy ownership, regulator routing, or user-facing workflow timer semantics** -> STOP
- **If the implementation needs more than one forward-only migration for the declared dwell-time-forensics-only objective** -> STOP
- **If declared temporal-policy inputs cannot be expressed without wall-clock runtime dependence or historical-record mutation** -> STOP

---

## Non-Goals

- No contradiction classification ownership.
- No failure composition taxonomy ownership.
- No regulator routing semantics.
- No user-facing workflow timers or orchestration.
- No retroactive mutation of pre-Phase-3 records or undeclared statutory time-limit semantics.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that deterministic replay-derived dwell-time
    forensic structures exist and are machine-inspectable where inspected.
  - The verifier can prove that declared temporal-policy thresholds are
    structurally evaluated against persisted constitutional records under the
    declared substrate.
- Limitations:
  - The verifier cannot prove the substantive correctness of temporal policy
    thresholds or statutory time-limit interpretation outside doctrine.
  - The verifier cannot prove user-facing timer workflow behavior,
    orchestration semantics, or regulator routing.
  - The verifier cannot prove future observability or performance-support
    implementation beyond declared structural constraints.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_010_w01] Define a single forward-only Phase 3 schema mutation that establishes deterministic replay-derived dwell-time forensic structures grounded in persisted constitutional records and declared temporal policy inputs without importing contradiction ownership, failure taxonomy ownership, regulator routing, or user-facing workflow timer semantics.
- [ID tsk_p3_wp_010_w02] Bind dwell-time findings to supersedable replay-derived projections, deterministic canonical ordering and tie-break rules, declared temporal-policy inputs, and historical-truth-preserving supersession rules that never rewrite prior records or depend on wall-clock runtime state.
- [ID tsk_p3_wp_010_w03] Add a deterministic verifier that proves dwell-time forensic structure is mechanically inspectable, threshold-based anomaly cases are testable against declared policy inputs, and findings remain replay-derived projections rather than historical truth under declared structural constraints.
- [ID tsk_p3_wp_010_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated contradiction/failure semantics, user-facing timer workflow, or Wave 4 support-node ownership.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh > evidence/phase3/tsk_p3_wp_010_dwell_time_forensic_enforcement.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-010/meta.yml` as the live runtime task-pack source.

### Step 5: Rebaseline (CRITICAL for DB_SCHEMA tasks)
**What:** Regenerate the physical baseline and satisfy ADR-0010 governance.
**How:**
1. Connect to DB: `export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"`
2. Regenerate: `bash scripts/db/generate_baseline_snapshot.sh 2026-05-18`
3. Register any new SQLSTATE codes in `docs/contracts/sqlstate_map.yml`.
4. Audit Log: Append an entry to `docs/decisions/ADR-0010-baseline-policy.md` citing the new MIGRATION_HEAD and the specific changes made.
**Done when:** `scripts/db/check_baseline_drift.sh` exits 0.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh

# 2. Migration lint
bash scripts/db/lint_migrations.sh

# 3. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-010 --evidence evidence/phase3/tsk_p3_wp_010_dwell_time_forensic_enforcement.json

# 4. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-WP-010
```

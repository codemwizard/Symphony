# TSK-P3-WP-006 PLAN — Authority scope and delegation enforcement

Task: TSK-P3-WP-006
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-WP-006.PROOF_FAIL
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

Authority scope and delegation enforcement. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the replay-authoritative
authority-scope and delegation enforcement substrate required by `P3-SURF-006`
and `INV-307`, anchored to the Wave 1 policy and authority lineage truth,
without importing regulator partition, product authorization, host-country
workflow, projection, or source-lineage definition semantics.

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
| `schema/migrations/0212_p3_authority_scope_engine.sql` | CREATE | Forward-only authority-scope and delegation enforcement substrate |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance the forward-only migration head after successful implementation |
| `schema/baseline.sql` | MODIFY | Refresh stable baseline after DB schema mutation |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot |
| `schema/baselines/current/baseline.normalized.sql` | MODIFY | Refresh current normalized baseline snapshot |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Advance current baseline cutoff to include migration 0212 |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh deterministic baseline metadata after rebaseline |
| `schema/baselines/2026-05-17/0001_baseline.sql` | MODIFY | Refresh dated baseline snapshot emitted by canonical baseline tooling |
| `schema/baselines/2026-05-17/baseline.normalized.sql` | MODIFY | Refresh dated normalized baseline emitted by canonical baseline tooling |
| `schema/baselines/2026-05-17/baseline.cutoff` | MODIFY | Refresh dated baseline cutoff emitted by canonical baseline tooling |
| `schema/baselines/2026-05-17/baseline.meta.json` | MODIFY | Refresh dated baseline metadata emitted by canonical baseline tooling |
| `scripts/db/verify_p3_authority_scope_engine.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_006_authority_scope_engine.json` | CREATE | Output artifact |
| `docs/contracts/sqlstate_map.yml` | MODIFY | Register the Phase 3 SQLSTATE required by `INV-307` |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Record baseline governance closure for migration 0212 |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-006/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-006/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into regulator partition, product authorization, host-country workflow, or projection semantics** -> STOP
- **If the implementation needs more than one forward-only migration for the declared authority-enforcement-only objective** -> STOP

---

## Non-Goals

- No policy or authority lineage definition.
- No projection or recursive legitimacy evaluation semantics.
- No contradiction or failure-composition mechanics.
- No regulator partition, product authorization, host-country workflow, or sovereignty runtime semantics.
- No generalized application authorization redesign.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that replay-authoritative authority enforcement
    structures exist and are machine-inspectable where inspected.
  - The verifier can prove that delegation overflow and revoked-authority cases
    are structurally rejectable under the declared substrate.
- Limitations:
  - The verifier cannot prove regulator partition, host-country workflow, or
    product-authorization semantics.
  - The verifier cannot prove the substantive correctness of the authority
    policy corpus itself.
  - The verifier cannot prove runtime API integration or generalized
    application authorization behavior.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_006_w01] Define a single forward-only Phase 3 schema mutation that establishes replay-authoritative authority-scope and delegation enforcement structures anchored to canonical policy and authority lineage without importing regulator, product-authorization, host-country workflow, or sovereignty runtime semantics.
- [ID tsk_p3_wp_006_w02] Bind authority enforcement to deterministic delegation reconstruction, revocation-lineage metadata, immutable provenance identifiers, and scope-overflow boundaries that never exceed declarative lineage-backed authority.
- [ID tsk_p3_wp_006_w03] Add a deterministic verifier that proves authority-scope enforcement structure exists, delegation overflow and revoked-authority cases are mechanically rejectable, and enforcement semantics remain anchored to Wave 1 lineage truth under declared structural constraints.
- [ID tsk_p3_wp_006_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 2 projection, fixture, or future-phase authority workflow scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_p3_authority_scope_engine.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_p3_authority_scope_engine.sh > evidence/phase3/tsk_p3_wp_006_authority_scope_engine.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active human index and
Phase 3 runtime registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-006/meta.yml` as the live
runtime task-pack source.

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
bash scripts/db/verify_p3_authority_scope_engine.sh

# 2. Migration lint
bash scripts/db/lint_migrations.sh

# 3. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-006 --evidence evidence/phase3/tsk_p3_wp_006_authority_scope_engine.json

# 4. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```

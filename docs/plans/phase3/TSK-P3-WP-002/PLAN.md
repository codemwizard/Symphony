# TSK-P3-WP-002 PLAN — Policy artifact and authority lineage foundation

Task: TSK-P3-WP-002
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-WP-002.PROOF_FAIL
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

Policy artifact and authority lineage foundation. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the first replay-authoritative
policy artifact and authority-lineage substrate required by `P3-SURF-002`,
without importing legitimacy semantics, regulator partition behavior,
host-country authorization runtime, or final authority-scope engine semantics.

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
| `schema/migrations/0208_p3_policy_authority_lineage.sql` | CREATE | Forward-only policy/authority lineage substrate |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance canonical migration head to 0208 |
| `schema/baseline.sql` | MODIFY | Refresh stable baseline pointer after canonical baseline regeneration |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot after 0208 |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Refresh current baseline cutoff after 0208 |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh current baseline metadata after 0208 |
| `schema/baselines/2026-05-17/0001_baseline.sql` | CREATE_OR_MODIFY | Dated baseline snapshot emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.normalized.sql` | CREATE_OR_MODIFY | Dated normalized baseline snapshot emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.cutoff` | CREATE_OR_MODIFY | Dated baseline cutoff emitted by canonical baseline tool |
| `schema/baselines/2026-05-17/baseline.meta.json` | CREATE_OR_MODIFY | Dated baseline metadata emitted by canonical baseline tool |
| `scripts/db/verify_p3_policy_authority_lineage.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_002_policy_authority_lineage.json` | CREATE | Output artifact |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Record required baseline governance note for MIGRATION_HEAD 0208 |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-002/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-002/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into legitimacy, regulator, host-country, or sovereign-mandate semantics** -> STOP
- **If the implementation needs more than one forward-only migration for the declared lineage-only objective** -> STOP

---

## Non-Goals

- No recursive legitimacy engine work.
- No contradiction or failure-composition work.
- No regulator partition runtime.
- No host-country authorization runtime.
- No methodology policy execution semantics.
- No full authority-scope engine finalization.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that policy artifact and authority lineage structures
    exist and are machine-inspectable where inspected.
  - The verifier can prove that malformed lineage insertion fails under
    structural constraints.
- Limitations:
  - The verifier cannot prove full authority-scope enforcement semantics.
  - The verifier cannot prove regulator hierarchy or host-country mandate meaning.
  - The verifier cannot prove runtime API integration.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_002_w01] Define a forward-only Phase 3 schema mutation that establishes replay-authoritative policy artifact lineage and authority-source lineage without introducing legitimacy, regulator, or host-country mandate semantics.
- [ID tsk_p3_wp_002_w02] Bind policy and authority lineage records to deterministic reconstruction primitives, immutable provenance identifiers, and revocation-lineage metadata compatible with the existing admissible proof substrate.
- [ID tsk_p3_wp_002_w03] Add a deterministic verifier that proves policy and authority lineage structure exists, authority-source reconstruction is machine-inspectable, and malformed lineage insertion fails under declared structural constraints.
- [ID tsk_p3_wp_002_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 1 planning or support-slice scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_p3_policy_authority_lineage.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_p3_policy_authority_lineage.sh > evidence/phase3/tsk_p3_wp_002_policy_authority_lineage.json
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
**What:** Register the generated runtime task pack in the active human index and
Phase 3 runtime registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-002/meta.yml` as the live
runtime task-pack source.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/db/verify_p3_policy_authority_lineage.sh

# 2. Migration lint
bash scripts/db/lint_migrations.sh

# 3. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-002 --evidence evidence/phase3/tsk_p3_wp_002_policy_authority_lineage.json

# 4. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```

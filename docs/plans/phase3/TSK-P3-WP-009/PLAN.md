# TSK-P3-WP-009 PLAN — Spatial legality and DNSH gates

Task: TSK-P3-WP-009
Owner: DB_FOUNDATION
failure_signature: PHASE3.STRICT.TSK-P3-WP-009.PROOF_FAIL
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

Spatial legality and DNSH gates. This task forms a closed proof graph from work
items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the authoritative
replay-derived spatial legality and DNSH gating substrate required by
`P3-SURF-009` and `INV-309`, grounded in canonical policy and authority
lineage, with explicit bounded-nondeterministic input declarations,
replay-stable comparison rules, and version-addressable dataset dependencies,
without importing external registry integrations, regulator submission
workflow, settlement semantics, or broad geospatial product behavior.

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
| `schema/migrations/0217_p3_spatial_legality_dnsh_gates.sql` | CREATE | Forward-only spatial legality and DNSH gate substrate |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance canonical migration head when DB task lands |
| `schema/baseline.sql` | MODIFY | Maintain stable baseline pointer after DB closure work |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Refresh current baseline snapshot |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Refresh current baseline cutoff metadata |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Refresh current baseline metadata |
| `schema/baselines/2026-05-18/0001_baseline.sql` | MODIFY | Record dated baseline snapshot |
| `schema/baselines/2026-05-18/baseline.normalized.sql` | MODIFY | Record dated normalized baseline snapshot |
| `schema/baselines/2026-05-18/baseline.cutoff` | MODIFY | Record dated baseline cutoff |
| `schema/baselines/2026-05-18/baseline.meta.json` | MODIFY | Record dated baseline metadata |
| `scripts/db/verify_p3_spatial_legality_dnsh_gates.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_009_spatial_legality_dnsh_gates.json` | CREATE | Output artifact |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Document baseline-governance closure |
| `docs/contracts/sqlstate_map.yml` | MODIFY | Register any new SQLSTATE codes introduced by the DB task |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-009/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-009/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into external registry integration, broad geospatial product behavior, regulator submission workflow, or settlement semantics** -> STOP
- **If the implementation needs more than one forward-only migration for the declared spatial/DNSH-only objective** -> STOP
- **If admissibility doctrine gaps remain unresolved, or bounded-nondeterministic inputs/comparison rules cannot be declared with version-addressable datasets** -> STOP

---

## Non-Goals

- No statutory environmental legal opinions or universal DNSH meaning.
- No cross-registry legal completeness claims or external registry integrations routed to Phase 8B.
- No regulator submission workflow or settlement semantics.
- No broad geospatial product behavior.
- No premature `SUPPORT-OBS-001` or `SUPPORT-PERF-001` task creation.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that authoritative replay-derived spatial/DNSH gate
    structures exist and are machine-inspectable where inspected.
  - The verifier can prove that bounded-nondeterministic inputs,
    replay-stable comparison rules, and version-addressable dataset
    dependencies are structurally declared under the substrate.
- Limitations:
  - The verifier cannot prove the substantive legal correctness of protected
    area datasets or statutory DNSH interpretation.
  - The verifier cannot prove external registry availability, double-counting
    integration, or regulator submission workflow behavior.
  - The verifier cannot prove user-facing geospatial behavior or future
    observability/performance-support implementation beyond declared structural
    constraints.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_009_w01] Define a single forward-only Phase 3 schema mutation that establishes authoritative replay-derived spatial legality and DNSH gating structures grounded in canonical policy and authority lineage without importing external registry integration, broad geospatial product behavior, regulator submission workflow, or settlement semantics.
- [ID tsk_p3_wp_009_w02] Bind spatial findings to supersedable admissibility projections, deterministic canonical ordering and tie-break rules, bounded-nondeterministic input declarations, replay-stable comparison rules, and version-identified replay-addressable dataset dependencies without undeclared cache, ordering, or dataset-staleness assumptions.
- [ID tsk_p3_wp_009_w03] Add a deterministic verifier that proves spatial legality and DNSH gate structure is mechanically inspectable, bounded nondeterminism is explicitly constrained to declared datasets and comparison rules, and unresolved admissibility doctrine gaps block continuation under declared structural constraints.
- [ID tsk_p3_wp_009_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated observability-share, performance-share, external registry, or broad geospatial product scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/db/verify_p3_spatial_legality_dnsh_gates.sh`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/db/verify_p3_spatial_legality_dnsh_gates.sh > evidence/phase3/tsk_p3_wp_009_spatial_legality_dnsh_gates.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-009/meta.yml` as the live runtime task-pack source.

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
bash scripts/db/verify_p3_spatial_legality_dnsh_gates.sh

# 2. Migration lint
bash scripts/db/lint_migrations.sh

# 3. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-009 --evidence evidence/phase3/tsk_p3_wp_009_spatial_legality_dnsh_gates.json

# 4. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-WP-009
```

# GF-W1-SCH-002A PLAN — Foundational root tables before all dependent Green Finance schema tasks

Task: GF-W1-SCH-002A
Owner: DB_FOUNDATION
Depends on: none
failure_signature: PH0.DB.GF_W1_SCH_002A.FOUNDATIONAL_OWNERSHIP_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create the first valid corrective root for the Green Finance schema graph by
introducing `projects` and `methodology_versions` exactly once and in the right
order. Done means the root tables have one owner each, their sidecars match the
parsed SQL, and every downstream dependency can point at this task instead of a
patch migration. The proof artifact is `evidence/phase0/gf_sch_002a.json`.

---

## Architectural Context

This task exists because the previous chain tried to repair missing root-table
ownership downstream, which invalidated determinism from an empty database. It
guards against three concrete anti-patterns: duplicate root ownership,
conditional root creation, and sidecar forgery. Downstream tasks must not start
until this task defines the neutral root correctly.

---

## Pre-conditions

- [ ] Approval metadata exists for the regulated-surface changes.
- [ ] The remediation rollback has removed the invalid diagnosis-linked chain.
- [ ] The `0097`-`0101` corrective range is reserved as the current collision-free Green Finance rebuild block.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0097_gf_projects.sql` | CREATE | Foundational root table |
| `schema/migrations/0097_gf_projects.meta.yml` | CREATE | Ownership sidecar |
| `schema/migrations/0098_gf_methodology_versions.sql` | CREATE | Second foundational root table |
| `schema/migrations/0098_gf_methodology_versions.meta.yml` | CREATE | Ownership sidecar |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Keep head consistent with filesystem |
| `scripts/db/verify_gf_sch_002a.sh` | CREATE | Root ownership verifier |
| `evidence/phase0/gf_sch_002a.json` | CREATE | Proof artifact |
| `tasks/GF-W1-SCH-002A/meta.yml` | MODIFY | Task contract |

---

## Stop Conditions

- **If `projects` or `methodology_versions` already has another governed owner** -> STOP
- **If the SQL creates a governed object not declared in sidecars** -> STOP
- **If procedural or destructive DDL appears in the migrations** -> STOP
- **If the verification plan cannot inspect real ownership/order state** -> STOP

---

## Implementation Steps

### Step 1: Create projects
**What:** `[ID gf_w1_sch_002a_work_item_01]` Add migration 0097 for `public.projects`.
**How:** Write a single-purpose migration owning only `projects` and its declared dependent objects.
**Done when:** Parsed SQL shows one governed owner for `public.projects`.

### Step 2: Create methodology_versions
**What:** `[ID gf_w1_sch_002a_work_item_02]` Add migration 0098 for `public.methodology_versions`.
**How:** Create it after 0097 with a FK that resolves to `public.projects`.
**Done when:** Ordered graph validation resolves the FK without forward references.

### Step 3: Bind sidecars and head
**What:** `[ID gf_w1_sch_002a_work_item_03]` Write sidecars and recompute `MIGRATION_HEAD`.
**How:** Populate `task_id`, `introduced_identifiers`, `phase`, `layer`, and `volatility_class`, then compare to parsed SQL.
**Done when:** Sidecar/SQL consistency and head consistency both pass.

### Step 4: Negative-test the root contract
**What:** `[ID gf_w1_sch_002a_work_item_04]` Add `scripts/db/verify_gf_sch_002a.sh`.
**How:** Make it fail on duplicate owners, `IF NOT EXISTS`, undeclared governed objects, procedural SQL, dynamic DDL, and destructive DDL.
**Done when:** The verifier exits non-zero on the declared negative cases and 0 on the correct implementation.

### Step 5: Emit evidence
**What:** `[ID gf_w1_sch_002a_work_item_05]` Write `evidence/phase0/gf_sch_002a.json`.
**How:** Run the verifier and persist bounded proof fields.
**Done when:** The evidence file exists with the declared contract.

---

## Verification

```bash
# [ID gf_w1_sch_002a_work_item_04] [ID gf_w1_sch_002a_work_item_05]
bash scripts/db/verify_gf_sch_002a.sh || exit 1

# [ID gf_w1_sch_002a_work_item_01] [ID gf_w1_sch_002a_work_item_02]
python3 scripts/audit/verify_neutral_schema_ast.py schema/migrations/0097_gf_projects.sql schema/migrations/0098_gf_methodology_versions.sql || exit 1

# [ID gf_w1_sch_002a_work_item_03]
python3 scripts/audit/verify_migration_meta_alignment.py || exit 1
```

---

## Evidence Contract

File: `evidence/phase0/gf_sch_002a.json`

Required fields:
- `task_id`: `GF-W1-SCH-002A`
- `git_sha`
- `timestamp_utc`
- `status`
- `projects_owner`
- `methodology_versions_owner`
- `ownership_uniqueness_confirmed`
- `reference_order_confirmed`
- `no_if_not_exists_confirmed`
- `owning_task_mapping_confirmed`
- `ownership_closure_confirmed`
- `sidecar_sql_consistency_confirmed`
- `migration_head_confirmed`
- `checks`

---

## Rollback

If this task must be reverted:
1. Remove the unmerged 0097/0098 migrations and sidecars together.
2. Restore `MIGRATION_HEAD` to the filesystem-derived max.
3. Update task status back to `ready` and record the failure in `EXEC_LOG.md`.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Duplicate root ownership | CRITICAL_FAIL | Graph verifier rejects multiple owners |
| Sidecar/SQL mismatch | CRITICAL_FAIL | Parse SQL and compare to sidecars |
| Anti-pattern: mixing downstream scope into the root task | FAIL_REVIEW | Restrict ownership to `projects` and `methodology_versions` only |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`

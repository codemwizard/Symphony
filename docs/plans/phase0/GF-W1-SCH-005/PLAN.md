# GF-W1-SCH-005 PLAN — Neutral lifecycle tables

Task: GF-W1-SCH-005
Owner: DB_FOUNDATION
Depends on: GF-W1-SCH-004, GF-W1-SCH-002A
failure_signature: PH0.DB.GF_W1_SCH_005.LIFECYCLE_SCOPE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create the corrected lifecycle task as a lifecycle-only downstream schema step
after the foundational, monitoring, and lineage tasks exist. Done means
migration 0101 owns only the declared lifecycle tables, keeps the schema
neutral, and emits proof that no extra governed objects or destructive behavior
leaked into the task.

---

## Architectural Context

This task sits after evidence lineage because lifecycle events depend on stable
project, monitoring, and evidence primitives. It also depends directly on the
corrected foundational task so lifecycle work cannot quietly rely on transitive
root ownership assumptions.

---

## Pre-conditions

- [ ] `GF-W1-SCH-002A` is completed and validated.
- [ ] `GF-W1-SCH-004` is completed and validated.
- [ ] Approval metadata exists for regulated-surface changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0101_gf_asset_lifecycle.sql` | CREATE | Lifecycle tables |
| `schema/migrations/0101_gf_asset_lifecycle.meta.yml` | CREATE | Ownership sidecar |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Keep head consistent |
| `scripts/db/verify_gf_asset_lifecycle.sh` | CREATE | Lifecycle verifier |
| `evidence/phase0/gf_asset_lifecycle.json` | CREATE | Proof artifact |
| `tasks/GF-W1-SCH-005/meta.yml` | MODIFY | Task contract |

---

## Stop Conditions

- **If this task creates any governed object outside lifecycle scope** -> STOP
- **If lifecycle neutrality cannot be proven mechanically** -> STOP
- **If direct dependencies on both upstream owner tasks are weakened** -> STOP
- **If verification cannot compare sidecars to parsed SQL** -> STOP

---

## Implementation Steps

### Step 1: Create lifecycle tables
**What:** `[ID gf_w1_sch_005_work_item_01]` Add migration 0101 for lifecycle-only governed objects.
**How:** Keep the migration restricted to `asset_batches`, `asset_lifecycle_events`, and `retirement_events`.
**Done when:** Parsed SQL shows only lifecycle-owned governed objects.

### Step 2: Bind metadata and head
**What:** `[ID gf_w1_sch_005_work_item_02]` Add sidecar metadata and update `MIGRATION_HEAD`.
**How:** Match governed objects exactly and recompute head from the filesystem.
**Done when:** Sidecar/SQL consistency and head consistency pass.

### Step 3: Prove negative cases
**What:** `[ID gf_w1_sch_005_work_item_03]` Add the lifecycle verifier.
**How:** Make it reject extra objects, procedural SQL, destructive DDL, and non-neutral lifecycle drift.
**Done when:** The declared negative cases fail closed.

### Step 4: Emit evidence
**What:** `[ID gf_w1_sch_005_work_item_04]` Write `evidence/phase0/gf_asset_lifecycle.json`.
**How:** Run the verifier and persist bounded proof fields.
**Done when:** The evidence file exists with the declared contract.

---

## Verification

```bash
# [ID gf_w1_sch_005_work_item_01] [ID gf_w1_sch_005_work_item_03]
bash scripts/db/verify_gf_asset_lifecycle.sh || exit 1

# [ID gf_w1_sch_005_work_item_02]
python3 scripts/audit/verify_migration_meta_alignment.py || exit 1

# [ID gf_w1_sch_005_work_item_04]
test -f evidence/phase0/gf_asset_lifecycle.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase0/gf_asset_lifecycle.json`

Required fields:
- `task_id`: `GF-W1-SCH-005`
- `git_sha`
- `timestamp_utc`
- `status`
- `asset_batches_owner`
- `asset_lifecycle_events_owner`
- `retirement_events_owner`
- `ownership_closure_confirmed`
- `sidecar_sql_consistency_confirmed`
- `checks`

---

## Rollback

If this task must be reverted:
1. Remove the unmerged 0101 migration and sidecar together.
2. Restore `MIGRATION_HEAD` to filesystem truth.
3. Update task status and remediation trace before retrying.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Lifecycle task leaks non-lifecycle ownership | CRITICAL_FAIL | Reject any created object outside lifecycle scope |
| Neutral lifecycle semantics weakened | CRITICAL_FAIL | Negative tests must fail on destructive/procedural patterns |
| Anti-pattern: undeclared helper objects | FAIL_REVIEW | Enforce ownership closure and sidecar/SQL comparison |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`

# GF-W1-SCH-003 PLAN — Monitoring records neutral append-only event ledger

Task: GF-W1-SCH-003
Owner: DB_FOUNDATION
Depends on: GF-W1-SCH-002A
failure_signature: PH0.DB.GF_W1_SCH_003.MONITORING_SCOPE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create the corrected monitoring ledger task as a single-purpose downstream
schema step after the foundational root is in place. Done means migration 0099
owns only `monitoring_records`, preserves append-only behavior, and emits proof
that no undeclared or destructive behavior leaked into the task.

---

## Architectural Context

The prior drift mixed foundational concerns and downstream ledger creation into
the same wrong-diagnosis chain. This repaired task keeps the ledger narrow and
depends directly on `GF-W1-SCH-002A`, which removes any excuse for transitive or
implicit root-table assumptions.

---

## Pre-conditions

- [ ] `GF-W1-SCH-002A` is completed and validated.
- [ ] Approval metadata exists for regulated-surface changes.
- [ ] Migration 0099 remains reserved for this task.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0099_gf_monitoring_records.sql` | CREATE | Monitoring ledger |
| `schema/migrations/0099_gf_monitoring_records.meta.yml` | CREATE | Ownership sidecar |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Keep head consistent |
| `scripts/db/verify_gf_monitoring_records.sh` | CREATE | Monitoring verifier |
| `evidence/phase0/gf_monitoring_records.json` | CREATE | Proof artifact |
| `tasks/GF-W1-SCH-003/meta.yml` | MODIFY | Task contract |

---

## Stop Conditions

- **If this task creates any governed object outside monitoring scope** -> STOP
- **If append-only behavior cannot be proven mechanically** -> STOP
- **If direct dependency on `GF-W1-SCH-002A` is removed or weakened** -> STOP
- **If verification cannot compare sidecars to parsed SQL** -> STOP

---

## Implementation Steps

### Step 1: Create monitoring table
**What:** `[ID gf_w1_sch_003_work_item_01]` Add migration 0099 for `public.monitoring_records`.
**How:** Keep the migration single-purpose and root-table-free.
**Done when:** Parsed SQL shows only the monitoring ledger and its declared dependent objects.

### Step 2: Bind metadata and head
**What:** `[ID gf_w1_sch_003_work_item_02]` Add sidecar metadata and update `MIGRATION_HEAD`.
**How:** Match governed objects exactly and recompute head from the filesystem.
**Done when:** Sidecar/SQL consistency and head consistency pass.

### Step 3: Prove negative cases
**What:** `[ID gf_w1_sch_003_work_item_03]` Add the monitoring verifier.
**How:** Make it reject extra tables, undeclared objects, procedural SQL, destructive DDL, and mutable ledger behavior.
**Done when:** The declared negative cases fail closed.

### Step 4: Emit evidence
**What:** `[ID gf_w1_sch_003_work_item_04]` Write `evidence/phase0/gf_monitoring_records.json`.
**How:** Run the verifier and persist bounded proof fields.
**Done when:** The evidence file exists with the declared contract.

---

## Verification

```bash
# [ID gf_w1_sch_003_work_item_01] [ID gf_w1_sch_003_work_item_03]
bash scripts/db/verify_gf_monitoring_records.sh || exit 1

# [ID gf_w1_sch_003_work_item_02]
python3 scripts/audit/verify_migration_meta_alignment.py || exit 1

# [ID gf_w1_sch_003_work_item_04]
test -f evidence/phase0/gf_monitoring_records.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase0/gf_monitoring_records.json`

Required fields:
- `task_id`: `GF-W1-SCH-003`
- `git_sha`
- `timestamp_utc`
- `status`
- `monitoring_records_owner`
- `append_only_confirmed`
- `ownership_closure_confirmed`
- `sidecar_sql_consistency_confirmed`
- `checks`

---

## Rollback

If this task must be reverted:
1. Remove the unmerged 0099 migration and sidecar together.
2. Restore `MIGRATION_HEAD` to filesystem truth.
3. Update task status and remediation trace before retrying.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Monitoring task leaks foundational ownership | CRITICAL_FAIL | Reject any created object outside monitoring scope |
| Append-only semantics weakened | CRITICAL_FAIL | Negative tests must fail on UPDATE/DELETE paths |
| Anti-pattern: undeclared helper objects | FAIL_REVIEW | Enforce ownership closure and sidecar/SQL comparison |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`

# GF-W1-SCH-004 PLAN — Evidence lineage universal graph

Task: GF-W1-SCH-004
Owner: DB_FOUNDATION
Depends on: GF-W1-SCH-003, GF-W1-SCH-002A
failure_signature: PH0.DB.GF_W1_SCH_004.LINEAGE_SCOPE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create the corrected evidence-lineage graph task as a lineage-only downstream
schema step after the foundational and monitoring tasks exist. Done means
migration 0100 owns only `evidence_nodes` and `evidence_edges`, preserves
lineage safety constraints, and emits proof that no extra governed objects or
destructive semantics leaked into the task.

---

## Architectural Context

This task sits after the monitoring ledger because lineage is structurally
meaningless without a stable upstream record layer. It also depends directly on
the corrected foundational task so the evidence graph cannot rely on transitive
root ownership assumptions.

---

## Pre-conditions

- [ ] `GF-W1-SCH-002A` is completed and validated.
- [ ] `GF-W1-SCH-003` is completed and validated.
- [ ] Approval metadata exists for regulated-surface changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0100_gf_evidence_lineage.sql` | CREATE | Lineage graph |
| `schema/migrations/0100_gf_evidence_lineage.meta.yml` | CREATE | Ownership sidecar |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Keep head consistent |
| `scripts/db/verify_gf_evidence_lineage.sh` | CREATE | Lineage verifier |
| `evidence/phase0/gf_evidence_lineage.json` | CREATE | Proof artifact |
| `tasks/GF-W1-SCH-004/meta.yml` | MODIFY | Task contract |

---

## Stop Conditions

- **If this task creates any governed object outside lineage scope** -> STOP
- **If self-loop prevention or lineage safety cannot be proven mechanically** -> STOP
- **If direct dependencies on both upstream owner tasks are weakened** -> STOP
- **If verification cannot compare sidecars to parsed SQL** -> STOP

---

## Implementation Steps

### Step 1: Create lineage tables
**What:** `[ID gf_w1_sch_004_work_item_01]` Add migration 0100 for lineage-only governed objects.
**How:** Keep the migration restricted to `evidence_nodes` and `evidence_edges`.
**Done when:** Parsed SQL shows only lineage-owned governed objects.

### Step 2: Bind metadata and head
**What:** `[ID gf_w1_sch_004_work_item_02]` Add sidecar metadata and update `MIGRATION_HEAD`.
**How:** Match governed objects exactly and recompute head from the filesystem.
**Done when:** Sidecar/SQL consistency and head consistency pass.

### Step 3: Prove negative cases
**What:** `[ID gf_w1_sch_004_work_item_03]` Add the lineage verifier.
**How:** Make it reject extra objects, self-loop regressions, procedural SQL, destructive DDL, and cascade collapse semantics.
**Done when:** The declared negative cases fail closed.

### Step 4: Emit evidence
**What:** `[ID gf_w1_sch_004_work_item_04]` Write `evidence/phase0/gf_evidence_lineage.json`.
**How:** Run the verifier and persist bounded proof fields.
**Done when:** The evidence file exists with the declared contract.

---

## Verification

```bash
# [ID gf_w1_sch_004_work_item_01] [ID gf_w1_sch_004_work_item_03]
bash scripts/db/verify_gf_evidence_lineage.sh || exit 1

# [ID gf_w1_sch_004_work_item_02]
python3 scripts/audit/verify_migration_meta_alignment.py || exit 1

# [ID gf_w1_sch_004_work_item_04]
test -f evidence/phase0/gf_evidence_lineage.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase0/gf_evidence_lineage.json`

Required fields:
- `task_id`: `GF-W1-SCH-004`
- `git_sha`
- `timestamp_utc`
- `status`
- `evidence_nodes_owner`
- `evidence_edges_owner`
- `self_loop_prevention_confirmed`
- `ownership_closure_confirmed`
- `sidecar_sql_consistency_confirmed`
- `checks`

---

## Rollback

If this task must be reverted:
1. Remove the unmerged 0100 migration and sidecar together.
2. Restore `MIGRATION_HEAD` to filesystem truth.
3. Update task status and remediation trace before retrying.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Lineage task leaks non-lineage ownership | CRITICAL_FAIL | Reject any created object outside lineage scope |
| Self-loop or cascade collapse semantics regress | CRITICAL_FAIL | Negative tests must fail on those patterns |
| Anti-pattern: undeclared helper objects | FAIL_REVIEW | Enforce ownership closure and sidecar/SQL comparison |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`

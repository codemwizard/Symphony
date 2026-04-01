# GF-W1-SCH-006 PLAN — Regulatory plane and jurisdiction tables

Task: GF-W1-SCH-006
Owner: DB_FOUNDATION
Depends on: GF-W1-SCH-005
failure_signature: PH0.DB.GF_W1_SCH_006.REGULATORY_SCOPE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create the corrected regulatory plane as a jurisdiction-only downstream schema
step after the lifecycle tables exist. Done means migrations 0102-0103 own only
the six declared jurisdiction tables and the `current_jurisdiction_code_or_null()`
helper function, preserve jurisdiction isolation semantics, and emit proof that
no extra governed objects or destructive behavior leaked into the task.

---

## Architectural Context

The regulatory plane is structurally separate from the tenant-scoped GF tables.
All six tables in this task use jurisdiction-based RLS (not tenant-based), which
requires the `current_jurisdiction_code_or_null()` SECURITY DEFINER function to
exist before any policy referencing it is created. Migration 0102 creates the
function and the first set of tables; migration 0103 creates the remaining tables
that reference entries from 0102.

**Corrected migration numbers:** The corrected implementation plan originally
listed 0078-0079 for this task, but those numbers are already applied
(0078_sequence_gap_fix.sql and 0079_hard_wave6_operational_resilience_and_privacy.sql).
The corrected collision-free assignment is 0102-0103.

---

## Pre-conditions

- [ ] `GF-W1-SCH-005` is completed and validated.
- [ ] Approval metadata exists for regulated-surface changes.
- [ ] Migration numbers 0102 and 0103 are confirmed available.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0102_gf_regulatory_plane.sql` | CREATE | jurisdiction function + first regulatory tables |
| `schema/migrations/0102_gf_regulatory_plane.meta.yml` | CREATE | Ownership sidecar |
| `schema/migrations/0103_gf_jurisdiction_rules.sql` | CREATE | Remaining jurisdiction tables |
| `schema/migrations/0103_gf_jurisdiction_rules.meta.yml` | CREATE | Ownership sidecar |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Keep head consistent (0103) |
| `scripts/db/verify_gf_regulatory_plane.sh` | CREATE | Regulatory plane verifier |
| `evidence/phase0/gf_regulatory_plane.json` | CREATE | Proof artifact |
| `tasks/GF-W1-SCH-006/meta.yml` | CREATE | Task contract |

---

## Stop Conditions

- **If this task creates any governed object outside the six declared jurisdiction tables and the jurisdiction function** -> STOP
- **If `current_jurisdiction_code_or_null()` does not use `SECURITY DEFINER SET search_path = pg_catalog, public`** -> STOP
- **If any table uses tenant isolation instead of jurisdiction isolation** -> STOP
- **If verification cannot compare sidecars to parsed SQL** -> STOP
- **If `CREATE TABLE IF NOT EXISTS` appears** -> STOP

---

## Governed Objects (migration 0102)

- Function: `public.current_jurisdiction_code_or_null()` — SECURITY DEFINER, SET search_path = pg_catalog, public
- Table: `public.interpretation_packs` — jurisdiction isolation
- Table: `public.regulatory_authorities` — jurisdiction isolation

## Governed Objects (migration 0103)

- Table: `public.regulatory_checkpoints` — jurisdiction isolation, FK to regulatory_authorities
- Table: `public.jurisdiction_profiles` — jurisdiction isolation
- Table: `public.lifecycle_checkpoint_rules` — jurisdiction isolation, FK to regulatory_checkpoints
- Table: `public.authority_decisions` — jurisdiction isolation, FK to regulatory_authorities

---

## Implementation Steps

### Step 1: Create jurisdiction function and first tables
**What:** `[ID gf_w1_sch_006_work_item_01]` Add migration 0102 with `current_jurisdiction_code_or_null()`, `interpretation_packs`, and `regulatory_authorities`.
**How:** Function must use SECURITY DEFINER with hardened search_path. Tables use jurisdiction RLS referencing the function.
**Done when:** Parsed SQL shows only declared governed objects; function hardening verified.

### Step 2: Create remaining jurisdiction tables
**What:** `[ID gf_w1_sch_006_work_item_02]` Add migration 0103 with `regulatory_checkpoints`, `jurisdiction_profiles`, `lifecycle_checkpoint_rules`, `authority_decisions`.
**How:** All tables reference 0102 governed objects via FK; all use jurisdiction RLS.
**Done when:** Parsed SQL shows only declared governed objects and all FKs resolve without forward references.

### Step 3: Bind sidecars and head
**What:** `[ID gf_w1_sch_006_work_item_03]` Write sidecars and update `MIGRATION_HEAD` to 0103.
**How:** Populate `task_id`, `introduces_identifiers`, `phase`, `layer`, `volatility_class`.
**Done when:** Sidecar/SQL consistency and head consistency pass.

### Step 4: Prove negative cases
**What:** `[ID gf_w1_sch_006_work_item_04]` Add `scripts/db/verify_gf_regulatory_plane.sh`.
**How:** Reject `IF NOT EXISTS`, tenant-scoped RLS on jurisdiction tables, missing SECURITY DEFINER hardening, undeclared governed objects.
**Done when:** Declared negative cases fail closed.

### Step 5: Emit evidence
**What:** `[ID gf_w1_sch_006_work_item_05]` Write `evidence/phase0/gf_regulatory_plane.json`.
**How:** Run the verifier; persist bounded proof fields including `run_id`.
**Done when:** Evidence file exists with the declared contract.

---

## Verification

```bash
# [ID gf_w1_sch_006_work_item_01] [ID gf_w1_sch_006_work_item_04]
bash scripts/db/verify_gf_regulatory_plane.sh || exit 1

# [ID gf_w1_sch_006_work_item_01] [ID gf_w1_sch_006_work_item_02]
python3 scripts/audit/verify_neutral_schema_ast.py schema/migrations/0102_gf_regulatory_plane.sql schema/migrations/0103_gf_jurisdiction_rules.sql || exit 1

# [ID gf_w1_sch_006_work_item_03]
python3 scripts/audit/verify_migration_meta_alignment.py || exit 1
```

---

## Evidence Contract

File: `evidence/phase0/gf_regulatory_plane.json`

Required fields:
- `task_id`: `GF-W1-SCH-006`
- `run_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `jurisdiction_fn_owner`
- `interpretation_packs_owner`
- `regulatory_authorities_owner`
- `regulatory_checkpoints_owner`
- `jurisdiction_profiles_owner`
- `lifecycle_checkpoint_rules_owner`
- `authority_decisions_owner`
- `ownership_uniqueness_confirmed`
- `jurisdiction_fn_hardened`
- `no_if_not_exists_confirmed`
- `ownership_closure_confirmed`
- `sidecar_sql_consistency_confirmed`
- `migration_head_confirmed`
- `checks`

---

## Rollback

If this task must be reverted:
1. Remove the unmerged 0102/0103 migrations and sidecars together.
2. Restore `MIGRATION_HEAD` to filesystem truth (0101).
3. Update task status back to `ready` and record the failure in `EXEC_LOG.md`.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Regulatory table uses tenant instead of jurisdiction RLS | CRITICAL_FAIL | Verifier rejects non-jurisdiction policy expression |
| `current_jurisdiction_code_or_null()` lacks SECURITY DEFINER hardening | SECURITY_FAIL | Verifier checks SET search_path clause |
| Migration number collision | CRITICAL_FAIL | 0102-0103 verified as available before scaffolding |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`

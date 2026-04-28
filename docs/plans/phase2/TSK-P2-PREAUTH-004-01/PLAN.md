# TSK-P2-PREAUTH-004-01: Create policy_decisions table

**Task:** TSK-P2-PREAUTH-004-01
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-004-00
**Blocks:** TSK-P2-PREAUTH-004-02
**failure_signature**: W4-REM-004-01
**canonical_reference**: docs/operations/AI_AGENT_OPERATION_MANUAL.md
**origin_task_id**: TSK-P2-PREAUTH-004-01
**repro_command**: bash scripts/db/verify_policy_decisions_schema.sh
**verification_commands_run**: verify_policy_decisions_schema.sh, validate_evidence.py
**final_status**: IMPLEMENTED

## Objective

Create the policy_decisions table to track policy decisions with cryptographic binding. The table is append-only with 11 columns, 5 constraints, and 2 indexes per migration 0134. This task was remediated by TSK-P2-PREAUTH-004-01-REM to align with the hardened 0134 contract.

## Architectural Context

The policy_decisions table stores policy decision events with cryptographic binding (decision_hash, signature). It is append-only with a trigger that raises GF060 on UPDATE/DELETE. It has a FK to execution_records (migration 0118) and enforces hash format constraints. This task aligns with INV-138 (authority transition binding).

## Pre-conditions

- TSK-P2-PREAUTH-004-00 PLAN.md exists and passes verification
- Migration 0134 exists (hardened Wave 4 contract)
- Migration 0118 exists (execution_records table for FK dependency)

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0134_create_policy_decisions.sql | READ | Migration creating policy_decisions table (hardened, 11 columns) |
| scripts/db/verify_policy_decisions_schema.sh | CREATE | Verification script for this task |
| tasks/TSK-P2-PREAUTH-004-01/meta.yml | MODIFY | Update to reference 0134 contract |

## Stop Conditions

- If migration 0134 does not create policy_decisions table with 11 columns
- If required constraints are missing (FK, UNIQUE, 2 CHECK, append-only trigger)
- If required indexes are missing (idx_policy_decisions_entity, idx_policy_decisions_declared_by)

## Implementation Steps

### [ID tsk_p2_preauth_004_01_work_item_01] Migration 0134 creates policy_decisions table
Migration 0134 creates policy_decisions table with 11 columns: policy_decision_id UUID NOT NULL DEFAULT gen_random_uuid(), execution_id UUID NOT NULL, decision_type TEXT NOT NULL, authority_scope TEXT NOT NULL, declared_by UUID NOT NULL, entity_type TEXT NOT NULL, entity_id UUID NOT NULL, decision_hash TEXT NOT NULL, signature TEXT NOT NULL, signed_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now().

### [ID tsk_p2_preauth_004_01_work_item_02] Migration 0134 creates 5 constraints
Migration 0134 creates 5 constraints: policy_decisions_pk (PRIMARY KEY), policy_decisions_fk_execution (FK to execution_records), policy_decisions_unique_exec_type (UNIQUE), policy_decisions_hash_hex_64 (CHECK on decision_hash), policy_decisions_sig_hex_128 (CHECK on signature).

### [ID tsk_p2_preauth_004_01_work_item_03] Migration 0134 creates 2 indexes
Migration 0134 creates 2 indexes: idx_policy_decisions_entity (entity_type, entity_id), idx_policy_decisions_declared_by (declared_by).

### [ID tsk_p2_preauth_004_01_work_item_04] Migration 0134 creates append-only trigger
Migration 0134 creates append-only trigger policy_decisions_append_only_trigger with function enforce_policy_decisions_append_only() having SECURITY DEFINER and pinned search_path.

## Verification

```bash
# [ID tsk_p2_preauth_004_01_work_item_01] [ID tsk_p2_preauth_004_01_work_item_02]
# [ID tsk_p2_preauth_004_01_work_item_03] [ID tsk_p2_preauth_004_01_work_item_04]
test -x scripts/db/verify_policy_decisions_schema.sh && bash scripts/db/verify_policy_decisions_schema.sh > evidence/phase2/tsk_p2_preauth_004_01.json || exit 1

# [ID tsk_p2_preauth_004_01_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_004_01.json || exit 1

# [ID tsk_p2_preauth_004_01_work_item_04]
python3 scripts/audit/validate_evidence.py --task TSK-P2-PREAUTH-004-01 --evidence evidence/phase2/tsk_p2_preauth_004_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_004_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- pass_count
- fail_count
- checks
- column_contract_source

## Regulated Surface Compliance

This task touches schema/migrations/0134_create_policy_decisions.sql (regulated surface). No approval metadata required as this is a remediation task aligning with existing hardened contract.

## Remediation Trace Compliance

- failure_signature: W4-REM-004-01
- origin_task_id: TSK-P2-PREAUTH-004-01
- repro_command: bash scripts/db/verify_policy_decisions_schema.sh
- verification_commands_run: verify_policy_decisions_schema.sh, validate_evidence.py
- final_status: IMPLEMENTED

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration 0134 contract mismatch | Low | High | Verified by verify_policy_decisions_schema.sh |
| Constraints missing | Low | High | All 5 constraints verified by script |
| Append-only trigger missing | Low | High | Trigger verified by script |

## Approval

This task modifies database schema. Requires human review before merge.

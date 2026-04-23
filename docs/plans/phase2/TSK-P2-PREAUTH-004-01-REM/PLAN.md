# TSK-P2-PREAUTH-004-01-REM PLAN: Verify Policy Decisions Schema and Update Task Metadata

**Task:** TSK-P2-PREAUTH-004-01-REM
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-004-01
**Blocks:** TSK-P2-PREAUTH-004-03-DAG
**failure_signature**: PHASE2.PREAUTH.TSK-P2-PREAUTH-004-01.METADATA_DRIFT
**origin_task_id**: TSK-P2-PREAUTH-004-01
**repro_command**: bash scripts/db/verify_policy_decisions_schema.sh
**verification_commands_run**: bash scripts/db/verify_policy_decisions_schema.sh; bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy
**final_status**: PLANNED

## Objective

Wave 4 audit identified that TSK-P2-PREAUTH-004-01 metadata references migration 0119 (4 columns) instead of the actual 0134 migration (11 columns). This task creates a verifier script built from the 0134 contract and updates the 004-01 task metadata to reflect the hardened implementation. Without this fix, the task metadata is out of sync with the actual migration, creating governance drift risk.

## Architectural Context

Migration 0134 (create_policy_decisions.sql) was hardened on the Wave 5 branch with 11 columns, 5 named constraints, and an append-only trigger. The original task metadata for 004-01 was never updated to reflect this implementation, leaving it in a "planned" state with incorrect migration references. This is a post-integration reconciliation task that aligns metadata with reality without modifying the migration itself.

## Pre-conditions

- Migration 0134 exists and is hardened (verified on Wave 5 branch)
- TSK-P2-PREAUTH-004-01 task pack exists but has stale metadata
- DATABASE_URL environment variable is available for verification

## Files to Change

| Path | Type | Change |
|------|------|--------|
| scripts/db/verify_policy_decisions_schema.sh | CREATE | Verifier script with 12 structural checks + 5 negative tests |
| tasks/TSK-P2-PREAUTH-004-01/meta.yml | MODIFY | Update status, migration ref, columns, negative tests, invariants |
| docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md | MODIFY | Rewrite with 0134 contract, compliance sections |
| docs/plans/phase2/TSK-P2-PREAUTH-004-01/EXEC_LOG.md | MODIFY | Append remediation markers and 0134 implementation entry |

## Stop Conditions

- If migration 0134 contract changes during implementation → STOP
- If verify_task_meta_schema.sh fails on updated meta.yml → STOP
- If verifier script does not use DATABASE_URL → STOP

## Implementation Steps

- [ID tsk_p2_preauth_004_01_rem_01] Create verify_policy_decisions_schema.sh at scripts/db/verify_policy_decisions_schema.sh with 12 structural checks (C1-C12) and 5 negative tests (N1-N5) per 0134 migration contract. Script must use DATABASE_URL environment variable for all psql commands.
- [ID tsk_p2_preauth_004_01_rem_02] Update tasks/TSK-P2-PREAUTH-004-01/meta.yml: status→completed, migration ref→0134_create_policy_decisions.sql, column list→all 11 per locked contract, negative tests→all 5 enumerated (N1-N5), verifier→verify_policy_decisions_schema.sh, evidence path→tsk_p2_preauth_004_01.json, invariants→INV-138, regulated_surface_compliance.enabled→true, remediation_trace_compliance.enabled→true, database_connection.enabled→true, migration_dependencies.enabled→true with table_dependencies: execution_records from 0118.

## Acceptance Criteria

- [ID tsk_p2_preauth_004_01_rem_01] Verifier script exists, is executable, uses DATABASE_URL for all psql commands, emits JSON evidence to evidence/phase2/tsk_p2_preauth_004_01.json with required fields.
- [ID tsk_p2_preauth_004_01_rem_02] meta.yml passes verify_task_meta_schema.sh --mode strict, references migration 0134, contains all 11 columns, 5 negative tests, invariants=[INV-138].

## Verification

```bash
# [ID tsk_p2_preauth_004_01_rem_01]
test -x scripts/db/verify_policy_decisions_schema.sh && bash scripts/db/verify_policy_decisions_schema.sh > evidence/phase2/tsk_p2_preauth_004_01.json || exit 1

# [ID tsk_p2_preauth_004_01_rem_01] [ID tsk_p2_preauth_004_01_rem_02]
python3 scripts/audit/validate_evidence.py --task TSK-P2-PREAUTH-004-01 --evidence evidence/phase2/tsk_p2_preauth_004_01.json || exit 1

# [ID tsk_p2_preauth_004_01_rem_02]
bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy || exit 1
```

## Evidence Contract

File: evidence/phase2/tsk_p2_preauth_004_01.json

Required fields:
- task_id: "TSK-P2-PREAUTH-004-01"
- git_sha: <commit sha at time of evidence emission>
- migration_head: "0144"
- timestamp_utc: <ISO 8601>
- status: "PASS|FAIL"
- pass_count: <int>
- fail_count: <int>
- checks: array of check objects with id, status, detail
- column_contract_source: "schema/migrations/0134_create_policy_decisions.sql"

## Remediation Trace Compliance (CRITICAL)

This task touches production-affecting surfaces (scripts/db/**) and requires remediation trace markers in the 004-01 EXEC_LOG.md:

- failure_signature: PHASE2.PREAUTH.TSK-P2-PREAUTH-004-01.METADATA_DRIFT
- origin_task_id: TSK-P2-PREAUTH-004-01
- repro_command: bash scripts/db/verify_policy_decisions_schema.sh
- verification_commands_run: bash scripts/db/verify_policy_decisions_schema.sh; bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy
- final_status: IMPLEMENTED

EXEC_LOG.md is append-only - never delete or modify existing entries.

## Regulated Surface Compliance

None of the files modified by this task are in REGULATED_SURFACE_PATHS.yml. Approval metadata is not required.

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration 0134 contract changes during implementation | Low | High | Stop condition triggers if contract changes |
| Verifier script does not use DATABASE_URL | Low | High | Stop condition triggers if DATABASE_URL not used |
| meta.yml fails schema validation | Low | Medium | Run verify_task_meta_schema.sh before marking complete |

## Approval

This task does not modify regulated surfaces. No approval metadata required.

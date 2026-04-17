# TSK-P2-PREAUTH-002-01: Create factor_registry table

<!--
PLAN.md RULES:
1. This file is the single source of truth for implementation. Do not begin implementation until this file is complete and verified.
2. Implementation steps MUST use explicit IDs: [ID step_name]. These IDs MUST map to work items in meta.yml and acceptance criteria.
3. Every implementation step MUST have a "Done when" clause that is objectively verifiable.
4. Verification section MUST include: (a) task-specific verifier, (b) validate_evidence.py for schema conformance, (c) pre_ci.sh for local parity.
5. Do NOT retroactively edit this PLAN.md to match the implementation log. If implementation diverges, update this file FIRST, then implement.
-->

**Task:** TSK-P2-PREAUTH-002-01
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-002-00
**Blocks:** TSK-P2-PREAUTH-002-02
**failure_signature:** PHASE2.PREAUTH.TSK-P2-PREAUTH-002-01.MIGRATION_FAIL
**canonical_reference:** docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the factor_registry table to track emission factors with unique factor codes. This task enables the system to manage factor definitions, preventing inconsistent factor usage across calculations.

## Architectural Context

The factor_registry table stores emission factor definitions with unique factor codes. This ensures factor codes are not duplicated and provides a canonical reference for emission factors used in calculations.

## Pre-conditions

- TSK-P2-PREAUTH-002-00 PLAN.md exists and passes verification
- Migration 0117 does not exist yet
- MIGRATION_HEAD exists and contains current migration number

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0117_create_factor_registry.sql | CREATE | Migration creating factor_registry table |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0117 |
| scripts/db/verify_tsk_p2_preauth_002_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration 0117 does not create factor_registry table
- If UNIQUE constraint on factor_code is missing
- If MIGRATION_HEAD is not updated to 0117

## Implementation Steps

### [ID tsk_p2_preauth_002_01_work_item_01] Write migration 0117
**What:** Create migration 0117 at schema/migrations/0117_create_factor_registry.sql
**How:** Write SQL to create factor_registry table with columns: factor_id UUID PRIMARY KEY, factor_code VARCHAR NOT NULL, factor_name VARCHAR NOT NULL, unit VARCHAR NOT NULL, and UNIQUE constraint on factor_code
**Done when:** Migration file exists and contains CREATE TABLE statement with UNIQUE constraint

### [ID tsk_p2_preauth_002_01_work_item_02] Update MIGRATION_HEAD
**What:** Update MIGRATION_HEAD to 0117
**How:** Execute echo 0117 > schema/migrations/MIGRATION_HEAD
**Done when:** schema/migrations/MIGRATION_HEAD contains exactly "0117"

### [ID tsk_p2_preauth_002_01_work_item_03] Write verification script
**What:** Create verify_tsk_p2_preauth_002_01.sh
**How:** Write bash script that runs psql to verify table exists and UNIQUE constraint on factor_code is present
**Done when:** scripts/db/verify_tsk_p2_preauth_002_01.sh exists and is executable

### [ID tsk_p2_preauth_002_01_work_item_04] Run verification script
**What:** Verify migration is successful
**How:** Execute bash scripts/db/verify_tsk_p2_preauth_002_01.sh
**Done when:** Verification script exits 0 and emits evidence file

### [ID tsk_p2_preauth_002_01_work_item_05] Write the Negative Test Constraints
**What:** Define negative test constraints for table verification
**How:** Document that verify_tsk_p2_preauth_002_01.sh must exit non-zero when factor_registry table does not exist
**Done when:** Negative test N1 is documented in meta.yml and passes verification

## Verification

```bash
# [ID tsk_p2_preauth_002_01_work_item_01] [ID tsk_p2_preauth_002_01_work_item_02]
# [ID tsk_p2_preauth_002_01_work_item_03] [ID tsk_p2_preauth_002_01_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_002_01.sh && bash scripts/db/verify_tsk_p2_preauth_002_01.sh > evidence/phase2/tsk_p2_preauth_002_01.json || exit 1

# [ID tsk_p2_preauth_002_01_work_item_02]
test $(cat schema/migrations/MIGRATION_HEAD) = "0117" || exit 1

# [ID tsk_p2_preauth_002_01_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_002_01.json || exit 1

# Validate evidence schema conformance
python3 scripts/audit/validate_evidence.py --task TSK-P2-PREAUTH-002-01 --evidence evidence/phase2/tsk_p2_preauth_002_01.json || exit 1

# Local parity check
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_002_01.json. Required fields:
- task_id: TSK-P2-PREAUTH-002-01
- git_sha: Current git commit SHA
- timestamp_utc: ISO-8601 timestamp in UTC
- status: One of PASS, FAIL, PARTIAL
- checks: Array of check results with name, status, message
- table_exists: true if factor_registry table exists
- unique_constraint_present: true if UNIQUE constraint on factor_code exists
- migration_head: Current migration head value

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0117_create_factor_registry.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Medium | Test migration on dev database first |
| UNIQUE constraint incorrect | Low | High | Review constraint definition carefully |

## Approval

This task modifies database schema (regulated surface). Requires human review and approval metadata before merge. Approval must be documented in approvals/ directory with signed approval.json.

# TSK-P2-PREAUTH-002-02: Create unit_conversions table

<!--
PLAN.md RULES:
1. This file is the single source of truth for implementation. Do not begin implementation until this file is complete and verified.
2. Implementation steps MUST use explicit IDs: [ID step_name]. These IDs MUST map to work items in meta.yml and acceptance criteria.
3. Every implementation step MUST have a "Done when" clause that is objectively verifiable.
4. Verification section MUST include: (a) task-specific verifier, (b) validate_evidence.py for schema conformance, (c) pre_ci.sh for local parity.
5. Do NOT retroactively edit this PLAN.md to match the implementation log. If implementation diverges, update this file FIRST, then implement.
-->

**Task:** TSK-P2-PREAUTH-002-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-002-01
**Blocks:** []
**failure_signature:** PHASE2.PREAUTH.TSK-P2-PREAUTH-002-02.MIGRATION_FAIL
**canonical_reference:** docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the unit_conversions table to track unit conversion factors with unique (from_unit, to_unit) pairs. This task enables the system to manage unit conversions, preventing incorrect calculations due to unit mismatches.

## Architectural Context

The unit_conversions table stores unit conversion factors with unique (from_unit, to_unit) pairs. This ensures conversion factors are not duplicated and provides a canonical reference for unit conversions used in calculations.

## Pre-conditions

- TSK-P2-PREAUTH-002-01 is complete
- Migration 0117 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0117_create_factor_registry.sql | MODIFY | Add unit_conversions table |
| scripts/db/verify_tsk_p2_preauth_002_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration does not create unit_conversions table
- If UNIQUE constraint on (from_unit, to_unit) is missing

## Implementation Steps

### [ID tsk_p2_preauth_002_02_work_item_01] Add unit_conversions table to migration 0117
**What:** Add unit_conversions table to migration 0117
**How:** Write SQL to create unit_conversions table with columns: conversion_id UUID PRIMARY KEY, from_unit VARCHAR NOT NULL, to_unit VARCHAR NOT NULL, conversion_factor NUMERIC NOT NULL, and UNIQUE constraint on (from_unit, to_unit)
**Done when:** Migration 0117 contains CREATE TABLE statement for unit_conversions with UNIQUE constraint

### [ID tsk_p2_preauth_002_02_work_item_02] Write verification script
**What:** Create verify_tsk_p2_preauth_002_02.sh
**How:** Write bash script that runs psql to verify table exists and UNIQUE constraint on (from_unit, to_unit) is present
**Done when:** scripts/db/verify_tsk_p2_preauth_002_02.sh exists and is executable

### [ID tsk_p2_preauth_002_02_work_item_03] Run verification script
**What:** Verify migration is successful
**How:** Execute bash scripts/db/verify_tsk_p2_preauth_002_02.sh
**Done when:** Verification script exits 0 and emits evidence file

### [ID tsk_p2_preauth_002_02_work_item_04] Write the Negative Test Constraints
**What:** Define negative test constraints for table verification
**How:** Document that verify_tsk_p2_preauth_002_02.sh must exit non-zero when unit_conversions table does not exist
**Done when:** Negative test N1 is documented in meta.yml and passes verification

## Verification

```bash
# [ID tsk_p2_preauth_002_02_work_item_01] [ID tsk_p2_preauth_002_02_work_item_02]
# [ID tsk_p2_preauth_002_02_work_item_03]
test -x scripts/db/verify_tsk_p2_preauth_002_02.sh && bash scripts/db/verify_tsk_p2_preauth_002_02.sh > evidence/phase2/tsk_p2_preauth_002_02.json || exit 1

# [ID tsk_p2_preauth_002_02_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_002_02.json || exit 1

# Validate evidence schema conformance
python3 scripts/audit/validate_evidence.py --task TSK-P2-PREAUTH-002-02 --evidence evidence/phase2/tsk_p2_preauth_002_02.json || exit 1

# Local parity check
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_002_02.json. Required fields:
- task_id: TSK-P2-PREAUTH-002-02
- git_sha: Current git commit SHA
- timestamp_utc: ISO-8601 timestamp in UTC
- status: One of PASS, FAIL, PARTIAL
- checks: Array of check results with name, status, message
- table_exists: true if unit_conversions table exists
- unique_constraint_present: true if UNIQUE constraint on (from_unit, to_unit) exists

## Rollback

Revert unit_conversions table addition from migration 0117:
```bash
git checkout schema/migrations/0117_create_factor_registry.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| UNIQUE constraint incorrect | Low | High | Review constraint definition carefully |
| Conversion factor type incorrect | Low | Medium | Use NUMERIC for precision |

## Approval

This task modifies database schema (regulated surface). Requires human review and approval metadata before merge. Approval must be documented in approvals/ directory with signed approval.json.

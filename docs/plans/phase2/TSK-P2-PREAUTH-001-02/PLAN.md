# TSK-P2-PREAUTH-001-02: Implement resolve_interpretation_pack() function with exact signature

<!--
PLAN.md RULES:
1. This file is the single source of truth for implementation. Do not begin implementation until this file is complete and verified.
2. Implementation steps MUST use explicit IDs: [ID step_name]. These IDs MUST map to work items in meta.yml and acceptance criteria.
3. Every implementation step MUST have a "Done when" clause that is objectively verifiable.
4. Verification section MUST include: (a) task-specific verifier, (b) validate_evidence.py for schema conformance, (c) pre_ci.sh for local parity.
5. Do NOT retroactively edit this PLAN.md to match the implementation log. If implementation diverges, update this file FIRST, then implement.
-->

**Task:** TSK-P2-PREAUTH-001-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-001-01
**Blocks:** TSK-P2-PREAUTH-003-00
**failure_signature:** PHASE2.PREAUTH.TSK-P2-PREAUTH-001-02.FUNCTION_FAIL
**canonical_reference:** docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Implement the resolve_interpretation_pack() function with exact signature to resolve the correct interpretation pack for a given project and effective timestamp. This task enables the system to determine which interpretation pack applies at a given time.

## Architectural Context

The resolve_interpretation_pack() function queries the interpretation_packs table to find the active interpretation pack for a project at a given effective timestamp. It must be SECURITY DEFINER with hardened search_path to prevent SQL injection.

## Pre-conditions

- TSK-P2-PREAUTH-001-01 is complete
- interpretation_packs table exists with temporal uniqueness constraint
- Migration 0116 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0116_create_interpretation_packs.sql | MODIFY | Add resolve_interpretation_pack() function |
| scripts/db/verify_tsk_p2_preauth_001_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If function does not have exact signature: FUNCTION resolve_interpretation_pack(p_project_id UUID, p_effective_at TIMESTAMPTZ) RETURNS UUID
- If function is not SECURITY DEFINER with hardened search_path
- If verifier does not check for exact function signature in pg_proc

## Implementation Steps

### [ID tsk_p2_preauth_001_02_work_item_01] Add resolve_interpretation_pack() function to migration 0116
**What:** Add resolve_interpretation_pack() function to migration 0116
**How:** Write CREATE FUNCTION statement with exact signature: FUNCTION resolve_interpretation_pack(p_project_id UUID, p_effective_at TIMESTAMPTZ) RETURNS UUID. Function must be SECURITY DEFINER with SET search_path = pg_catalog, public
**Done when:** Migration 0116 contains CREATE FUNCTION with exact signature and SECURITY DEFINER attribute

### [ID tsk_p2_preauth_001_02_work_item_02] Implement function logic
**What:** Implement temporal resolution query logic
**How:** Write SELECT statement: SELECT interpretation_pack_id FROM interpretation_packs WHERE project_id = p_project_id AND effective_from <= p_effective_at AND (effective_to IS NULL OR effective_to > p_effective_at) ORDER BY effective_from DESC LIMIT 1
**Done when:** Function body contains the temporal resolution query with correct WHERE clause and ordering

### [ID tsk_p2_preauth_001_02_work_item_03] Write verification script
**What:** Create verify_tsk_p2_preauth_001_02.sh
**How:** Write bash script that runs psql to verify function exists with exact signature and is SECURITY DEFINER
**Done when:** scripts/db/verify_tsk_p2_preauth_001_02.sh exists and is executable

### [ID tsk_p2_preauth_001_02_work_item_04] Run verification script
**What:** Verify function is created correctly
**How:** Execute bash scripts/db/verify_tsk_p2_preauth_001_02.sh
**Done when:** Verification script exits 0 and emits evidence file

### [ID tsk_p2_preauth_001_02_work_item_05] Write the Negative Test Constraints
**What:** Define negative test constraints for function verification
**How:** Document that verify_tsk_p2_preauth_001_02.sh must exit non-zero when function does not exist or has incorrect signature
**Done when:** Negative test N1 is documented in meta.yml and passes verification

## Verification

```bash
# [ID tsk_p2_preauth_001_02_work_item_01] [ID tsk_p2_preauth_001_02_work_item_02]
# [ID tsk_p2_preauth_001_02_work_item_03] [ID tsk_p2_preauth_001_02_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_001_02.sh && bash scripts/db/verify_tsk_p2_preauth_001_02.sh > evidence/phase2/tsk_p2_preauth_001_02.json || exit 1

# [ID tsk_p2_preauth_001_02_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='resolve_interpretation_pack' AND prorettype='uuid'::regtype" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_001_02_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_001_02.json || exit 1

# Validate evidence schema conformance
python3 scripts/audit/validate_evidence.py --task TSK-P2-PREAUTH-001-02 --evidence evidence/phase2/tsk_p2_preauth_001_02.json || exit 1

# Local parity check
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_001_02.json. Required fields:
- task_id: TSK-P2-PREAUTH-001-02
- git_sha: Current git commit SHA
- timestamp_utc: ISO-8601 timestamp in UTC
- status: One of PASS, FAIL, PARTIAL
- checks: Array of check results with name, status, message
- function_exists: true if resolve_interpretation_pack function exists in pg_proc
- function_signature_correct: true if function signature matches exact specification
- security_definer_present: true if function is SECURITY DEFINER with prosecdef=true

## Rollback

Revert function addition from migration 0116:
```bash
git checkout schema/migrations/0116_create_interpretation_packs.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function signature incorrect | Low | Critical | Verify exact signature matches requirements |
| Function not SECURITY DEFINER | Low | Critical | Hardening required for security |

## Approval

This task modifies database schema with SECURITY DEFINER function (regulated surface). Requires human review and approval metadata before merge. Approval must be documented in approvals/ directory with signed approval.json.

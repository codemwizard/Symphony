# TSK-P2-PREAUTH-002-00: Create PLAN.md and verify alignment for factor_registry

<!--
PLAN.md RULES:
1. This file is the single source of truth for implementation. Do not begin implementation until this file is complete and verified.
2. Implementation steps MUST use explicit IDs: [ID step_name]. These IDs MUST map to work items in meta.yml and acceptance criteria.
3. Every implementation step MUST have a "Done when" clause that is objectively verifiable.
4. Verification section MUST include: (a) task-specific verifier, (b) validate_evidence.py for schema conformance, (c) pre_ci.sh for local parity.
5. Do NOT retroactively edit this PLAN.md to match the implementation log. If implementation diverges, update this file FIRST, then implement.
-->

**Task:** TSK-P2-PREAUTH-002-00
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-CCG-001-01
**Blocks:** TSK-P2-PREAUTH-002-01
**failure_signature:** PHASE2.PREAUTH.TSK-P2-PREAUTH-002-00.PLAN_ALIGNMENT_FAIL
**canonical_reference:** docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the PLAN.md for the factor_registry and unit_conversions tables. This task ensures the schema changes have architectural documentation and verification trace before implementation begins.

## Architectural Context

The factor_registry table tracks emission factors with unique factor codes. The unit_conversions table tracks unit conversion factors with unique (from_unit, to_unit) pairs. Without these tables, the system cannot manage factor definitions and unit conversions.

## Pre-conditions

- TSK-P2-CCG-001-01 is complete
- Core contract gate has passed
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_preauth_002_00_work_item_01] Create PLAN.md from template
**What:** Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md from PLAN_TEMPLATE.md
**How:** Copy PLAN_TEMPLATE.md and fill in all required sections: objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections
**Done when:** PLAN.md file exists at docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md with all required sections filled

### [ID tsk_p2_preauth_002_00_work_item_02] Document factor_registry table requirements
**What:** Document the factor_registry table requirements
**How:** Add documentation specifying columns: factor_id UUID PRIMARY KEY, factor_code VARCHAR NOT NULL, factor_name VARCHAR NOT NULL, unit VARCHAR NOT NULL, and UNIQUE constraint on factor_code
**Done when:** PLAN.md contains explicit documentation of factor_registry table with UNIQUE constraint

### [ID tsk_p2_preauth_002_00_work_item_03] Document unit_conversions table requirements
**What:** Document the unit_conversions table requirements
**How:** Add documentation specifying columns: conversion_id UUID PRIMARY KEY, from_unit VARCHAR NOT NULL, to_unit VARCHAR NOT NULL, conversion_factor NUMERIC NOT NULL, and UNIQUE constraint on (from_unit, to_unit)
**Done when:** PLAN.md contains explicit documentation of unit_conversions table with UNIQUE constraint

### [ID tsk_p2_preauth_002_00_work_item_04] Run verify_plan_semantic_alignment.py
**What:** Validate proof graph integrity
**How:** Run python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-002-00/meta.yml
**Done when:** verify_plan_semantic_alignment.py exits 0 with NO_ORPHANS=true and GRAPH_CONNECTED=true

### [ID tsk_p2_preauth_002_00_work_item_05] Write the Negative Test Constraints
**What:** Define negative test constraints for plan verification
**How:** Document that verify_plan_semantic_alignment.py must fail on a plan with orphaned work items (missing acceptance criteria mapping)
**Done when:** Negative test N1 is documented in meta.yml and passes verification

## Verification

```bash
# [ID tsk_p2_preauth_002_00_work_item_01]
test -f docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_002_00_work_item_02]
grep -q "factor_registry" docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md &&
grep -q "factor_code" docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_002_00_work_item_03]
grep -q "unit_conversions" docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md &&
grep -q "from_unit" docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_002_00_work_item_04]
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-002-00/meta.yml || exit 1

# Validate evidence schema conformance
python3 scripts/audit/validate_evidence.py --task TSK-P2-PREAUTH-002-00 --evidence evidence/phase2/tsk_p2_preauth_002_00.json || exit 1

# Local parity check
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```


## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_002_00.json. Required fields:
- task_id: TSK-P2-PREAUTH-002-00
- git_sha: Current git commit SHA
- timestamp_utc: ISO-8601 timestamp in UTC
- status: One of PASS, FAIL, PARTIAL
- checks: Array of check results with name, status, message
- plan_path: Path to PLAN.md file
- graph_validation_enabled: true
- no_orphans: true if no orphaned work items
- graph_connected: true if proof graph is fully connected

## Rollback

Delete the PLAN.md file if it needs to be revised:
```bash
rm docs/plans/phase2/TSK-P2-PREAUTH-002-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| Table requirements incomplete | Low | High | Document all columns and constraints explicitly |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.

# TSK-P2-PREAUTH-005-00 PLAN — Create PLAN.md and verify alignment for state_transitions

Task: TSK-P2-PREAUTH-005-00
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-003-02, TSK-P2-PREAUTH-004-02
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-005-00.PLAN_CREATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the PLAN.md for the state_transitions and state_current tables plus 6 trigger functions. This task ensures the highest-risk schema changes (state machine + trigger layer) have architectural documentation and verification trace before implementation begins.

## Architectural Context

The state_transitions table tracks all state transitions with execution binding. The state_current table tracks current state for each project. Six trigger functions enforce state machine rules: enforce_transition_state_rules, enforce_transition_authority, enforce_transition_signature, enforce_execution_binding, deny_state_transitions_mutation, update_current_state. This is the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-003-02 and TSK-P2-PREAUTH-004-02 are complete
- execution_records and state_rules tables exist
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-005-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

## Implementation Steps

### Step 1: Create PLAN.md from template
**What:** `[ID tsk_p2_preauth_005_00_work_item_01]` Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-005-00/PLAN.md from PLAN_TEMPLATE.md
**How:** Copy template and fill with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections
**Done when:** PLAN.md exists at the specified path with all required sections populated

### Step 2: Document state_transitions table requirements
**What:** `[ID tsk_p2_preauth_005_00_work_item_02]` Document state_transitions table requirements in PLAN.md
**How:** Add section documenting columns: transition_id UUID PRIMARY KEY, project_id UUID NOT NULL, from_state VARCHAR NOT NULL, to_state VARCHAR NOT NULL, transition_timestamp TIMESTAMPTZ NOT NULL, execution_id UUID, policy_decision_id UUID, signature TEXT, and indexes on project_id and transition_timestamp
**Done when:** PLAN.md contains complete state_transitions table specification

### Step 3: Document state_current table requirements
**What:** `[ID tsk_p2_preauth_005_00_work_item_03]` Document state_current table requirements in PLAN.md
**How:** Add section documenting columns: project_id UUID PRIMARY KEY, current_state VARCHAR NOT NULL, state_since TIMESTAMPTZ NOT NULL
**Done when:** PLAN.md contains complete state_current table specification

### Step 4: Document 6 trigger functions
**What:** `[ID tsk_p2_preauth_005_00_work_item_04]` Document 6 trigger functions in PLAN.md
**How:** Add section documenting: enforce_transition_state_rules(), enforce_transition_authority(), enforce_transition_signature(), enforce_execution_binding(), deny_state_transitions_mutation(), update_current_state()
**Done when:** PLAN.md contains documentation for all 6 trigger functions

### Step 5: Run verify_plan_semantic_alignment.py
**What:** `[ID tsk_p2_preauth_005_00_work_item_05]` Validate proof graph integrity
**How:** Run: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-005-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-005-00/meta.yml
**Done when:** Script exits 0 with "Proof graph integrity PASSED"

## Verification

```bash
# DOCS_ONLY task - human review required
# No automated verification for plan creation
```


## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_00.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- plan_path
- graph_validation_enabled
- no_orphans
- graph_connected
- observed_paths

## Rollback

Delete the PLAN.md file if it needs to be revised:
```bash
rm docs/plans/phase2/TSK-P2-PREAUTH-005-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| Trigger functions not documented | Low | Critical | Document all 6 trigger functions explicitly |

## Approval

This is a DOCS_ONLY task for the HIGHEST RISK area. No regulated surface changes. No approval required beyond verification passing.

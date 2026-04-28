# Multi-Wave Consolidation Commit Fix - Implementation Plan

## Problem

The staged git commit contains work from multiple waves (Wave 4, 5, 6, 7, 8) but the commit message and exception file incorrectly describe it as only Wave 8 governance work. The structural detector is correctly flagging NEW DDL changes (migrations 0145-0171) that are being introduced in this commit.

## Root Cause

1. **Incorrect scope description**: Commit message says "TSK-P2-W8-GOV-001" but staged changes span Wave 4, 5, 6, 7, and 8
2. **False exception claim**: Exception file claims "no new DDL introduced" but migrations 0145-0171 are NEW files being added
3. **Missing Wave 7**: Wave 7 files (PREAUTH-007 series) are not acknowledged in the scope

## Solution

Update the exception file and commit message to accurately reflect the multi-wave consolidation scope.

## Implementation Steps

### Step 1: Update Exception File

**File**: `docs/invariants/exceptions/exception_change-rule_ddl_2026-04-27_6.md`

**Changes**:
- Update `exception_id` to `EXC-044`
- Update `follow_up_ticket` to `MULTI-WAVE-CONSOLIDATION-2026-04-27`
- Update `reason` to: "Multi-wave consolidation commit (Wave 4/5/6/7/8) with new DDL from Wave 5 stabilization"
- Update `Reason` section to explain:
  - This is a consolidation commit spanning Wave 4, 5, 6, 7, and 8 work
  - Wave 4: Verification script fixes (lost_verify/*.sh)
  - Wave 5: Stabilization fixes (migrations 0145-0171, FIX-01 through FIX-13 tasks)
  - Wave 6: Contract pack updates (sqlstate_map, README)
  - Wave 7: PREAUTH-007 series tasks (007-06 through 007-19)
  - Wave 8: Governance truth repair (TSK-P2-W8-* tasks, plans, metadata hardening)
  - Migrations 0145-0171 are NEW DDL changes from Wave 5 stabilization work
- Update `Mitigation` section to explain:
  - The new migrations (0145-0171) are part of Wave 5 stabilization work
  - They are being consolidated with Wave 4/6/7/8 work in a single commit
  - Invariants linkage will be addressed in follow-up Wave 5 closure tasks

### Step 2: Update Commit Message

**New commit message**:
```
[Multi-Wave Consolidation] Wave 4/5/6/7/8 integration and metadata hardening

Wave 4:
- Verification script fixes (lost_verify/*.sh)

Wave 5:
- Stabilization fixes (migrations 0145-0171)
- FIX-01 through FIX-13 tasks for state machine trigger layer
- New DDL: enforce_transition_authority fix, trigger hardening, state transitions schema

Wave 6:
- Contract pack updates (sqlstate_map.wave6.merge.json, README_WAVE6_PACK.md)

Wave 7:
- PREAUTH-007 series tasks (007-06 through 007-19)
- State machine trigger layer implementation

Wave 8:
- Governance truth repair (TSK-P2-W8-* tasks)
- Task packs and plans integration
- MIGRATION_HEAD to regulated_paths for DB tasks
- Dynamic IP discovery and baseline drift guidance
- WAVE8_GAP_TO_DOD_TASK_GENERATION_PLAN.md to docs/plans/phase2/
- .NET 10 Preview SDK/runtime pinning to immutable SHA256 digests

General:
- Cleaned incidental churn per EVIDENCE_CHURN_CLEANUP_POLICY.md
- Updated approvals, docs, evidence

Exception: EXC-044 (multi-wave consolidation with new DDL from Wave 5)
```

### Step 3: Execute Git Commit

Run the git commit command with the updated commit message.

### Step 4: Delete system_snapshot/ Directory

After successful push, delete the `system_snapshot/` directory as it was only for debugging.

## Verification

- Exception file accurately describes the multi-wave scope
- Commit message lists all wave-specific changes
- Git commit succeeds without structural detector errors
- system_snapshot/ is deleted after push

## Stop Conditions

- If git commit still fails after updates, investigate what other files are causing structural changes
- If the exception file is rejected by CI, ensure all required fields are populated correctly

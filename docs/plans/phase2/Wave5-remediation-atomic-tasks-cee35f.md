# Wave 5 Remediation Plan - Updated for Current State (0137-0144)

## Context

Wave 5 implementation (migrations 0137-0144) is complete but contains gaps identified in Wave-5-for-Devin.md. The original REM tasks (01-11) were designed for a monolithic migration 0120 and are now misaligned with the current atomic migration structure.

## Audit Findings

### Current State of Migrations 0137-0144

**0137 (state_transitions table):**
- 11 columns including execution_id, policy_decision_id, transition_hash (all NOT NULL)
- Weak constraint: `UNIQUE(entity_type, entity_id, execution_id)` - allows multiple transitions if execution is reused
- 4 indexes including idx_state_transitions_entity

**0138 (state_current table):**
- 4 columns including last_transition_id with FK to state_transitions
- PK is `project_id` (incorrect per Wave-5-for-Devin.md - should be `(entity_type, entity_id)`)

**0139-0144 (Trigger functions):**
- All use RAISE EXCEPTION (not RAISE NOTICE)
- Triggers are hollow stubs - they don't execute the relational joins required to validate rules
- 0143 error string: "Direct mutation of state_transitions is not allowed..." (incorrect - should be "state_transitions is append-only")
- 0144 trigger name: `trg_update_current_state` (incorrect - should be `trg_06_update_current` for explicit ordering)

### Original REM Tasks Status

**Redundant (Already Done in 0137/0138):**
- REM-01: Add NOT NULL to execution_id (already NOT NULL in 0137)
- REM-02: Add NOT NULL to policy_decision_id (already NOT NULL in 0137)
- REM-04: Add last_transition_id column (already exists in 0138)
- REM-05: Add FK constraint (already exists in 0138)
- REM-09: Add transition_hash column (already exists in 0137)

**Misdirected (Won't Fix Logic Gaps):**
- REM-06, REM-07, REM-08: Target exception type (already RAISE EXCEPTION) but ignore missing JOIN logic

**Anti-Pattern (Actively Harmful):**
- REM-03: Implements weak constraint `UNIQUE(entity_type, entity_id, execution_id)` - already in 0137

**Incomplete:**
- REM-10: Identifies crypto need but doesn't implement functions
- REM-11: Identifies project_id flaw but targets wrong table (state_transitions instead of state_current)

## Updated Remediation Plan

### Task 1: Rewrite REM-03 - Fix Idempotency Constraint
- **Delete**: `UNIQUE(entity_type, entity_id, execution_id)` from 0137
- **Add**: `UNIQUE(entity_type, entity_id, transition_hash)` to 0137
- **Rationale**: Weak constraint allows multiple transitions if execution is reused. Wave-5-for-Devin.md requires hash-based idempotency.
- **Depends on**: Wave 5 implementation complete
- **Touches**: schema/migrations/0137_create_state_transitions.sql, MIGRATION_HEAD

### Task 2: Rewrite REM-06 - Add State Rules Validation Logic
- **Replace**: Hollow trigger with actual JOIN to state_rules table
- **Implementation**: Add query to verify state transition is valid per state_rules
- **Rationale**: Current trigger only checks NULL values, doesn't validate actual state rules
- **Depends on**: REM-03
- **Touches**: schema/migrations/0139_create_enforce_transition_state_rules.sql, MIGRATION_HEAD

### Task 3: Rewrite REM-07 - Add Authority Validation Logic
- **Replace**: Hollow trigger with actual JOIN to policy_decisions table
- **Implementation**: Add query to verify entity type and decision type match
- **Rationale**: Current trigger only checks policy_decision_id presence, doesn't validate authority
- **Depends on**: REM-06
- **Touches**: schema/migrations/0140_create_enforce_transition_authority.sql, MIGRATION_HEAD

### Task 4: Rewrite REM-08 - Add Execution Binding Validation Logic
- **Replace**: Hollow trigger with actual JOIN to execution_records table
- **Implementation**: Add query to ensure interpretation_version_id NOT NULL
- **Rationale**: Current trigger doesn't validate execution binding requirements
- **Depends on**: REM-07
- **Touches**: schema/migrations/0142_create_enforce_execution_binding.sql, MIGRATION_HEAD

### Task 5: Rewrite REM-10 - Implement Cryptographic Functions
- **Add**: ed25519 signature verification function
- **Add**: hash recomputation logic in enforce_transition_signature trigger
- **Rationale**: Wave-5-for-Devin.md requires cryptographic contract validation
- **Depends on**: REM-08
- **Touches**: schema/migrations/0141_create_enforce_transition_signature.sql, MIGRATION_HEAD

### Task 6: Rewrite REM-11 - Fix Projection Architecture
- **Change PK in 0138**: From `project_id` to `(entity_type, entity_id)`
- **Update 0144 trigger**: Modify update_current_state to use correct PK
- **Rename trigger in 0144**: From `trg_update_current_state` to `trg_06_update_current`
- **Rationale**: Wave-5-for-Devin.md requires generic entity model, not project-specific. Trigger naming enforces explicit ordering.
- **Depends on**: REM-10
- **Touches**: schema/migrations/0138_create_state_current.sql, schema/migrations/0144_create_update_current_state.sql, MIGRATION_HEAD

### Task 7: New REM Task - Fix Append-Only Error String
- **Change error string in 0143**: From "Direct mutation of state_transitions is not allowed..." to "state_transitions is append-only"
- **Rationale**: Wave-5-for-Devin.md requires exact error string for negative test verification
- **Depends on**: REM-11
- **Touches**: schema/migrations/0143_create_deny_state_transitions_mutation.sql, MIGRATION_HEAD

## Complete Execution Order (7 Tasks Total)

1. **REM-03 (Rewritten)**: Fix idempotency constraint in 0137
2. **REM-06 (Rewritten)**: Add state rules validation logic in 0139
3. **REM-07 (Rewritten)**: Add authority validation logic in 0140
4. **REM-08 (Rewritten)**: Add execution binding validation logic in 0142
5. **REM-10 (Rewritten)**: Implement cryptographic functions in 0141
6. **REM-11 (Rewritten)**: Fix projection architecture in 0138 and 0144, rename trigger
7. **New REM Task**: Fix append-only error string in 0143

## Implementation Approach

**For Each Remediation Task Implementation (Mandatory Sequence):**

1. **Pre-Edit Documentation (Before touching any file):**
   - Create Stage A approval artifact: `approvals/YYYY-MM-DD/BRANCH-<branch-name>.md`
   - Create Stage A approval sidecar: `approvals/YYYY-MM-DD/BRANCH-<branch-name>.approval.json`
   - Validate with approval_metadata.schema.json
   - Update EXEC_LOG.md with initial entry including failure_signature, origin_task_id, repro_command

2. **File Modification:**
   - Edit migration file or trigger function
   - Update EXEC_LOG.md with exact change made

3. **Post-Edit Documentation:**
   - Update EXEC_LOG.md with verification_commands_run and final_status
   - Run conformance check with `--mode=stage-a --branch=<branch-name>`

4. **After PR Opening:**
   - Create Stage B approval artifact: `approvals/YYYY-MM-DD/PR-<number>.md`
   - Create Stage B approval sidecar: `approvals/YYYY-MM-DD/PR-<number>.approval.json`
   - Run conformance check with `--mode=stage-b --pr=<PR-number>`

## Key Considerations

1. **Migration Modification**: Remediation tasks modify migrations 0137-0144 - this is intentional schema drift that must be documented in EXEC_LOG.md

2. **MIGRATION_HEAD Updates**: Each remediation task will increment MIGRATION_HEAD (0144 → 0145 → 0146, etc.) - must track carefully

3. **Regulated Surface Compliance (CRITICAL):**
   - All migration modifications (schema/migrations/**) are regulated surfaces per REGULATED_SURFACE_PATHS.yml
   - MUST NOT edit any migration file without prior approval metadata
   - Approval artifacts MUST be created BEFORE editing regulated surfaces

4. **Remediation Trace Compliance (CRITICAL):**
   - schema/** is a production-affecting surface requiring remediation trace per REMEDIATION_TRACE_WORKFLOW.md
   - Task PLAN.md/EXEC_LOG.md pair satisfies remediation trace requirement
   - EXEC_LOG.md MUST include all required markers: failure_signature, origin_task_id, repro_command, verification_commands_run, final_status

5. **Baseline Regeneration**: After each migration modification, must regenerate schema baseline per ADR-0010

6. **Trigger Ordering**: Trigger names with numeric prefixes (trg_06_update_current) enforce explicit execution order as required by Wave-5-for-Devin.md

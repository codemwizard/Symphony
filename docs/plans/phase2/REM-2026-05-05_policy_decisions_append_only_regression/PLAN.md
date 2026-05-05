# REMEDIATION PLAN

Canonical-Reference: docs/operations/REMEDIATION_TRACE_WORKFLOW.md

failure_signature: SCHEMA.POLICY_DECISIONS.APPEND_ONLY_REGRESSION

origin_task_id: TSK-P2-W8-DB-006

origin_gate_id: code_review

repro_command: grep -n -A 2 -B 2 "RAISE EXCEPTION.*GF060" schema/migrations/*.sql

verification_commands_run: pending

final_status: OPEN

## Scope

**In-scope:**
- Migration file containing the append-only regression (lines 95-96)
- Trigger logic for policy_decisions table
- Verification of append-only contract enforcement

**Out-of-scope:**
- Other policy_decisions table migrations
- Unrelated schema changes

## Initial Hypotheses

1. Migration author intended to fix specific DELETE-only case but inadvertently broadened trigger scope
2. Original append-only contract required blocking both UPDATE and DELETE operations
3. Change breaks immutability guarantees for policy decision records

## Derived Tasks

- TSK-P2-W8-DB-006-REM-01: Fix append-only trigger to block both UPDATE and DELETE
- TSK-P2-W8-DB-006-REM-02: Add automated test for append-only enforcement
- TSK-P2-W8-DB-006-REM-03: Verify no other similar regressions exist

## Risk Assessment

**Criticality:** HIGH - Breaks core immutability guarantees
**Blast Radius:** policy_decisions table integrity
**Dependencies:** None - can be fixed independently

# TSK-HARD-020 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-020

- task_id: TSK-HARD-020
- title: Adjustment instruction schema and lifecycle
- phase: Hardening
- wave: 2
- depends_on: [TSK-OPS-WAVE1-EXIT-GATE]
- goal: Define and migrate the adjustment instruction table with its full lifecycle
  state machine. An adjustment is an additive correction to a terminal parent
  instruction — it never mutates the parent. This task establishes the schema
  foundation that all Wave-2 governance tasks build on.
- required_deliverables:
  - adjustment instruction table schema and DB migration (expand/contract compliant)
  - state enum with all required values
  - parent_instruction_id FK constraint
  - append-only enforcement (no UPDATE/DELETE on parent instruction from adjustment path)
  - tasks/TSK-HARD-020/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_020.json
- verifier_command: bash scripts/audit/verify_tsk_hard_020.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_020.json
- schema_path: evidence/schemas/hardening/tsk_hard_020.schema.json
- acceptance_assertions:
  - adjustment instruction table exists with state enum containing exactly:
    requested, pending_approval, cooling_off, eligible_execute, executed,
    denied, blocked_legal_hold — no other values permitted
  - parent_instruction_id is a non-nullable FK to the instruction table;
    an adjustment row cannot be inserted without a valid parent
  - no DB path exists that mutates a column on the parent instruction row
    via the adjustment code path; verified by static analysis of migration
    and triggers
  - schema migration is expand/contract compliant and reversible; verifier
    confirms the down-migration restores prior state cleanly
  - migration does not acquire DDL locks on the instruction table during
    apply; lock-risk lint passes
  - evidence artifact schema-valid and contains: task_id, migration_id,
    state_enum_values[], parent_fk_confirmed: true, pass
  - negative-path test: attempting to insert an adjustment row with a
    null parent_instruction_id fails with FK constraint error
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - parent instruction mutated via adjustment code path => FAIL_CLOSED
  - state enum missing any required value => FAIL
  - migration not reversible => FAIL
  - migration acquires DDL lock => FAIL
  - negative-path test absent => FAIL

---

# TSK-HARD-022 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-022

- task_id: TSK-HARD-022
- title: Execution attempt model, idempotency, and value ceiling
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-021]
- goal: Implement the execution attempt model with idempotency enforcement and
  cumulative value ceiling. The ceiling is enforced at the DB layer — not only
  at the application layer. A series of partial adjustments against the same
  parent instruction must not collectively exceed the original instruction value.
  Ceiling breach fails-closed with a named error and produces evidence.
- required_deliverables:
  - execution attempt table schema and migration
  - idempotency key per execution attempt
  - DB-layer cumulative ceiling enforcement (check constraint or trigger)
  - named error P7201 ADJUSTMENT_CEILING_BREACH
  - ceiling breach evidence artifact
  - tasks/TSK-HARD-022/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_022.json
- verifier_command: bash scripts/audit/verify_tsk_hard_022.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_022.json
- schema_path: evidence/schemas/hardening/tsk_hard_022.schema.json
- acceptance_assertions:
  - execution attempt table exists with fields: attempt_id, adjustment_id,
    idempotency_key, adjustment_value, attempt_timestamp, dispatch_reference,
    outcome
  - idempotency_key is unique per adjustment_id; duplicate key on same
    adjustment_id is rejected with named error, not applied twice
  - adjustment_value field is non-nullable; zero-value adjustments require
    explicit justification field
  - cumulative ceiling enforced at DB layer: sum of adjustment_value across all
    executed attempts against the same parent_instruction_id must not exceed
    the original instruction value; this is a DB check constraint or trigger —
    not solely an application-layer check
  - ceiling breach attempt fails with P7201 ADJUSTMENT_CEILING_BREACH before
    any state change occurs
  - ceiling breach produces evidence artifact schema-valid against
    adjustment_approval_event class (TSK-HARD-002) and contains: adjustment_id,
    parent_instruction_id, breach_amount, ceiling_value, cumulative_executed,
    outcome: CEILING_BREACH
  - negative-path test: submitting a sequence of adjustments whose cumulative
    value exceeds parent instruction value — last adjustment fails with P7201
    and produces breach evidence artifact; parent instruction state unchanged
  - negative-path test: replaying an execution attempt with same idempotency_key
    is rejected; not applied twice
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - duplicate execution attempt applied => FAIL_CLOSED
  - cumulative ceiling absent or enforced only at application layer => FAIL_CLOSED
  - ceiling breach produces no evidence artifact => FAIL
  - ceiling breach does not fail before state change => FAIL_CLOSED
  - negative-path tests absent => FAIL

---

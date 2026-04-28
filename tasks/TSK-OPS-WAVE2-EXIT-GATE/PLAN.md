# TSK-OPS-WAVE2-EXIT-GATE PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-OPS-WAVE2-EXIT-GATE

- task_id: TSK-OPS-WAVE2-EXIT-GATE
- title: Wave-2 Exit Gate
- phase: Hardening
- wave: 2
- depends_on:
    [TSK-HARD-020, TSK-HARD-021, TSK-HARD-022, TSK-HARD-023,
     TSK-HARD-025, TSK-HARD-026, TSK-HARD-024]
- goal: Deterministic Wave-2 pass/fail gate. All five negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Gate script exits
  non-zero if any artifact is missing, invalid, or failing. Wave-3 tasks are
  BLOCKED until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave2_exit_gate.sh
  - evidence/phase1/program_wave2_exit_gate.json
  - evidence/phase1/wave2_exit/adjustment_ceiling_breach.json
  - evidence/phase1/wave2_exit/recipient_redirect_blocked.json
  - evidence/phase1/wave2_exit/cooling_off_execution_blocked.json
  - evidence/phase1/wave2_exit/p7101_terminal_update_blocked.json
  # Freeze-flag artifacts (one per flag type; shared schema)
  - evidence/phase1/wave2_exit/freeze_flag_participant_suspended.json
  - evidence/phase1/wave2_exit/freeze_flag_account_frozen.json
  - evidence/phase1/wave2_exit/freeze_flag_aml_hold.json
  - evidence/phase1/wave2_exit/freeze_flag_regulator_stop.json
  - evidence/phase1/wave2_exit/freeze_flag_program_hold.json
- verifier_command: bash scripts/audit/verify_program_wave2_exit_gate.sh
- evidence_path: evidence/phase1/program_wave2_exit_gate.json
- schema_path: evidence/schemas/hardening/wave2_exit/wave2_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave2_exit/adjustment_ceiling_breach.schema.json
  - evidence/schemas/hardening/wave2_exit/recipient_redirect_blocked.schema.json
  - evidence/schemas/hardening/wave2_exit/cooling_off_execution_blocked.schema.json
  - evidence/schemas/hardening/wave2_exit/freeze_flag_execution_blocked.schema.json
  - evidence/schemas/hardening/wave2_exit/p7101_terminal_update_blocked.schema.json
- acceptance_assertions:
  - all required_deliverables evidence artifacts exist
  - gate script validates each artifact against its schema in schema_set before
    emitting pass; checking existence and pass=true alone is insufficient
  - each artifact contains pass=true
  - gate script exits non-zero if any artifact is missing, fails schema
    validation, or contains pass=false
  - gate script is deterministic: identical inputs produce identical exit code
  - specific field requirements per artifact:
    - adjustment_ceiling_breach.json: contains adjustment_id,
      parent_instruction_id, breach_amount, ceiling_value,
      outcome: CEILING_BREACH
    - recipient_redirect_blocked.json: contains adjustment_id,
      attempted_recipient, error_code: P7504, outcome: REJECTED
    - cooling_off_execution_blocked.json: contains adjustment_id,
      state_at_attempt: cooling_off, error_code: P7701, outcome: BLOCKED
    - freeze_flag_*.json: contains adjustment_id, flag_type, error_code: P7702,
      outcome: BLOCKED (exactly one artifact per flag type listed above)
    - p7101_terminal_update_blocked.json: contains adjustment_id,
      terminal_state_at_attempt, sqlstate: P7101, outcome: BLOCKED
  - Wave-3 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - any artifact contains pass=false => FAIL_CLOSED
  - gate validates only existence and pass=true without schema validation
    => FAIL_CLOSED (gate script itself is defective)
  - manual override of gate result => FAIL_CLOSED (not permitted)

---

## Wave 3 Task Packs

Wave-3 entry gate: TSK-OPS-WAVE2-EXIT-GATE must be pass=true before any Wave-3
task may be marked done.

---

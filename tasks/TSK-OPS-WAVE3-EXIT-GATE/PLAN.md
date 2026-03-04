# TSK-OPS-WAVE3-EXIT-GATE PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-OPS-WAVE3-EXIT-GATE

- task_id: TSK-OPS-WAVE3-EXIT-GATE
- title: Wave-3 Exit Gate
- phase: Hardening
- wave: 3
- depends_on:
    [TSK-HARD-030, TSK-HARD-031, TSK-HARD-032, TSK-HARD-033]
- goal: Deterministic Wave-3 pass/fail gate. All four negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Wave-4 tasks are
  BLOCKED until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave3_exit_gate.sh
  - evidence/phase1/program_wave3_exit_gate.json
  - evidence/phase1/wave3_exit/reference_allocation_retry_exhausted.json
  - evidence/phase1/wave3_exit/reference_length_exceeded.json
  - evidence/phase1/wave3_exit/truncation_collision_blocked.json
  - evidence/phase1/wave3_exit/unregistered_reference_blocked.json
- verifier_command: bash scripts/audit/verify_program_wave3_exit_gate.sh
- evidence_path: evidence/phase1/program_wave3_exit_gate.json
- schema_path: evidence/schemas/hardening/wave3_exit/wave3_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave3_exit/reference_allocation_retry_exhausted.schema.json
  - evidence/schemas/hardening/wave3_exit/reference_length_exceeded.schema.json
  - evidence/schemas/hardening/wave3_exit/truncation_collision_blocked.schema.json
  - evidence/schemas/hardening/wave3_exit/unregistered_reference_blocked.schema.json
- acceptance_assertions:
  - all 4 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - gate script exits non-zero if any artifact is missing, fails schema
    validation, or contains pass=false
  - specific field requirements per artifact:
    - reference_allocation_retry_exhausted.json: contains reference_attempted,
      collision_count, strategy_used, outcome: EXHAUSTED
    - reference_length_exceeded.json: contains reference_attempted, rail_max_length,
      reference_length, error_code: P7901, outcome: REJECTED
    - truncation_collision_blocked.json: contains original_reference,
      truncated_reference, colliding_registry_entry_id,
      outcome: TRUNCATION_COLLISION_BLOCKED
    - unregistered_reference_blocked.json: contains reference_attempted,
      instruction_id, error_code: P8001, outcome: UNREGISTERED_BLOCKED
  - Wave-4 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - gate validates only existence without schema validation => FAIL_CLOSED
  - manual override => FAIL_CLOSED (not permitted)

---

## Wave 4 Task Packs

Wave-4 entry gate: TSK-OPS-WAVE3-EXIT-GATE must be pass=true before any Wave-4
task may be marked done.

Note: TSK-HARD-051 completion is the point at which all Wave-1 through Wave-3
unsigned_reason=DEPENDENCY_NOT_READY evidence artifacts must be retroactively
re-signed with back-linkage. The EXEC_LOG.md for TSK-HARD-051 must include a
re-sign sweep record confirming all prior DEPENDENCY_NOT_READY artifacts have
been re-signed and their re_sign_timestamp and re_sign_key_id fields populated.

---

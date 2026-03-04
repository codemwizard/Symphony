# TSK-OPS-WAVE6-EXIT-GATE PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-OPS-WAVE6-EXIT-GATE

- task_id: TSK-OPS-WAVE6-EXIT-GATE
- title: Wave-6 Exit Gate — Hardening Program Complete
- phase: Hardening
- wave: 6
- depends_on:
    [TSK-HARD-080, TSK-HARD-081, TSK-HARD-082, TSK-HARD-090, TSK-HARD-091,
     TSK-HARD-092, TSK-HARD-093, TSK-HARD-095, TSK-HARD-098, TSK-HARD-040,
     TSK-HARD-041, TSK-HARD-042, TSK-HARD-100]
- goal: Deterministic hardening program completion gate. All six negative-path
  evidence artifacts must be present, schema-valid, and pass=true. Passing this
  gate constitutes completion of the hardening program. The program may not claim
  "evidence-grade" institutional status until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave6_exit_gate.sh
  - evidence/phase1/program_wave6_exit_gate.json
  - evidence/phase1/wave6_exit/hsm_outage_fail_closed.json
  - evidence/phase1/wave6_exit/boz_scenario_all_six_pass.json
  - evidence/phase1/wave6_exit/pii_absent_from_evidence_tables.json
  - evidence/phase1/wave6_exit/erased_subject_purge_placeholder.json
  - evidence/phase1/wave6_exit/rate_limit_breach_blocked.json
  - evidence/phase1/wave6_exit/retraction_secondary_approval_enforced.json
- verifier_command: bash scripts/audit/verify_program_wave6_exit_gate.sh
- evidence_path: evidence/phase1/program_wave6_exit_gate.json
- schema_path: evidence/schemas/hardening/wave6_exit/wave6_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave6_exit/hsm_outage_fail_closed.schema.json
  - evidence/schemas/hardening/wave6_exit/boz_scenario_all_six_pass.schema.json
  - evidence/schemas/hardening/wave6_exit/pii_absent_from_evidence_tables.schema.json
  - evidence/schemas/hardening/wave6_exit/erased_subject_purge_placeholder.schema.json
  - evidence/schemas/hardening/wave6_exit/rate_limit_breach_blocked.schema.json
  - evidence/schemas/hardening/wave6_exit/retraction_secondary_approval_enforced.schema.json
- acceptance_assertions:
  - all 6 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - gate script exits non-zero if any artifact is missing, fails schema
    validation, or contains pass=false
  - gate script explicitly checks all prior wave exit gate evidence artifacts
    (program_wave1 through program_wave5) and confirms each has pass=true;
    transitive depends_on coverage is not sufficient — script must verify
    each by reading the artifacts directly
  - gate script explicitly checks evidence/phase1/hardening/tsk_hard_102.json
    exists and contains pass=true; TSK-HARD-102 is the Wave-5 regulator
    continuity gate and is a separate check from program_wave5_exit_gate.json;
    a gate script that checks only the wave exit gate artifact and omits
    tsk_hard_102.json check is defective (FAIL_CLOSED)
  - specific field requirements per artifact:
    - hsm_outage_fail_closed.json: contains simulated_outage_duration,
      fallback_attempted: false, outcome: FAIL_CLOSED
    - boz_scenario_all_six_pass.json: contains scenario_ids[] (all six),
      all_exits_zero: true, all_evidence_schema_valid: true
    - pii_absent_from_evidence_tables.json: contains tables_scanned[],
      pii_fields_found: 0, scan_timestamp
    - erased_subject_purge_placeholder.json: contains token_hash,
      status: PURGED, purge_evidence_ref, query_returned_404: false
    - rate_limit_breach_blocked.json: contains action_type, actor_id,
      outcome: RATE_LIMITED, breach_evidence_produced: true
    - retraction_secondary_approval_enforced.json: contains action_type,
      initiator_id, approval_attempted_without_secondary: true,
      outcome: SECONDARY_APPROVAL_REQUIRED
  - gate evidence artifact contains: hardening_program_complete: true,
    all_waves_confirmed: [1,2,3,4,5,6], tsk_hard_102_confirmed: true,
    gate_timestamp
  - hardening program is not considered complete until this gate passes;
    no claim of "evidence-grade" institutional status may be made until
    this artifact exists with pass=true and hardening_program_complete: true
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - any artifact contains pass=false => FAIL_CLOSED
  - tsk_hard_102.json absent or pass=false => FAIL_CLOSED
  - any prior wave exit gate artifact absent or pass=false => FAIL_CLOSED
  - gate emits hardening_program_complete: true before all wave exit gates
    and tsk_hard_102 have been confirmed => FAIL_CLOSED (gate script is defective)
  - manual override => FAIL_CLOSED (not permitted)

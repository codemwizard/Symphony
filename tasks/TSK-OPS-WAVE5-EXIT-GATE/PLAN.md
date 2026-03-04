# TSK-OPS-WAVE5-EXIT-GATE PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-OPS-WAVE5-EXIT-GATE

- task_id: TSK-OPS-WAVE5-EXIT-GATE
- title: Wave-5 Exit Gate
- phase: Hardening
- wave: 5
- depends_on:
    [TSK-HARD-060, TSK-HARD-061, TSK-HARD-062, TSK-HARD-070, TSK-HARD-071,
     TSK-HARD-072, TSK-HARD-073, TSK-HARD-074, TSK-HARD-097, TSK-HARD-099,
     TSK-HARD-102]
- goal: Deterministic Wave-5 pass/fail gate. All five negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Wave-6 tasks are
  BLOCKED until this gate passes.
- required_deliverables:
  - scripts/audit/verify_program_wave5_exit_gate.sh
  - evidence/phase1/program_wave5_exit_gate.json
  - evidence/phase1/wave5_exit/unverifiable_missing_canonicalizer.json
  - evidence/phase1/wave5_exit/pka_entry_update_blocked.json
  - evidence/phase1/wave5_exit/bundle_access_quorum_rejected.json
  - evidence/phase1/wave5_exit/regulator_write_denied.json
  - evidence/phase1/wave5_exit/dr_recovery_end_to_end_pass.json
- verifier_command: bash scripts/audit/verify_program_wave5_exit_gate.sh
- evidence_path: evidence/phase1/program_wave5_exit_gate.json
- schema_path: evidence/schemas/hardening/wave5_exit/wave5_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave5_exit/unverifiable_missing_canonicalizer.schema.json
  - evidence/schemas/hardening/wave5_exit/pka_entry_update_blocked.schema.json
  - evidence/schemas/hardening/wave5_exit/bundle_access_quorum_rejected.schema.json
  - evidence/schemas/hardening/wave5_exit/regulator_write_denied.schema.json
  - evidence/schemas/hardening/wave5_exit/dr_recovery_end_to_end_pass.schema.json
- acceptance_assertions:
  - all 5 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - specific field requirements per artifact:
    - unverifiable_missing_canonicalizer.json: contains artifact_id,
      canonicalization_version_requested, error: UNVERIFIABLE_MISSING_CANONICALIZER,
      outcome: FAIL
    - pka_entry_update_blocked.json: contains entry_id, attempted_operation: UPDATE,
      outcome: BLOCKED
    - bundle_access_quorum_rejected.json: contains ceremony_id,
      authority_categories_present[], quorum_met: false, outcome: REJECTED
    - regulator_write_denied.json: contains accessor_id, attempted_operation,
      error_code: P8301, outcome: DENIED
    - dr_recovery_end_to_end_pass.json: contains ceremony_evidence_ref,
      artifacts_verified[], operational_runtime_used: false,
      artifact_types_covered[] (minimum 3 distinct types), all_outcomes: PASS
  - Wave-6 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - dr_recovery evidence shows operational_runtime_used: true => FAIL_CLOSED
  - manual override => FAIL_CLOSED (not permitted)

---

## Wave 6 Task Packs

Wave-6 entry gate: TSK-OPS-WAVE5-EXIT-GATE must be pass=true before any Wave-6
task may be marked done.

---

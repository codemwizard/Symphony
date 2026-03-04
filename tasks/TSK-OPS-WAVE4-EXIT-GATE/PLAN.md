# TSK-OPS-WAVE4-EXIT-GATE PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-OPS-WAVE4-EXIT-GATE

- task_id: TSK-OPS-WAVE4-EXIT-GATE
- title: Wave-4 Exit Gate
- phase: Hardening
- wave: 4
- depends_on:
    [TSK-HARD-050, TSK-HARD-051, TSK-HARD-052, TSK-HARD-053,
     TSK-HARD-054, TSK-HARD-011B, TSK-HARD-096]
- goal: Deterministic Wave-4 pass/fail gate. All five negative-path evidence
  artifacts must be present, schema-valid, and pass=true. Wave-5 tasks are
  BLOCKED until this gate passes. Additionally confirms the DEPENDENCY_NOT_READY
  re-sign sweep and assurance tier sweep are complete.
- required_deliverables:
  - scripts/audit/verify_program_wave4_exit_gate.sh
  - evidence/phase1/program_wave4_exit_gate.json
  - evidence/phase1/wave4_exit/key_class_unauthorized_rejected.json
  - evidence/phase1/wave4_exit/hsm_bypass_blocked.json
  - evidence/phase1/wave4_exit/unsigned_policy_bundle_rejected.json
  - evidence/phase1/wave4_exit/historical_verification_archive_only.json
  - evidence/phase1/wave4_exit/dependency_not_ready_resign_sweep.json
- verifier_command: bash scripts/audit/verify_program_wave4_exit_gate.sh
- evidence_path: evidence/phase1/program_wave4_exit_gate.json
- schema_path: evidence/schemas/hardening/wave4_exit/wave4_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave4_exit/key_class_unauthorized_rejected.schema.json
  - evidence/schemas/hardening/wave4_exit/hsm_bypass_blocked.schema.json
  - evidence/schemas/hardening/wave4_exit/unsigned_policy_bundle_rejected.schema.json
  - evidence/schemas/hardening/wave4_exit/historical_verification_archive_only.schema.json
  - evidence/schemas/hardening/wave4_exit/dependency_not_ready_resign_sweep.schema.json
- acceptance_assertions:
  - all 5 artifact paths listed in required_deliverables exist
  - gate script validates each artifact against its schema before emitting pass
  - each artifact contains pass=true
  - specific field requirements per artifact:
    - key_class_unauthorized_rejected.json: contains caller_id,
      requested_key_class, error_code: P8101, outcome: REJECTED
    - hsm_bypass_blocked.json: contains attempted_signing_path: SOFTWARE_BYPASS,
      outcome: BLOCKED
    - unsigned_policy_bundle_rejected.json: contains policy_id, error_code: P8201,
      outcome: ACTIVATION_REJECTED
    - historical_verification_archive_only.json: contains key_versions_tested[],
      operational_store_excluded: true, all_outcomes: PASS
    - dependency_not_ready_resign_sweep.json: contains sweep_completed_timestamp,
      artifacts_resigned_count, artifacts_with_pending_tier_assignment_cleared: true
  - Wave-5 tasks are BLOCKED until this gate passes
- failure_modes:
  - any artifact missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - dependency_not_ready_resign_sweep artifact absent or incomplete => FAIL_CLOSED
  - manual override => FAIL_CLOSED (not permitted)

---

## Wave 5 Task Packs

Wave-5 entry gate: TSK-OPS-WAVE4-EXIT-GATE must be pass=true before any Wave-5
task may be marked done.

---

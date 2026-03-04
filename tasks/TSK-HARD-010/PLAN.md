# TSK-HARD-010 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-010

- task_id: TSK-HARD-010
- title: Rail uncertainty model and inquiry policy framework
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-002]
- goal: Define the complete model for how the system behaves when a rail returns
  silence, contradiction, or garbage. This task produces the policy framework
  document and the rail scenario matrix that all downstream inquiry and containment
  tasks implement against. No runtime code is required; the output is a specification
  that is testable and frozen.
- required_deliverables:
  - docs/programs/symphony-hardening/INQUIRY_POLICY_FRAMEWORK.md
  - docs/programs/symphony-hardening/RAIL_SCENARIO_MATRIX.md
  - tasks/TSK-HARD-010/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_010.json
- verifier_command: bash scripts/audit/verify_tsk_hard_010.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_010.json
- schema_path: evidence/schemas/hardening/tsk_hard_010.schema.json
- acceptance_assertions:
  - INQUIRY_POLICY_FRAMEWORK.md exists and defines the following fields for each
    policy entry: rail_id (wildcard permitted), cadence_seconds, retry_window_seconds,
    max_attempts, timeout_threshold_seconds, orphan_threshold_seconds,
    circuit_breaker_threshold_rate, circuit_breaker_window_seconds
  - RAIL_SCENARIO_MATRIX.md exists and contains one row per scenario type; minimum
    required scenario types: SILENT_RAIL, CONFLICTING_FINALITY, LATE_CALLBACK,
    MALFORMED_RESPONSE, PARTIAL_RESPONSE, TIMEOUT_EXCEEDED
  - each scenario row defines: scenario_type, description, expected_system_response,
    evidence_artifact_type, implementing_task_id
  - implementing_task_id in each row references a real task ID in TRACEABILITY_MATRIX
  - no scenario row has a missing or placeholder implementing_task_id
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - INQUIRY_POLICY_FRAMEWORK.md missing => FAIL_CLOSED
  - RAIL_SCENARIO_MATRIX.md missing => FAIL_CLOSED
  - fewer than 6 scenario types defined => FAIL
  - any scenario row missing implementing_task_id => FAIL
  - implementing_task_id references non-existent task => FAIL

---

# TSK-HARD-024 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-024

- task_id: TSK-HARD-024
- title: Terminal immutability enforcement (P7101) on adjustment tables
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-026]
- goal: Deploy the P7101 terminal immutability trigger on the adjustment
  instruction table. Any direct UPDATE on a row whose state is terminal
  (executed, denied, blocked_legal_hold) must raise SQLSTATE P7101.
  This mirrors the existing P7101 enforcement on the parent instruction
  table and closes the gap where adjustment records could be silently
  edited after reaching a terminal state.
- required_deliverables:
  - P7101 trigger deployed on adjustment instruction table
  - terminal states covered: executed, denied, blocked_legal_hold
  - negative-path test for each terminal state
  - tasks/TSK-HARD-024/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_024.json
- verifier_command: bash scripts/audit/verify_tsk_hard_024.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_024.json
- schema_path: evidence/schemas/hardening/tsk_hard_024.schema.json
- acceptance_assertions:
  - P7101 trigger exists on adjustment instruction table; verifier confirms
    trigger presence by querying DB information_schema or equivalent
  - trigger fires on any UPDATE to a row where current state is in
    (executed, denied, blocked_legal_hold)
  - trigger raises SQLSTATE P7101; UPDATE is not applied
  - trigger covers all three terminal states individually; not only one
  - negative-path test for each terminal state: direct UPDATE attempt raises
    P7101; row state is unchanged after attempt; verified by querying row
    before and after UPDATE attempt
  - P7101 trigger does not interfere with legitimate state transitions
    (e.g. transition to executed from eligible_execute is not blocked)
  - evidence artifact contains: task_id, trigger_name, terminal_states_covered[],
    negative_path_outcomes[], pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - P7101 trigger absent from adjustment table => FAIL_CLOSED
  - direct UPDATE on any terminal state row permitted => FAIL_CLOSED
  - trigger covers fewer than three terminal states => FAIL
  - legitimate state transitions blocked by trigger => FAIL
  - negative-path test absent for any terminal state => FAIL

---

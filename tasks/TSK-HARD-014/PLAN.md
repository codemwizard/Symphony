# TSK-HARD-014 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-014

- task_id: TSK-HARD-014
- title: Late callback reconciliation — orphaned attestation landing zone
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-013, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a persistent, queryable orphaned attestation landing zone that
  receives callbacks arriving after their parent instruction has reached a terminal
  or EXHAUSTED state. Late callbacks must not be discarded, must not mutate
  instruction state, and must produce evidence artifacts for audit retrieval.
- required_deliverables:
  - orphaned attestation landing zone (persistent, queryable store — not a log)
  - late callback routing logic (detects terminal/EXHAUSTED parent state and
    routes to landing zone instead of instruction state machine)
  - late callback evidence artifact
  - tasks/TSK-HARD-014/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_014.json
- verifier_command: bash scripts/audit/verify_tsk_hard_014.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_014.json
- schema_path: evidence/schemas/hardening/tsk_hard_014.schema.json
- acceptance_assertions:
  - orphaned attestation landing zone is a persistent store queryable by
    instruction_id, arrival_timestamp, and classification
  - landing zone is separate from the main instruction state tables (not a
    flag on the instruction row)
  - late callback routing: on callback arrival, system checks parent instruction
    state; if state is terminal or EXHAUSTED the callback is routed to landing
    zone, not applied to instruction
  - each landing zone record contains: callback_payload_hash, arrival_timestamp,
    instruction_id, instruction_state_at_arrival, classification: LATE_CALLBACK
  - late callback evidence artifact is schema-valid against
    orphaned_attestation_event schema (registered in TSK-HARD-002)
  - negative-path test: sending a callback after instruction reaches terminal state
    produces a landing zone record and does not mutate instruction state; verified
    by querying instruction state before and after callback arrival
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - late callback mutates terminal instruction state => FAIL_CLOSED
  - late callback silently discarded (no landing zone record) => FAIL
  - landing zone is a log (append-only text) rather than a queryable store => FAIL
  - landing zone record missing any required field => FAIL
  - negative-path test absent => FAIL

---

# TSK-HARD-012 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-012

- task_id: TSK-HARD-012
- title: Rail inquiry engine — SCHEDULED, SENT, ACKNOWLEDGED, EXHAUSTED state machine
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-011A, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement the rail inquiry engine with an explicit, DB-enforced state machine
  governing inquiry lifecycle. The core invariant: no instruction may be
  auto-finalized while its inquiry is in an uncertain or exhausted state. The
  EXHAUSTED state is a holding state, not a resolution state.
- required_deliverables:
  - inquiry state machine implementation with DB-enforced state enum:
    SCHEDULED, SENT, ACKNOWLEDGED, EXHAUSTED
  - state transition guards (illegal transitions rejected with named SQLSTATE)
  - auto-finalization prohibition: code path that attempts to finalize an
    instruction while inquiry is EXHAUSTED must be blocked and evidenced
  - tasks/TSK-HARD-012/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_012.json
- verifier_command: bash scripts/audit/verify_tsk_hard_012.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_012.json
- schema_path: evidence/schemas/hardening/tsk_hard_012.schema.json
- acceptance_assertions:
  - inquiry state enum exists in DB with values: SCHEDULED, SENT, ACKNOWLEDGED,
    EXHAUSTED — no other values permitted
  - state transitions enforced: SCHEDULED → SENT on dispatch confirmation only;
    SENT → ACKNOWLEDGED on confirmed rail response only; SENT → EXHAUSTED on
    max-attempts-exceeded per policy loaded from TSK-HARD-011 metadata;
    ACKNOWLEDGED → no further inquiry states (terminal for inquiry, not for
    instruction)
  - EXHAUSTED is a holding state: instruction remains in its pre-finalization state
    when inquiry reaches EXHAUSTED — no automatic progression to any outcome state
  - any code path that attempts to auto-finalize an instruction while inquiry state
    is EXHAUSTED is intercepted and fails-closed with named error
    (e.g. P7301 INQUIRY_EXHAUSTED_AUTO_FINALIZE_BLOCKED)
  - auto-finalization intercept produces an evidence artifact of event class
    inquiry_event containing: instruction_id, inquiry_state: EXHAUSTED,
    attempted_action: AUTO_FINALIZE, outcome: BLOCKED
  - negative-path test: simulating max-attempts-exceeded drives inquiry to
    EXHAUSTED; subsequent auto-finalization attempt produces P7301 and evidence
    artifact; instruction state is unchanged
  - max_attempts threshold resolved from policy metadata (TSK-HARD-011) — not
    hardcoded
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - auto-finalization permitted from EXHAUSTED state => FAIL_CLOSED
  - auto-finalization intercept produces no evidence artifact => FAIL
  - max_attempts hardcoded rather than policy-resolved => FAIL_CLOSED
  - illegal state transition silently permitted => FAIL_CLOSED
  - negative-path test absent => FAIL

---

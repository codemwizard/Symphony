# TSK-HARD-015 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-015

- task_id: TSK-HARD-015
- title: Conflicting truth containment — FINALITY_CONFLICT state machine
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-014, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement deterministic detection and containment of contradictory finality
  signals from different rails or counterparties. FINALITY_CONFLICT must be a
  named, directly queryable state in the instruction state enum — not a derived
  condition inferred from logs. Containment holds all release; no auto-resolution
  is permitted.
- required_deliverables:
  - FINALITY_CONFLICT state added to instruction state enum in DB
  - conflict detection logic (contradictory signals → FINALITY_CONFLICT transition)
  - conflict containment: release hold while in FINALITY_CONFLICT
  - FINALITY_CONFLICT evidence artifact (structured conflict pack)
  - tasks/TSK-HARD-015/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_015.json
- verifier_command: bash scripts/audit/verify_tsk_hard_015.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_015.json
- schema_path: evidence/schemas/hardening/tsk_hard_015.schema.json
- acceptance_assertions:
  - FINALITY_CONFLICT is a value in the instruction state enum in the DB — its
    presence confirmed by querying the enum type directly (not by log inspection)
  - contradictory finality signals (example: rail_a confirms SUCCESS, rail_b
    confirms FAILED for same instruction) deterministically trigger transition
    to FINALITY_CONFLICT state
  - FINALITY_CONFLICT state holds all release: no funds movement, no
    auto-resolution, no automatic progression to any outcome state permitted
  - transition to FINALITY_CONFLICT is irreversible without an explicit human
    operator action that is itself recorded in evidence
  - FINALITY_CONFLICT evidence artifact is schema-valid against
    finality_conflict_record schema (registered in TSK-HARD-002) and contains:
    instruction_id, contradiction_timestamp, rail_a_id, rail_a_response,
    rail_b_id, rail_b_response, conflict_classification, containment_action:
    HOLD_RELEASE
  - negative-path test: supplying contradictory finality signals produces
    FINALITY_CONFLICT state and evidence artifact; instruction state confirmed
    FINALITY_CONFLICT by direct DB query; no release occurs
  - resolution of FINALITY_CONFLICT requires explicit operator action with
    secondary approval; resolution action produces evidence artifact
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - FINALITY_CONFLICT absent from DB state enum => FAIL_CLOSED
  - FINALITY_CONFLICT only detectable by log inspection => FAIL_CLOSED
    (must be directly queryable as a state value)
  - contradictory signals produce silent resolution to any outcome => FAIL_CLOSED
  - release occurs while instruction is in FINALITY_CONFLICT => FAIL_CLOSED
  - FINALITY_CONFLICT evidence artifact not schema-valid => FAIL
  - negative-path test absent => FAIL

---

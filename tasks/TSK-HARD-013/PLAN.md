# TSK-HARD-013 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-013

- task_id: TSK-HARD-013
- title: Effect sealing enforcement
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-012, TSK-OPS-A1-STABILITY-GATE]
- goal: Compute and store effect_seal_hash at instruction seal time. Enforce that
  outbound dispatch payload hash equals the stored seal. Any mismatch fails-closed
  pre-dispatch and produces an evidence artifact. This prevents silent payload
  mutation between instruction sealing and dispatch.
- required_deliverables:
  - effect_seal_hash computation and storage at seal time
  - pre-dispatch hash equality check (outbound payload hash vs stored seal)
  - mismatch evidence artifact
  - tasks/TSK-HARD-013/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_013.json
- verifier_command: bash scripts/audit/verify_tsk_hard_013.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_013.json
- schema_path: evidence/schemas/hardening/tsk_hard_013.schema.json
- acceptance_assertions:
  - effect_seal_hash computed and stored at instruction seal time using a
    deterministic canonicalization of the instruction payload
  - canonicalization algorithm is identified by canonicalization_version in the
    seal record (references TSK-HARD-052 standard, may be stub at this stage)
  - pre-dispatch check computes hash of outbound payload and compares to stored
    effect_seal_hash; mismatch causes dispatch to be rejected before sending
  - mismatch produces evidence artifact containing: instruction_id,
    stored_seal_hash, computed_dispatch_hash, mismatch_detected: true,
    dispatch_blocked: true, timestamp
  - mismatch evidence is of event class inquiry_event or a dedicated
    seal_mismatch_event class; if dedicated class, schema registered in
    TSK-HARD-002 schema set
  - negative-path test: mutating the outbound payload after sealing produces a
    mismatch evidence artifact and dispatch is blocked; instruction state is
    unchanged
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - mismatch not detected pre-dispatch => FAIL_CLOSED
  - mismatch detected but dispatch proceeds => FAIL_CLOSED
  - mismatch produces no evidence artifact => FAIL
  - hash comparison performed post-dispatch => FAIL_CLOSED
  - negative-path test absent => FAIL

---

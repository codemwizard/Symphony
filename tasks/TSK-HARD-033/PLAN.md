# TSK-HARD-033 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-033

- task_id: TSK-HARD-033
- title: Reference registry linkage enforcement
- phase: Hardening
- wave: 3
- depends_on: [TSK-HARD-032]
- goal: Enforce that every outbound dispatch references a registered entry in the
  registry from TSK-HARD-031. Dispatch without a registry entry is blocked.
  Adjusted references (from adjustment dispatches) are accepted when a registry
  entry exists for the adjustment_id. Rail-rejected duplicates produce evidence
  artifacts that reference the original dispatch registry entry.
- required_deliverables:
  - pre-dispatch registry linkage check
  - rejection evidence for unregistered references
  - adjusted reference acceptance logic
  - duplicate rejection evidence artifact
  - tasks/TSK-HARD-033/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_033.json
- verifier_command: bash scripts/audit/verify_tsk_hard_033.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_033.json
- schema_path: evidence/schemas/hardening/tsk_hard_033.schema.json
- acceptance_assertions:
  - pre-dispatch check confirms reference exists in registry before any outbound
    call is made; absence blocks dispatch with named error
    (e.g. P8001 REFERENCE_NOT_REGISTERED)
  - unregistered reference rejection produces evidence artifact containing:
    reference_attempted, instruction_id, outcome: UNREGISTERED_BLOCKED
  - adjusted references (dispatched for an adjustment_id) are accepted when
    the registry contains an entry with matching adjustment_id and
    allocated_reference; no special bypass is required
  - when a rail rejects a dispatch as a duplicate (rail-level duplicate
    rejection): the system records a duplicate rejection evidence artifact
    that references the original dispatch registry entry by registry_id
  - duplicate rejection evidence artifact contains: reference, rail_rejection_code,
    original_registry_entry_id, rejection_timestamp
  - negative-path test: dispatching with an unregistered reference fails with
    P8001 and produces rejection evidence; wire is not touched
  - negative-path test: dispatch with a registry entry for adjustment_id
    succeeds (adjusted reference accepted)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - unregistered reference dispatched to wire => FAIL_CLOSED
  - unregistered reference rejection produces no evidence => FAIL
  - rail-rejected duplicate produces no evidence artifact => FAIL
  - adjusted reference rejected when valid registry entry exists => FAIL
  - negative-path tests absent => FAIL

---

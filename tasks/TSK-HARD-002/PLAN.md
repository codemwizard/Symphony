# TSK-HARD-002 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-002

- task_id: TSK-HARD-002
- title: Evidence event class schema registration
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-001]
- goal: Register all hardening event class schemas into the schema set that
  validate_evidence_schema.sh actually reads and enforces. This is the contract
  that governs what a valid evidence artifact looks like for every new event type
  introduced by the hardening program. The docs/architecture/ mirror is
  informational only and carries no gate weight.
- required_deliverables:
  - evidence/schemas/hardening/event_classes/inquiry_event.schema.json
  - evidence/schemas/hardening/event_classes/malformed_quarantine_event.schema.json
  - evidence/schemas/hardening/event_classes/orphaned_attestation_event.schema.json
  - evidence/schemas/hardening/event_classes/finality_conflict_record.schema.json
  - evidence/schemas/hardening/event_classes/adjustment_approval_event.schema.json
  - evidence/schemas/hardening/event_classes/policy_activation_event.schema.json
  - evidence/schemas/hardening/event_classes/pka_snapshot_event.schema.json
  - evidence/schemas/hardening/event_classes/canonicalization_archive_event.schema.json
  - evidence/schemas/hardening/event_classes/dr_ceremony_event.schema.json
  - evidence/schemas/hardening/event_classes/verification_continuity_event.schema.json
  - docs/architecture/EVIDENCE_EVENT_CLASSES.md  [informational mirror — not gating]
  - tasks/TSK-HARD-002/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_002.json
- verifier_command: bash scripts/audit/verify_tsk_hard_002.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_002.json
- schema_path: evidence/schemas/hardening/tsk_hard_002.schema.json
- acceptance_assertions:
  - all 10 event class schema files listed above exist under
    evidence/schemas/hardening/event_classes/
  - each schema file is valid JSON Schema (draft-07 or later)
  - each schema enforces additionalProperties: false at top level
  - scripts/audit/validate_evidence_schema.sh discovers and loads all 10 schemas
    automatically (no manual registration step required per schema)
  - validate_evidence_schema.sh run against a minimal valid sample for each event
    class returns exit 0
  - validate_evidence_schema.sh run against a sample with a missing required field
    for each event class returns exit non-zero
  - docs/architecture/EVIDENCE_EVENT_CLASSES.md exists as human-readable mirror
    but is NOT referenced in any verifier or gate script as a gating input
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the 10 schema files missing => FAIL_CLOSED
  - validate_evidence_schema.sh does not load schemas automatically => FAIL
  - schema permits additionalProperties at top level => FAIL
  - docs mirror referenced as a gate input in any script => FAIL_REVIEW
    (violates FIX-3: docs must not be the enforcement surface)

---

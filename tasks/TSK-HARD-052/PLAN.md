# TSK-HARD-052 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-052

- task_id: TSK-HARD-052
- title: Signature metadata completeness standard
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-051]
- goal: Establish and enforce the signature metadata standard for all evidence
  artifacts. Every signed artifact must carry a complete set of provenance fields.
  Missing any required field causes deterministic verification failure — not silent
  acceptance. The standard document is the normative reference; the schema in the
  evidence schema set is the enforcement surface.
- required_deliverables:
  - signature metadata standard document at
    docs/architecture/SIGNATURE_METADATA_STANDARD.md
  - enforcement in signing path: all required fields populated before artifact
    is returned
  - validation test: missing any required field causes schema validation failure
  - tasks/TSK-HARD-052/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_052.json
- verifier_command: bash scripts/audit/verify_tsk_hard_052.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_052.json
- schema_path: evidence/schemas/hardening/tsk_hard_052.schema.json
- acceptance_assertions:
  - every signed evidence artifact contains all required fields: key_id,
    key_version, algorithm, canonicalization_version, signature_timestamp,
    signing_service_id, trust_chain_ref, assurance_tier
  - when artifact is part of a Merkle batch (TSK-HARD-080), additional fields
    required: merkle_root, leaf_index, merkle_proof
  - missing any required field causes deterministic schema validation failure
    (validate_evidence_schema.sh exits non-zero); not silent acceptance
  - signing path populates all required fields before returning artifact to
    caller; caller cannot omit any field
  - SIGNATURE_METADATA_STANDARD.md is informational; schema in
    evidence/schemas/hardening/ is the enforcement surface
  - negative-path test: artifact with canonicalization_version field absent
    fails schema validation; artifact with signing_service_id absent fails
    schema validation; verified per field individually
  - negative-path test: batch artifact missing merkle_proof field fails
    schema validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - missing required metadata field silently accepted => FAIL_CLOSED
  - canonicalization_version absent from any signed artifact => FAIL_CLOSED
  - assurance_tier absent (added retroactively once TSK-HARD-096 is complete;
    if TSK-HARD-096 not yet done, field must be present with value
    PENDING_TIER_ASSIGNMENT — not absent) => FAIL
  - Merkle metadata absent from any batch artifact => FAIL
  - docs standard used as enforcement surface => FAIL_REVIEW
  - negative-path tests absent => FAIL

---

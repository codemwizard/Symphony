# TSK-HARD-042 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-042

- task_id: TSK-HARD-042
- title: Privacy-preserving audit query continuity
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-041]
- goal: Confirm that audit query responses remain coherent, structured, and
  evidenced after erasure events. A query for an erased subject must return
  a structured PURGED placeholder — not a 404, not an error, not an empty
  result. The purge evidence linkage must be queryable. The evidence chain
  continuity is documented, not a silent hole.
- required_deliverables:
  - structured PURGED placeholder response for erased subjects
  - purge evidence linkage (queryable by purge_evidence_ref)
  - evidence chain continuity documentation
  - post-erasure query test
  - tasks/TSK-HARD-042/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_042.json
- verifier_command: bash scripts/audit/verify_tsk_hard_042.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_042.json
- schema_path: evidence/schemas/hardening/tsk_hard_042.schema.json
- acceptance_assertions:
  - audit query for an erased subject token returns a structured placeholder:
    {token_hash, status: PURGED, purge_evidence_ref, erasure_timestamp}
  - structured placeholder is schema-valid and consistently returned for all
    erased subjects — no variation in response structure
  - purge evidence linkage: given purge_evidence_ref from the placeholder,
    the erasure evidence artifact from TSK-HARD-041 is retrievable; linkage
    confirmed by querying by erasure_id
  - evidence chain continuity confirmed: the gap left by erasure is documented
    in the evidence chain with a purge_marker and linkage; it is not a silent
    hole visible to auditors
  - negative-path test: querying an erased subject does not return HTTP 404 or
    any unstructured error; returns structured PURGED placeholder
  - negative-path test: querying a non-existent (never-registered) subject
    token returns NOT_FOUND (distinct from PURGED) — to confirm the two states
    are distinguishable
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - erased subject query returns 404 or unstructured error => FAIL
  - PURGED and NOT_FOUND responses are indistinguishable => FAIL
  - structured placeholder absent or non-schema-valid => FAIL
  - purge evidence linkage not queryable => FAIL_CLOSED
  - negative-path tests absent => FAIL

---

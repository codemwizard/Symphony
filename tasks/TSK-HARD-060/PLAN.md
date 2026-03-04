# TSK-HARD-060 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-060

- task_id: TSK-HARD-060
- title: Canonicalization version registry
- phase: Hardening
- wave: 5
- depends_on: [TSK-OPS-WAVE4-EXIT-GATE]
- goal: Implement the frozen canonicalization spec registry. Each version entry
  is immutable once activated. Test vectors are executable. The registry is
  independently queryable without operational runtime dependency. This is the
  foundation that TSK-HARD-061 (historical verifier loader) and TSK-HARD-062
  (archive snapshots) build on.
- required_deliverables:
  - canonicalization version registry store (append-only, independently queryable)
  - one frozen entry per active canonicalization version
  - executable test vectors per version
  - activation and deprecation metadata
  - tasks/TSK-HARD-060/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_060.json
- verifier_command: bash scripts/audit/verify_tsk_hard_060.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_060.json
- schema_path: evidence/schemas/hardening/tsk_hard_060.schema.json
- acceptance_assertions:
  - registry exists and is independently queryable without operational runtime
    dependency (e.g. can be queried from a read-only replica or exported snapshot)
  - each registry entry contains: version_id, spec_document_hash,
    implementation_package_ref, test_vectors_ref, activation_date,
    deprecation_date (nullable), entry_timestamp
  - spec documents are immutable once activated: UPDATE to spec_document_hash
    on an activated entry is blocked; verifier confirms via negative-path test
  - test vectors are stored alongside the spec and are executable — not
    documentation-only; verifier runs test vectors for each version and confirms
    they pass against the corresponding implementation package
  - registry is append-only: no DELETE on existing entries; verifier confirms
    via negative-path test
  - negative-path test: attempting to update spec_document_hash on an activated
    entry is rejected with a named error
  - negative-path test: attempting to delete an entry from the registry is
    rejected with a named error
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - spec document mutable after activation => FAIL_CLOSED
  - test vectors not executable => FAIL
  - registry entries deletable => FAIL_CLOSED
  - registry requires operational runtime to query => FAIL
  - negative-path tests absent => FAIL

---

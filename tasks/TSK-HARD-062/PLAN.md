# TSK-HARD-062 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-062

- task_id: TSK-HARD-062
- title: Archive integrity continuity — signed canonicalization snapshots
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-061]
- goal: Produce canonicalization archive snapshots that are cryptographically
  signed with key class PCSK. Each snapshot packages all active canonicalization
  versions, their spec hashes, and their test vectors. Offsite replication is
  confirmed with a linkage record. This produces the portable archive that
  TSK-HARD-072 (DR recovery bundle) packages.
- required_deliverables:
  - canonicalization archive snapshot generator
  - signed snapshot manifest (PCSK-signed)
  - offsite replication linkage record
  - tasks/TSK-HARD-062/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_062.json
- verifier_command: bash scripts/audit/verify_tsk_hard_062.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_062.json
- schema_path: evidence/schemas/hardening/tsk_hard_062.schema.json
- acceptance_assertions:
  - archive snapshot packages: all active and deprecated canonicalization
    versions with spec_document_hash, implementation_package_ref,
    test_vectors_ref, and activation_date for each
  - snapshot manifest is signed with key class PCSK (from TSK-HARD-050);
    signature verified at snapshot creation time
  - manifest contains: snapshot_timestamp, canonicalization_versions_included[],
    manifest_hash, signing_key_id, assurance_tier
  - offsite replication linkage record produced after snapshot and confirms:
    snapshot_id, offsite_location_ref, replication_timestamp,
    integrity_check_outcome: PASS
  - offsite replication linkage record is schema-valid against
    canonicalization_archive_event class (TSK-HARD-002)
  - snapshot can be used to independently verify historical artifacts without
    operational runtime dependency; confirmed by isolated verification test
  - negative-path test: snapshot with missing spec_document_hash for any
    included version fails snapshot manifest validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - snapshot manifest unsigned => FAIL_CLOSED
  - snapshot signed with wrong key class (not PCSK) => FAIL
  - offsite replication not confirmed => FAIL
  - snapshot missing any active canonicalization version => FAIL
  - negative-path test absent => FAIL

---

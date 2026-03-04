# TSK-HARD-054 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-054

- task_id: TSK-HARD-054
- title: Historical verification continuity (archive-only)
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-053]
- goal: Confirm that artifacts signed under each historical key version remain
  verifiable using archived key material only, with the operational key store
  completely excluded. Verification failure for a missing version produces a
  named error — not a silent pass. This task establishes the baseline that the
  Wave-5 five-year horizon simulation (TSK-HARD-099) extends.
- required_deliverables:
  - archive-only verification environment setup (operational store excluded)
  - historical verification test across all key versions in rotation history
  - named error modes for missing material
  - tasks/TSK-HARD-054/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_054.json
- verifier_command: bash scripts/audit/verify_tsk_hard_054.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_054.json
- schema_path: evidence/schemas/hardening/tsk_hard_054.schema.json
- acceptance_assertions:
  - test environment configured with operational key store explicitly excluded;
    EXEC_LOG.md confirms exclusion method (environment variable, network block,
    or equivalent)
  - at least one artifact signed under each historical key version in the
    rotation history is successfully verified using archived key material only
  - verification result for each historical key version recorded in evidence
    artifact: key_version, artifact_verified, archived_material_used,
    operational_store_excluded: true, outcome
  - missing key version in archive produces UNVERIFIABLE_MISSING_KEY named error
    — not a silent pass or a fallback to operational store
  - missing canonicalization version in archive produces
    UNVERIFIABLE_MISSING_CANONICALIZER named error — not a silent pass
  - neither UNVERIFIABLE_MISSING_KEY nor UNVERIFIABLE_MISSING_CANONICALIZER
    is treated as a passing state in any test or CI check; verifier script
    confirms absence of these error codes in passing test output
  - negative-path test: requesting verification of an artifact whose key
    version has been deliberately removed from the archive produces
    UNVERIFIABLE_MISSING_KEY; outcome is FAIL, not PASS
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - verification falls back to operational key store => FAIL_CLOSED
  - missing key version produces silent pass => FAIL_CLOSED
  - missing canonicalization version produces silent pass => FAIL_CLOSED
  - UNVERIFIABLE error treated as passing in any test => FAIL_CLOSED
  - historical key versions not all covered by test => FAIL
  - negative-path test absent => FAIL

---

# TSK-HARD-061 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-061

- task_id: TSK-HARD-061
- title: Historical verifier loader — no fallback to latest
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-060]
- goal: Implement the historical verifier that resolves the exact canonicalization
  version used at signing time from the registry. No fallback to current or latest
  version is permitted. If the exact version is absent from the registry, the
  verifier produces UNVERIFIABLE_MISSING_CANONICALIZER — not a silent pass, not a
  retry with a different version.
- required_deliverables:
  - historical verifier loader implementation
  - version resolution logic (reads canonicalization_version from artifact
    signature metadata, loads exact version from registry)
  - UNVERIFIABLE_MISSING_CANONICALIZER error mode
  - tasks/TSK-HARD-061/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_061.json
- verifier_command: bash scripts/audit/verify_tsk_hard_061.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_061.json
- schema_path: evidence/schemas/hardening/tsk_hard_061.schema.json
- acceptance_assertions:
  - historical verifier reads canonicalization_version from the artifact's
    signature metadata (field defined in TSK-HARD-052 standard)
  - verifier loads exact spec version from registry by version_id — no fallback
    to current/latest permitted; verifier confirms by static analysis that no
    fallback code path exists
  - if exact version_id is absent from registry: verification fails with
    named error UNVERIFIABLE_MISSING_CANONICALIZER; outcome is FAIL not PASS
  - UNVERIFIABLE_MISSING_CANONICALIZER is not caught and swallowed anywhere
    in the codebase; verifier confirms by grep for catch blocks around this
    error code
  - verification result contains: artifact_id, canonicalization_version_requested,
    canonicalization_version_found (or null if absent), outcome
  - negative-path test: artifact with canonicalization_version set to a value
    absent from registry produces UNVERIFIABLE_MISSING_CANONICALIZER;
    outcome is FAIL; no silent fallback occurs
  - negative-path test: artifact with canonicalization_version present in
    registry is verified successfully
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - fallback to latest canonicalization version occurs => FAIL_CLOSED
  - missing version produces silent pass => FAIL_CLOSED
  - UNVERIFIABLE_MISSING_CANONICALIZER swallowed by catch block => FAIL_CLOSED
  - verification result missing canonicalization_version_requested field => FAIL
  - negative-path tests absent => FAIL

---

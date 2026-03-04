# TSK-HARD-090 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-090

- task_id: TSK-HARD-090
- title: QA matrix hardening completeness
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-082]
- goal: Extend the QA matrix to cover all hardening negative-path scenarios.
  The matrix is the authoritative record of what is tested. Each entry must
  reference a specific executable test. Ten scenarios are required; none may
  be deferred or combined.
- required_deliverables:
  - extended QA matrix document at docs/programs/symphony-hardening/QA_MATRIX.md
  - executable test script or test case reference per scenario
  - test coverage evidence artifact
  - tasks/TSK-HARD-090/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_090.json
- verifier_command: bash scripts/audit/verify_tsk_hard_090.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_090.json
- schema_path: evidence/schemas/hardening/tsk_hard_090.schema.json
- acceptance_assertions:
  - QA matrix exists and each entry contains: scenario_id, description,
    expected_outcome, test_script_ref (path to executable test),
    evidence_artifact_path, pass_fail_status
  - exactly ten required scenarios present; none may be absent:
    QA-01 TOXIC_PAYLOAD_INJECTION: one test per parser classification
      (TRANSPORT, PROTOCOL, SYNTAX, SEMANTIC) — four tests required
    QA-02 TRUNCATION_COLLISION: two distinct references truncating to same
      value detected as collision; collision evidence artifact produced
    QA-03 ROLE_TAMPERING_ATTEMPT: approver submits approval with manipulated
      role claim; attestation captures original role; tampered claim rejected
    QA-04 COOLING_OFF_PLUS_AML_HOLD: both active simultaneously; execution
      blocked; combined hold evidence artifact produced
    QA-05 ALIAS_COLLISION_NONCE_EXHAUSTION: nonce retry limit exhausted;
      P7801 produced; exhaustion evidence artifact produced
    QA-06 MISSING_CANONICALIZER_VERSION:
      UNVERIFIABLE_MISSING_CANONICALIZER produced; no silent pass
    QA-07 HSM_OUTAGE: signing service fails-closed; no software fallback;
      outage evidence artifact produced
    QA-08 KMS_REGION_OUTAGE: signing service fails-closed; no fallback
      to alternate region; region outage evidence artifact produced
    QA-09 DR_ARCHIVE_ACCESS_WITHOUT_QUORUM: bundle access blocked;
      rejection evidence artifact produced
    QA-10 BATCH_MERKLE_PROOF_MISSING_LEAF: verification fails
      deterministically for leaf not in batch; not a silent pass
  - each QA entry's test_script_ref points to a file that exists and is
    executable; verifier confirms existence of all referenced scripts
  - all ten scenarios pass when verifier runs the test suite
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the ten required scenarios absent from QA matrix => FAIL
  - any scenario_id entry lacks a test_script_ref => FAIL
  - any referenced test script does not exist or is not executable => FAIL
  - any QA scenario test fails => FAIL
  - QA-01 covers fewer than all four parser classification types => FAIL

---

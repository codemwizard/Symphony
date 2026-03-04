# TSK-HARD-097 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-097

- task_id: TSK-HARD-097
- title: Recovery continuity proof — end-to-end DR path
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-074]
- goal: Produce evidence that the full recovery path from DR bundle retrieval
  through quorum ceremony through isolated verification is functional end-to-end.
  No step may require access to the operational runtime. At least three historical
  artifacts of distinct types must be verified. This task is the end-to-end
  integration test of the entire Wave-5 trust continuity stack.
- required_deliverables:
  - end-to-end recovery continuity test script
  - continuity evidence artifact
  - tasks/TSK-HARD-097/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_097.json
- verifier_command: bash scripts/audit/verify_tsk_hard_097.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_097.json
- schema_path: evidence/schemas/hardening/tsk_hard_097.schema.json
- acceptance_assertions:
  - end-to-end test performs these steps in order: (1) retrieve DR bundle via
    quorum ceremony (produces ceremony evidence artifact), (2) decrypt bundle
    using quorum-derived key, (3) restore PKA and canonicalization archive to
    an isolated environment, (4) verify at least three historical artifacts of
    distinct types using restored archives only, (5) confirm each verification
    produces a signed verification result
  - each of the five steps is individually evidenced and referenced in the
    continuity evidence artifact
  - continuity evidence artifact contains: test_timestamp, ceremony_evidence_ref,
    bundle_decrypted: true, artifacts_verified[], artifact_types_covered[],
    operational_runtime_used: false, verification_outcomes[], pass
  - artifact_types_covered must contain at least three distinct values
    (e.g. inquiry_event, finality_conflict_record, adjustment_approval_event)
  - evidence artifact is schema-valid against verification_continuity_event
    class (TSK-HARD-002)
  - test fails with explicit error if any step requires operational runtime
    access; the isolation constraint is machine-enforced, not relying on
    operator discipline
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any step accesses operational runtime => FAIL_CLOSED
  - fewer than three distinct artifact types verified => FAIL
  - any step not individually evidenced => FAIL
  - continuity evidence artifact not schema-valid => FAIL
  - test passes without performing quorum ceremony => FAIL_CLOSED

---

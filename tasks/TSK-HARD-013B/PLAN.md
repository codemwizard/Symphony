# TSK-HARD-013B PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-013B

- task_id: TSK-HARD-013B
- title: Orphan and replay containment
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-101, TSK-HARD-014, TSK-OPS-A1-STABILITY-GATE]
- goal: Classify and contain orphan events (events whose parent instruction cannot
  be resolved or is in an incompatible state) and prevent replay-based state
  corruption. Orphan events that are not late callbacks (handled in TSK-HARD-014)
  are classified here. Replay detection must be idempotency-key or
  message-fingerprint based — not state-based.
- required_deliverables:
  - orphan classification logic: LATE_CALLBACK (delegated to TSK-HARD-014),
    DUPLICATE_DISPATCH, UNKNOWN_REFERENCE, REPLAY_ATTEMPT
  - replay detection via idempotency key or message fingerprint
  - orphan evidence artifact per classification type
  - tasks/TSK-HARD-013B/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_013b.json
- verifier_command: bash scripts/audit/verify_tsk_hard_013b.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_013b.json
- schema_path: evidence/schemas/hardening/tsk_hard_013b.schema.json
- acceptance_assertions:
  - orphan events classified into exactly: LATE_CALLBACK (routed to TSK-HARD-014
    landing zone), DUPLICATE_DISPATCH, UNKNOWN_REFERENCE, REPLAY_ATTEMPT
  - classification is deterministic: same event always produces same classification
  - replay detection: each processed event has an idempotency_key or
    message_fingerprint stored; re-presentation of a previously processed event
    is detected by key/fingerprint lookup before state mutation
  - replay attempt produces containment evidence artifact schema-valid against
    orphaned_attestation_event schema and contains: event_fingerprint,
    original_processing_timestamp, replay_detected_timestamp,
    classification: REPLAY_ATTEMPT, action: REJECTED
  - replay attempt is rejected — not applied to instruction state
  - DUPLICATE_DISPATCH and UNKNOWN_REFERENCE are also rejected and produce
    evidence artifacts with respective classification values
  - negative-path test: replaying a previously processed event produces
    REPLAY_ATTEMPT classification and evidence artifact; instruction state
    unchanged; verified by querying state before and after replay attempt
  - negative-path test: submitting event with unknown instruction reference
    produces UNKNOWN_REFERENCE classification and evidence artifact
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - replay attempt applied to instruction state => FAIL_CLOSED
  - replay detection absent (no idempotency key or fingerprint check) => FAIL_CLOSED
  - any classification type absent from implementation => FAIL
  - containment evidence artifact not schema-valid => FAIL
  - negative-path test absent => FAIL

---

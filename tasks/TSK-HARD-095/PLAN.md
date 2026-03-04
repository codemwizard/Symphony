# TSK-HARD-095 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-095

- task_id: TSK-HARD-095
- title: BoZ submission audit trail primitives
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-093]
- goal: Implement the audit trail primitives for all BoZ regulatory submissions.
  Every submission produces an evidence artifact. Submission evidence is
  append-only. Every read of submission evidence is access-logged.
- required_deliverables:
  - BoZ submission evidence schema at
    evidence/schemas/hardening/boz_submission_event.schema.json
  - submission evidence artifact per submission
  - append-only enforcement on submission evidence store
  - access log for submission evidence reads
  - tasks/TSK-HARD-095/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_095.json
- verifier_command: bash scripts/audit/verify_tsk_hard_095.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_095.json
- schema_path: evidence/schemas/hardening/tsk_hard_095.schema.json
- acceptance_assertions:
  - every BoZ regulatory submission produces an evidence artifact schema-valid
    against boz_submission_event schema and containing: submission_id,
    report_type, submission_timestamp, signing_key_id, submission_hash,
    outcome, assurance_tier
  - submission evidence is stored in an append-only store; UPDATE and DELETE
    on submission evidence records are blocked at DB layer
  - access log records every read of submission evidence: accessor_id,
    role, access_timestamp, session_id, submission_ids_accessed[]
  - access log is itself append-only and signed
  - submission evidence and its access log are independently queryable
  - negative-path test: attempting UPDATE on a submission evidence record
    is rejected and produces rejection evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - submission produces no evidence artifact => FAIL_CLOSED
  - submission evidence store not append-only => FAIL_CLOSED
  - access log absent or not append-only => FAIL_CLOSED
  - access log unsigned => FAIL
  - negative-path test absent => FAIL

---

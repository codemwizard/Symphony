# TSK-HARD-011A PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-011A

- task_id: TSK-HARD-011A
- title: Policy snapshot and decision evidence baseline
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-011]
- goal: Ensure that every automated decision records a snapshot of the policy version
  that governed it, producing a decision evidence artifact that is independently
  verifiable without access to the current active policy.
- required_deliverables:
  - decision event log wiring (policy_version_id recorded per decision)
  - policy snapshot capture at decision time (not resolved at query time)
  - tasks/TSK-HARD-011A/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_011a.json
- verifier_command: bash scripts/audit/verify_tsk_hard_011a.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_011a.json
- schema_path: evidence/schemas/hardening/tsk_hard_011a.schema.json
- acceptance_assertions:
  - every automated inquiry/dispatch decision record contains policy_version_id
    populated at the time of the decision — not resolved lazily at query time
  - decision evidence artifact is of event class inquiry_event (TSK-HARD-002
    schema) and is schema-valid
  - test: deactivating a policy version after a decision was made does not alter
    the policy_version_id recorded on that decision record
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] same caveat as TSK-HARD-011:
    activation of a new policy version produces an evidence artifact; signed when
    signing service is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active version are blocked;
    runtime references policy_version_id at execution time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - policy_version_id resolved at query time rather than decision time => FAIL_CLOSED
  - decision record not schema-valid against inquiry_event schema => FAIL
  - deactivating policy version mutates historical decision records => FAIL_CLOSED

---

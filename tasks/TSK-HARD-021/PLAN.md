# TSK-HARD-021 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-021

- task_id: TSK-HARD-021
- title: Approval stage model and quorum baseline
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-020]
- goal: Implement the approval stage model that governs how an adjustment transitions
  from requested to pending_approval. Quorum rules are metadata-driven per
  adjustment type. Role heterogeneity is enforced at the DB layer — same-department
  duplicate approvals cannot satisfy quorum.
- required_deliverables:
  - approval stage table schema and migration
  - quorum policy schema at evidence/schemas/hardening/adjustment_quorum_policy.schema.json
  - quorum evaluation logic with role heterogeneity enforcement
  - policy store entry for default quorum policy (N departments, threshold T)
  - tasks/TSK-HARD-021/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_021.json
- verifier_command: bash scripts/audit/verify_tsk_hard_021.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_021.json
- schema_path: evidence/schemas/hardening/tsk_hard_021.schema.json
- acceptance_assertions:
  - approval stage table exists with fields: stage_id, adjustment_id,
    required_approver_count, quorum_threshold, stage_status, quorum_policy_version_id
  - each approval record contains: approver_id, role_at_approval_time,
    department_at_approval_time, approval_timestamp
  - quorum policy is loaded from versioned policy metadata per adjustment type —
    not hardcoded; policy_version_id referenced in approval stage record
  - cross-departmental quorum enforced: minimum N distinct departments required
    (N from policy); N >= 2 for all adjustment types
  - role heterogeneity enforced at evaluation time: two approvals from the same
    department do not increment the distinct-department count even if roles differ
  - negative-path test: submitting two approvals from the same department does
    not satisfy quorum; stage remains pending_approval
  - negative-path test: submitting approvals from N-1 distinct departments does
    not satisfy quorum
  - [METADATA GOVERNANCE] quorum policy config is versioned; activation of a new
    version produces an evidence artifact; signed when signing service is available;
    if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY and
    re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits to
    active policy version are blocked; runtime references policy_version_id at
    quorum evaluation time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - quorum hardcoded per adjustment type => FAIL_CLOSED
  - same-department duplicate approvals satisfy quorum => FAIL_CLOSED
  - role heterogeneity not enforced at evaluation time => FAIL_CLOSED
  - policy_version_id absent from approval stage record => FAIL
  - in-place edit of active quorum policy permitted => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path tests absent => FAIL

---

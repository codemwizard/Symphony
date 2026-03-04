# TSK-HARD-011 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-011

- task_id: TSK-HARD-011
- title: Metadata-driven per-rail inquiry policy
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-010]
- goal: Implement the runtime policy loader that resolves per-rail inquiry behavior
  from versioned metadata. Remove all hardcoded timeout/retry/cadence constants
  from adapter and inquiry code. Policy is versioned; the active version_id is
  recorded in every inquiry evidence artifact.
- required_deliverables:
  - runtime policy loader implementation
  - per-rail policy config schema at
    evidence/schemas/hardening/rail_inquiry_policy.schema.json
  - policy store migration (if DB-backed) or config file under version control
    (if file-backed) — must be explicitly stated in EXEC_LOG.md
  - tasks/TSK-HARD-011/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_011.json
- verifier_command: bash scripts/audit/verify_tsk_hard_011.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_011.json
- schema_path: evidence/schemas/hardening/tsk_hard_011.schema.json
- acceptance_assertions:
  - grep for hardcoded timeout/retry/cadence constants in adapter and inquiry code
    returns zero results (verifier runs this grep and fails if any found)
  - policy loader resolves policy by rail_id at runtime from store, not from
    compiled-in constants
  - inquiry evidence artifact contains policy_version_id field populated at
    execution time — not null, not empty
  - per-rail policy config schema validates against
    evidence/schemas/hardening/rail_inquiry_policy.schema.json
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] policy config is versioned: each
    version has a unique version_id; activation of a new version produces an evidence
    artifact of type policy_activation_event (registered in TSK-HARD-002); this
    artifact is signed when the signing service (TSK-HARD-051) is available; if the
    signing service is not yet available, the artifact is emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to an active policy version are blocked
    at the store layer; runtime operations reference policy_version_id at execution time
  - negative-path test: deploying a policy update without a version_id is rejected
  - EXEC_LOG.md states whether policy store is DB-backed or file-backed and
    contains Canonical-Reference line
- failure_modes:
  - any hardcoded constant found by grep => FAIL_CLOSED
  - policy_version_id absent from inquiry evidence => FAIL
  - in-place edit of active policy version permitted => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - activation of new policy version produces no evidence artifact => FAIL
    [METADATA GOVERNANCE violation]
  - activation evidence artifact is unsigned AND unsigned_reason field is absent
    => FAIL [signing caveat requires explicit field when unsigned]

---

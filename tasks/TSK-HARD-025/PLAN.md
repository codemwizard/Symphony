# TSK-HARD-025 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-025

- task_id: TSK-HARD-025
- title: Cooling-off and legal hold transitions
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-023]
- goal: Implement the cooling_off sealed state and all global freeze flags that
  can block adjustment execution. Cooling-off period is policy-driven. Each freeze
  flag type (participant_suspended, account_frozen, aml_hold, regulator_stop,
  program_hold) blocks execution independently. Legal hold transitions produce
  evidence artifacts with authority references.
- required_deliverables:
  - cooling_off state transition in adjustment lifecycle
  - cooling-off period loaded from policy metadata (not hardcoded)
  - global freeze flag check at execution gate
  - five freeze flag types implemented and individually testable
  - legal hold evidence artifact
  - tasks/TSK-HARD-025/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_025.json
- verifier_command: bash scripts/audit/verify_tsk_hard_025.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_025.json
- schema_path: evidence/schemas/hardening/tsk_hard_025.schema.json
- acceptance_assertions:
  - cooling_off state present in adjustment state enum (extends TSK-HARD-020
    enum); transition to cooling_off from pending_approval is defined and
    enforced
  - cooling-off period duration loaded from policy metadata; verifier confirms
    no hardcoded duration constant in execution gate code
  - execution attempt blocked while adjustment is in cooling_off state; blocked
    with named error (e.g. P7701 ADJUSTMENT_COOLING_OFF_ACTIVE)
  - global freeze flags checked at execution gate in this order:
    participant_suspended, account_frozen, aml_hold, regulator_stop, program_hold
  - any single active freeze flag blocks execution with named error that
    includes the flag type (e.g. P7702 ADJUSTMENT_FREEZE_AML_HOLD)
  - all five freeze flag types are independently checkable and independently
    testable
  - legal hold transition (any flag activation) produces an evidence artifact
    schema-valid against adjustment_approval_event class and contains:
    adjustment_id, hold_type, hold_timestamp, authority_reference, operator_id
  - negative-path test: executing adjustment in cooling_off state fails with
    P7701 and produces no execution attempt record
  - negative-path test: executing adjustment with each of the five freeze flags
    active individually fails with the correct named error
  - [METADATA GOVERNANCE] cooling-off duration policy is versioned; activation
    of a new version produces an evidence artifact; signed when signing service
    is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active version are blocked;
    runtime references policy_version_id at execution gate evaluation time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - execution permitted during cooling_off => FAIL_CLOSED
  - any freeze flag check absent from execution gate => FAIL_CLOSED
  - any of the five freeze flag types not implemented => FAIL
  - cooling-off period hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - legal hold produces no evidence artifact => FAIL
  - negative-path tests absent => FAIL

---

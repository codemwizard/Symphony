# TSK-HARD-092 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-092

- task_id: TSK-HARD-092
- title: Operator safety UX controls
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-091]
- goal: Implement operator-facing safety controls for all hardening-related
  high-risk actions. High-risk actions require secondary approval from a distinct
  operator role. All operator safety actions produce evidence artifacts. This
  is the UX enforcement complement to the technical controls in Waves 1–5.
- required_deliverables:
  - operator safety controls document at
    docs/programs/symphony-hardening/OPERATOR_SAFETY_CONTROLS.md
  - secondary approval enforcement for high-risk actions
  - confirmation step with evidence artifact for all controlled actions
  - tasks/TSK-HARD-092/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_092.json
- verifier_command: bash scripts/audit/verify_tsk_hard_092.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_092.json
- schema_path: evidence/schemas/hardening/tsk_hard_092.schema.json
- acceptance_assertions:
  - OPERATOR_SAFETY_CONTROLS.md exists and lists all controlled operator actions
    with: action_id, description, risk_level (HIGH/MEDIUM), confirmation_required,
    secondary_approval_required, evidence_artifact_produced
  - high-risk actions that require secondary approval from a distinct operator
    role at minimum: circuit breaker adapter resume, FINALITY_CONFLICT manual
    resolution, legal hold removal, DR bundle access (ceremony), policy bundle
    activation
  - secondary approval enforced: the approving operator must have a different
    operator_id and a different role from the initiating operator; same-role
    approval does not satisfy the requirement
  - every controlled operator action (regardless of risk level) produces a
    confirmation evidence artifact containing: action_type, initiator_id,
    initiator_role, approver_id (if applicable), approver_role (if applicable),
    confirmation_timestamp, justification_text, outcome
  - negative-path test: high-risk action attempted without secondary approval
    is blocked and produces rejection evidence containing action_type and
    outcome: SECONDARY_APPROVAL_REQUIRED
  - negative-path test: secondary approval from same-role operator is rejected
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any high-risk action permits execution without secondary approval => FAIL_CLOSED
  - secondary approval from same-role operator accepted => FAIL_CLOSED
  - any controlled action produces no evidence artifact => FAIL
  - negative-path tests absent => FAIL

---

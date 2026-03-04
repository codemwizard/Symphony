# TSK-HARD-011B PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-011B

- task_id: TSK-HARD-011B
- title: Signed policy bundle activation
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-054]
- goal: Enforce that policy bundles follow a signed lifecycle: draft → approved →
  active. The approved-to-active transition requires a valid signature verified at
  activation time. Unsigned or invalidly signed bundles cannot be activated.
  Runtime enforcement re-verifies the policy signature before applying the policy
  to any decision. High-risk policies require re-verification on every execution.
- required_deliverables:
  - policy bundle lifecycle: draft → approved → active state machine
  - signature verification at activation time
  - runtime re-verification at decision time
  - high-risk policy re-verification on every execution
  - activation rejection evidence artifact
  - tasks/TSK-HARD-011B/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_011b.json
- verifier_command: bash scripts/audit/verify_tsk_hard_011b.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_011b.json
- schema_path: evidence/schemas/hardening/tsk_hard_011b.schema.json
- acceptance_assertions:
  - policy bundle state enum: draft, approved, active — no other values
  - transition from approved to active blocked if bundle signature is invalid
    or absent; blocked with named error (e.g. P8201 POLICY_BUNDLE_UNSIGNED)
  - signature verified at activation time using signing service
    (TSK-HARD-051); verification result recorded in policy activation event
  - runtime enforcement: policy bundle signature re-verified at decision time
    before policy is applied; verification failure blocks decision with
    named error (e.g. P8202 POLICY_BUNDLE_VERIFICATION_FAILED)
  - high-risk policies (flag defined in policy metadata) require signature
    re-verification on every execution, not only at activation; verifier
    confirms high-risk flag is checked before applying policy
  - policy activation produces evidence artifact schema-valid against
    policy_activation_event class (TSK-HARD-002) and contains: policy_id,
    policy_version, signer_key_id, activation_timestamp, verification_outcome,
    assurance_tier
  - negative-path test: attempting to activate an unsigned policy bundle
    produces P8201 and rejection evidence artifact; bundle state remains approved
  - negative-path test: runtime decision with an invalidly signed policy
    bundle produces P8202; decision is blocked
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - unsigned policy bundle activated => FAIL_CLOSED
  - runtime verification absent at decision time => FAIL_CLOSED
  - high-risk policy applied without per-execution re-verification => FAIL_CLOSED
  - activation evidence artifact absent => FAIL
  - negative-path tests absent => FAIL

---

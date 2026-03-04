# TSK-HARD-053 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-053

- task_id: TSK-HARD-053
- title: Key rotation drill evidence
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-052]
- goal: Implement and evidence the key rotation SOP for both scheduled and
  emergency scenarios. Historical verification compatibility must be confirmed
  after rotation: artifacts signed with the deactivated key must remain verifiable
  using archived key material only. Rotation evidence artifacts are themselves
  meta-signed by a key class that is not being rotated.
- required_deliverables:
  - docs/operations/KEY_ROTATION_SOP.md
  - scheduled rotation drill evidence artifact
  - emergency rotation drill evidence artifact
  - post-rotation historical verification evidence
  - tasks/TSK-HARD-053/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_053.json
- verifier_command: bash scripts/audit/verify_tsk_hard_053.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_053.json
- schema_path: evidence/schemas/hardening/tsk_hard_053.schema.json
- acceptance_assertions:
  - KEY_ROTATION_SOP.md exists and covers: scheduled rotation flow with
    pre-rotation checklist, emergency rotation flow with trigger criteria,
    activation procedure, deactivation procedure with archival step,
    rollback procedure, historical verification compatibility check step
  - scheduled rotation drill produces evidence artifact containing: old_key_id,
    new_key_id, rotation_type: SCHEDULED, activation_timestamp,
    deactivation_timestamp, archival_confirmed: true, drill_outcome: PASS
  - emergency rotation drill produces evidence artifact containing:
    rotation_type: EMERGENCY, trigger_reason, old_key_deactivation_timestamp,
    new_key_activation_timestamp, order_confirmed: deactivation_before_activation,
    drill_outcome: PASS
  - deactivation_before_activation order enforced: new key must not be activated
    before old key is deactivated and archived in emergency scenario
  - post-rotation historical verification: at least one artifact signed with
    the deactivated key is verified successfully using archived key material only
    (operational key store excluded from verification environment during this test)
  - post-rotation verification evidence contains: verified_artifact_id,
    key_used: ARCHIVED_KEY, operational_store_excluded: true, outcome: PASS
  - rotation evidence artifacts are meta-signed: signed with a key class that
    is not the key class being rotated; meta-signing key class identified in
    drill evidence
  - negative-path test: attempting to verify a post-rotation artifact using
    the current operational key store (instead of archived key) produces
    UNVERIFIABLE_MISSING_KEY or equivalent named error — not a false pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - KEY_ROTATION_SOP.md absent => FAIL
  - emergency rotation not drilled => FAIL
  - new key activated before old key deactivated in emergency scenario => FAIL_CLOSED
  - historical verification broken after rotation => FAIL_CLOSED
  - post-rotation verification uses operational key store => FAIL_CLOSED
  - rotation evidence not meta-signed => FAIL
  - negative-path test absent => FAIL

---

# TSK-HARD-101 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-101

- task_id: TSK-HARD-101
- title: Zambia MMO reality controls
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-094, TSK-OPS-A1-STABILITY-GATE]
- goal: Encode the operational control set for Zambia MMO rail-specific failure
  modes: asynchronous contradiction, delayed settlement confirmation, dual-debit
  risk, and operator-side silent rejection. Controls must be metadata-driven
  (not hardcoded per MMO name) and produce deterministic evidence per scenario.
- required_deliverables:
  - MMO reality control rule set (metadata-driven, not per-MMO-name hardcoding)
  - scenario coverage: ASYNC_CONTRADICTION, DELAYED_SETTLEMENT, DUAL_DEBIT_RISK,
    SILENT_REJECTION
  - fallback posture per scenario (hold / inquiry / escalate / containment)
  - deterministic control evidence artifact per scenario type
  - tasks/TSK-HARD-101/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_101.json
- verifier_command: bash scripts/audit/verify_tsk_hard_101.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_101.json
- schema_path: evidence/schemas/hardening/tsk_hard_101.schema.json
- acceptance_assertions:
  - MMO reality control rule set defines at minimum: ASYNC_CONTRADICTION,
    DELAYED_SETTLEMENT, DUAL_DEBIT_RISK, SILENT_REJECTION
  - each scenario entry in rule set defines: scenario_type, detection_condition,
    fallback_posture (one of: hold / inquiry / escalate / containment),
    evidence_artifact_type, policy_version_id
  - rule set is loaded from versioned policy metadata (not hardcoded per MMO name
    or per MMO identifier); rule matching uses rail_class or behavior_profile, not
    MMO name string
  - fallback posture for each scenario type routes to the appropriate existing
    mechanism: hold routes to FINALITY_CONFLICT containment (TSK-HARD-015),
    inquiry routes to inquiry engine (TSK-HARD-012), containment routes to
    quarantine (TSK-HARD-016/017)
  - each scenario produces a deterministic control evidence artifact schema-valid
    against the appropriate event class from TSK-HARD-002
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] MMO reality control rule set is
    versioned; activation of a new rule set version produces an evidence artifact;
    signed when signing service is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active version blocked; runtime
    references policy_version_id at scenario evaluation time
  - negative-path test: simulating each of the 4 scenario types produces expected
    fallback posture and evidence artifact; verified by querying evidence store
    and instruction/inquiry state
  - EXEC_LOG.md contains Canonical-Reference line and explicitly states that no
    MMO name is hardcoded in the rule matching logic
- failure_modes:
  - rule matching uses hardcoded MMO name string => FAIL_CLOSED
    [portability and governance violation]
  - any of the 4 required scenario types absent from rule set => FAIL
  - fallback posture routes to mechanism not implemented in prior tasks => BLOCKED
  - rule set activation produces no evidence artifact => FAIL
    [METADATA GOVERNANCE violation]
  - rule set activation artifact is unsigned AND unsigned_reason field absent => FAIL
    [signing caveat requires explicit field when unsigned]
  - negative-path test absent or covers fewer than 4 scenarios => FAIL

---

# TSK-HARD-030 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-030

- task_id: TSK-HARD-030
- title: Lineage reference strategy DSL
- phase: Hardening
- wave: 3
- depends_on: [TSK-OPS-WAVE2-EXIT-GATE]
- goal: Define the reference strategy DSL that governs how adjustment dispatch
  references are derived from parent instruction references. Strategy selection
  is per-rail and loaded from policy metadata. The DSL is schema-validated and
  frozen once activated. This provides the policy contract that TSK-HARD-031
  implements at runtime.
- required_deliverables:
  - reference strategy DSL schema at
    evidence/schemas/hardening/reference_strategy_dsl.schema.json
  - policy store entry for each supported strategy type
  - docs/programs/symphony-hardening/REFERENCE_STRATEGY_DSL.md
  - tasks/TSK-HARD-030/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_030.json
- verifier_command: bash scripts/audit/verify_tsk_hard_030.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_030.json
- schema_path: evidence/schemas/hardening/tsk_hard_030.schema.json
- acceptance_assertions:
  - DSL schema defines and validates all four supported strategy types:
    SUFFIX, DETERMINISTIC_ALIAS, RE_ENCODED_HASH_TOKEN, RAIL_NATIVE_ALT_FIELD
  - each strategy entry in the DSL specifies: strategy_type, rail_id (wildcard
    permitted), max_length, nonce_retry_limit, collision_action
  - strategy selection is per-rail: DSL is looked up by rail_id at dispatch time,
    not hardcoded in adapter code
  - DSL document (REFERENCE_STRATEGY_DSL.md) is informational and the schema
    in evidence/schemas/hardening/ is the enforcement surface
  - DSL schema validates successfully against JSON Schema draft-07 or later
  - [METADATA GOVERNANCE] reference strategy config is versioned; activation of
    a new version produces an evidence artifact; signed when signing service is
    available; if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY
    and re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits
    to active version are blocked; runtime references policy_version_id at
    strategy selection time
  - negative-path test: rail with no matching DSL entry produces a named error
    rather than falling back to a default strategy silently
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the four strategy types absent from DSL schema => FAIL
  - strategy selection hardcoded in adapter code => FAIL_CLOSED
  - docs mirror used as enforcement surface => FAIL_REVIEW
  - in-place edit of active DSL version permitted => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---

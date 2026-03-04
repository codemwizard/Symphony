# TSK-OPS-WAVE1-EXIT-GATE PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-OPS-WAVE1-EXIT-GATE

- task_id: TSK-OPS-WAVE1-EXIT-GATE
- title: Wave-1 Exit Gate
- phase: Hardening
- wave: 1
- depends_on:
    [TSK-HARD-012, TSK-HARD-013, TSK-HARD-014, TSK-HARD-015,
     TSK-HARD-016, TSK-HARD-017, TSK-HARD-094, TSK-HARD-101, TSK-HARD-013B]
- goal: Deterministic Wave-1 pass/fail gate. All seven negative-path evidence
  artifacts must be present and schema-valid. Gate script exits non-zero if any
  artifact is missing, invalid, or pass=false. No manual override.
- required_deliverables:
  - scripts/audit/verify_program_wave1_exit_gate.sh
  - evidence/phase1/program_wave1_exit_gate.json
  - evidence/phase1/wave1_exit/effect_seal_mismatch_fail_closed.json
  - evidence/phase1/wave1_exit/malformed_response_capture.json
  - evidence/phase1/wave1_exit/conflicting_truth_containment.json
  - evidence/phase1/wave1_exit/offline_safe_mode_block.json
  - evidence/phase1/wave1_exit/inquiry_exhausted_no_autofinalize.json
  - evidence/phase1/wave1_exit/finality_conflict_enum_confirmed.json
  - evidence/phase1/wave1_exit/circuit_breaker_suspension.json
- verifier_command: bash scripts/audit/verify_program_wave1_exit_gate.sh
- evidence_path: evidence/phase1/program_wave1_exit_gate.json
- schema_path: evidence/schemas/hardening/wave1_exit/wave1_exit_gate.schema.json
- schema_set:
  - evidence/schemas/hardening/wave1_exit/effect_seal_mismatch.schema.json
  - evidence/schemas/hardening/wave1_exit/malformed_response_capture.schema.json
  - evidence/schemas/hardening/wave1_exit/conflicting_truth_containment.schema.json
  - evidence/schemas/hardening/wave1_exit/offline_safe_mode_block.schema.json
  - evidence/schemas/hardening/wave1_exit/inquiry_exhausted_no_autofinalize.schema.json
  - evidence/schemas/hardening/wave1_exit/finality_conflict_enum_confirmed.schema.json
  - evidence/schemas/hardening/wave1_exit/circuit_breaker_suspension.schema.json
- acceptance_assertions:
  - all 7 artifact paths listed in required_deliverables exist
  - each artifact validates against its corresponding schema in schema_set
  - each artifact contains pass=true
  - gate script is deterministic: identical inputs produce identical exit code
  - [MICRO-FIX-5] verify_program_wave1_exit_gate.sh must validate each of the 7
    artifacts against its corresponding schema in schema_set before emitting pass;
    it must either call scripts/audit/validate_evidence_schema.sh internally for
    each artifact or implement equivalent schema validation inline; checking only
    file existence and pass=true field without schema validation is insufficient
    and constitutes a defective gate script (FAIL_CLOSED)
  - gate script exits non-zero if any single artifact is missing, invalid JSON,
    fails schema validation, or contains pass=false
  - specific assertions per artifact:
    - effect_seal_mismatch_fail_closed.json: contains fields instruction_id,
      stored_seal_hash, computed_dispatch_hash, mismatch_detected: true,
      dispatch_blocked: true
    - malformed_response_capture.json: contains fields quarantine_id, adapter_id,
      classification (one of TRANSPORT/PROTOCOL/SYNTAX/SEMANTIC),
      truncation_applied, payload_hash
    - conflicting_truth_containment.json: contains fields instruction_id,
      rail_a_response, rail_b_response, conflict_classification,
      containment_action: HOLD_RELEASE
    - offline_safe_mode_block.json: contains fields block_start, reason,
      evidence_gap_marker_ids[]
    - inquiry_exhausted_no_autofinalize.json: contains fields instruction_id,
      inquiry_state: EXHAUSTED, attempted_action: AUTO_FINALIZE,
      outcome: BLOCKED
    - finality_conflict_enum_confirmed.json: contains fields confirmation_method:
      DB_ENUM_QUERY (not LOG_INSPECTION), enum_value_confirmed:
      FINALITY_CONFLICT, query_timestamp
    - circuit_breaker_suspension.json: contains fields adapter_id, rail_id,
      trigger_threshold, observed_rate, suspension_timestamp,
      policy_version_id, auto_recovery_possible: false
  - Wave-2 tasks are BLOCKED until this gate passes
  - DECISION NOTE: depends_on covers tasks 012–013B; tasks 000–011A are
    transitively required (012 depends_on 011A which chains back to 000).
    Excluding 000–011A from the direct depends_on list is intentional — transitive
    coverage is sufficient. Decision recorded in DECISION_LOG.md.
- failure_modes:
  - any of the 7 artifacts missing => FAIL_CLOSED
  - any artifact fails schema validation => FAIL_CLOSED
  - any artifact contains pass=false => FAIL_CLOSED
  - gate script exits zero when any artifact is missing => FAIL_CLOSED
    (gate script itself is defective)
  - [MICRO-FIX-5] gate script checks existence and pass=true but skips schema
    validation => FAIL_CLOSED (gate script itself is defective)
  - manual override of gate result => FAIL_CLOSED (not permitted)

# docs/programs/symphony-hardening/HARDENING_TASK_PACKS_WAVES_2_TO_6.md
# CANONICAL — v1
# Produced at the same standard as WAVE1_TASK_PACKS_FINAL.md (v6)
#
# All fixes from Wave-1 v6 applied uniformly:
#   - Full acceptance_assertions on every task (no blank tasks)
#   - Full required_deliverables on every task
#   - Metadata governance signing caveat (MICRO-FIX-2) on all metadata-driven tasks:
#     "activation produces an evidence artifact; signed when signing service is
#      available; if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY
#      and re-signed with back-linkage once TSK-HARD-051 is complete"
#   - All depends_on edges explicit — no prose sequencing constraints
#   - Negative-path test required on every task
#   - Standard acceptance assertions and failure modes apply to all tasks
#     (stated once below, not repeated per task)
#
# Wave-2 canonical task order:
#   TSK-HARD-020  Adjustment instruction schema and lifecycle
#   TSK-HARD-021  Approval stage model and quorum baseline
#   TSK-HARD-022  Execution attempt model, idempotency, and value ceiling
#   TSK-HARD-023  Recipient inheritance enforcement
#   TSK-HARD-025  Cooling-off and legal hold transitions
#   TSK-HARD-026  Approval attribution and role attestation
#   TSK-HARD-024  Terminal immutability enforcement (P7101) on adjustment tables
#   TSK-OPS-WAVE2-EXIT-GATE
#
# Wave-3 canonical task order:
#   TSK-HARD-030  Lineage reference strategy DSL
#   TSK-HARD-031  Dispatch reference allocation and registry
#   TSK-HARD-032  Length-aware canonicalization and alias collision
#   TSK-HARD-033  Reference registry linkage enforcement
#   TSK-OPS-WAVE3-EXIT-GATE
#
# Wave-4 canonical task order:
#   TSK-HARD-050  Key class separation model
#   TSK-HARD-051  HSM/KMS signing path enforcement
#   TSK-HARD-052  Signature metadata completeness standard
#   TSK-HARD-053  Key rotation drill evidence
#   TSK-HARD-054  Historical verification continuity (archive-only)
#   TSK-HARD-011B Signed policy bundle activation
#   TSK-HARD-096  Assurance tier disclosure evidence
#   TSK-OPS-WAVE4-EXIT-GATE
#
# Wave-5 canonical task order:
#   TSK-HARD-060  Canonicalization version registry
#   TSK-HARD-061  Historical verifier loader (no fallback to latest)
#   TSK-HARD-062  Archive integrity continuity (signed snapshots)
#   TSK-HARD-070  Trust-anchor archival controls (PKA)
#   TSK-HARD-071  Trust anchor archive and revocation material store
#   TSK-HARD-072  Offline verification package (DR recovery bundle)
#   TSK-HARD-073  Multi-party recovery ceremony controls
#   TSK-HARD-074  Regulator access audit envelope
#   TSK-HARD-097  Recovery continuity proof (end-to-end)
#   TSK-HARD-099  Long-horizon audit replay continuity (5-year)
#   TSK-HARD-102  Wave-5 regulator continuity gate
#   TSK-OPS-WAVE5-EXIT-GATE
#
# Wave-6 canonical task order:
#   TSK-HARD-080  Signing scale path (batch/Merkle + HSM throughput)
#   TSK-HARD-081  Rail Command Center v1
#   TSK-HARD-082  BoZ/Auditor demonstration pack (6 scripted scenarios)
#   TSK-HARD-090  QA matrix hardening completeness
#   TSK-HARD-091  Feature-flag rollout evidence controls
#   TSK-HARD-092  Operator safety UX controls
#   TSK-HARD-093  Reporting continuity and activation controls
#   TSK-HARD-095  BoZ submission audit trail primitives
#   TSK-HARD-098  Penalty defense pack generation
#   TSK-HARD-040  Privacy-preserving audit tokenization
#   TSK-HARD-041  Erasure workflow and key shredding controls
#   TSK-HARD-042  Privacy-preserving audit query continuity
#   TSK-HARD-100  Anti-abuse controls and retraction safety
#   TSK-OPS-WAVE6-EXIT-GATE
#
# Standard acceptance assertions (apply to ALL tasks — not repeated per task):
#   - evidence file exists and is valid JSON
#   - task_id in evidence matches task pack
#   - pass=true in evidence for successful closeout
#   - declared depends_on all confirmed complete before close
#   - verifier exits 0
#   - RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh exits 0
#   - Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md present in EXEC_LOG.md
#   - at least one negative-path test present and passing
#
# Standard failure modes (apply to ALL tasks — not repeated per task):
#   - missing contract / docs / verifier => FAIL_CLOSED
#   - invalid or missing evidence => FAIL
#   - dependency incomplete => BLOCKED
#   - undeclared path mutations => FAIL_REVIEW
#   - negative-path test absent => FAIL

---

## Wave 2 Task Packs

Wave-2 entry gate: TSK-OPS-WAVE1-EXIT-GATE must be pass=true before any Wave-2
task may be marked done.

---

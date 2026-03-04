# TSK-HARD-094 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-094

- task_id: TSK-HARD-094
- title: Offline Safe Mode execution gate
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-017, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a fail-closed execution gate that blocks instruction dispatch
  while the system is in offline or degraded signing mode. Unsigned evidence
  produced during offline periods must be preserved with gap markers, and a
  re-sign linkage must be established on recovery so the evidence chain is
  continuous.
- required_deliverables:
  - offline/degraded mode detection and dispatch block
  - unsigned evidence chain gap markers during offline period
  - recovery re-sign linkage (offline evidence re-signed and linked to gap markers
    on reconnection)
  - offline block evidence artifact
  - tasks/TSK-HARD-094/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_094.json
- verifier_command: bash scripts/audit/verify_tsk_hard_094.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_094.json
- schema_path: evidence/schemas/hardening/tsk_hard_094.schema.json
- acceptance_assertions:
  - instruction dispatch is blocked while system detects offline/degraded signing
    mode; block produces named error (e.g. P7501 OFFLINE_SAFE_MODE_ACTIVE)
  - gap markers inserted into evidence chain for each offline period: gap_start,
    gap_end (populated on recovery), gap_reason
  - on recovery: unsigned evidence artifacts from offline period are re-signed
    using current active key; re-sign produces evidence artifacts that reference
    original gap marker
  - re-signed artifacts preserve original timestamp (offline period timestamp)
    and add re_sign_timestamp and re_sign_key_id fields
  - offline block evidence artifact schema-valid and contains: block_start,
    block_end (populated on recovery), reason, evidence_gap_marker_ids[]
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] offline detection thresholds and
    safe mode policy loaded from versioned policy config; activation of a new policy
    version produces an evidence artifact; signed when signing service is available;
    if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY and
    re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits to
    active version blocked; runtime references policy_version_id
  - negative-path test: simulating offline mode blocks dispatch and produces
    P7501; dispatch rejected; gap marker created; on simulated recovery, re-sign
    linkage established and gap marker closed
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - dispatch permitted in offline mode => FAIL_CLOSED
  - gap markers not inserted during offline period => FAIL
  - re-sign linkage absent on recovery => FAIL
  - re-signed artifact does not preserve original timestamp => FAIL
  - negative-path test absent => FAIL

---

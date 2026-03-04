# TSK-HARD-073 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-073

- task_id: TSK-HARD-073
- title: Multi-party recovery ceremony controls
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-072]
- goal: Implement the quorum access policy and ceremony procedure for DR bundle
  access. Quorum must span heterogeneous roles from at least three distinct
  authority categories. Every bundle access event produces a ceremony evidence
  artifact that is itself signed and archived. A drill ceremony must be performed
  and evidenced before this task closes.
- required_deliverables:
  - quorum access policy (minimum threshold defined and enforced)
  - docs/operations/DR_RECOVERY_CEREMONY.md
  - ceremony evidence artifact schema
  - drill ceremony performed and drill evidence artifact
  - tasks/TSK-HARD-073/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_073.json
- verifier_command: bash scripts/audit/verify_tsk_hard_073.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_073.json
- schema_path: evidence/schemas/hardening/tsk_hard_073.schema.json
- acceptance_assertions:
  - quorum access policy defines: minimum participant count (e.g. 2-of-3 or
    3-of-5) and required authority categories; threshold and categories
    documented in DR_RECOVERY_CEREMONY.md and enforced at access gate
  - required authority categories: at minimum one Board-level authority, one
    Security function authority, one Audit/Witness authority
  - DR_RECOVERY_CEREMONY.md exists and covers: pre-ceremony checklist,
    participant verification procedure, access evidence recording steps,
    post-ceremony integrity check, emergency ceremony variant
  - every bundle access event produces a ceremony evidence artifact containing:
    ceremony_id, ceremony_type (DRILL or LIVE), participants[], roles[],
    authority_categories[], quorum_threshold, quorum_met: true/false,
    access_timestamp, purpose, outcome
  - ceremony evidence artifact is schema-valid against dr_ceremony_event class
    (TSK-HARD-002) and is itself signed with key class PCSK
  - signed ceremony evidence artifact is archived in a store that is independent
    of the DR bundle itself
  - drill ceremony performed: drill evidence artifact exists with
    ceremony_type: DRILL and outcome: PASS
  - negative-path test: bundle access attempted with fewer than required
    authority categories present is rejected; rejection evidence produced
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - bundle accessed without quorum => FAIL_CLOSED
  - role heterogeneity not enforced (same authority category satisfies multiple
    quorum slots) => FAIL_CLOSED
  - ceremony produces no evidence artifact => FAIL_CLOSED
  - ceremony evidence artifact not signed => FAIL_CLOSED
  - drill not performed before task closes => FAIL
  - negative-path test absent => FAIL

---

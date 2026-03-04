# TSK-HARD-071 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-071

- task_id: TSK-HARD-071
- title: Trust anchor archive and revocation material store
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-070]
- goal: Produce versioned trust anchor snapshots, archive revocation material for
  all deactivated keys, and archive all verification policy versions. All archived
  materials must be independently restorable. This provides the trust context
  that DR recovery and long-horizon verification (TSK-HARD-099) depend on.
- required_deliverables:
  - trust anchor snapshot store (versioned)
  - revocation material store (revoked key IDs, timestamps, reasons)
  - verification policy version archive
  - independent restore test for each store
  - tasks/TSK-HARD-071/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_071.json
- verifier_command: bash scripts/audit/verify_tsk_hard_071.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_071.json
- schema_path: evidence/schemas/hardening/tsk_hard_071.schema.json
- acceptance_assertions:
  - trust anchor snapshots exist and are versioned with: snapshot_id,
    snapshot_timestamp, signing_key_id, trust_anchor_entries[]
  - each trust anchor snapshot is signed with key class PCSK at creation time
  - revocation material archived for all deactivated keys: revoked_key_id,
    revocation_timestamp, revocation_reason, revoking_operator_id
  - revocation material is append-only: no UPDATE or DELETE on revocation records
  - verification policy versions archived: each version with activation_date,
    policy_document_hash, signing_key_id, deprecation_date (nullable)
  - all three archived stores (trust anchor, revocation, verification policy)
    are independently restorable; isolated restore test performed for each
  - evidence artifact contains: task_id, stores_archived[], restore_tests_passed[],
    pass
  - negative-path test: verification of an artifact from a revoked key produces
    a named error referencing revocation material (not a silent pass)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - revocation material not archived => FAIL_CLOSED
  - revocation records mutable => FAIL_CLOSED
  - verification policy versions not versioned => FAIL
  - any archived store not independently restorable => FAIL_CLOSED
  - negative-path test absent => FAIL

---

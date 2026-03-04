# TSK-HARD-070 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-070

- task_id: TSK-HARD-070
- title: Trust-anchor archival controls — Public Key Archive
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-062]
- goal: Implement the Public Key Archive (PKA) as an append-only store that is
  physically or logically separate from the operational database. The PKA contains
  one entry per key version for each key class. No UPDATE or DELETE is permitted
  on existing PKA entries. The PKA can be restored independently from a snapshot
  without access to the operational DB.
- required_deliverables:
  - PKA store (separate from operational DB)
  - append-only enforcement on PKA entries
  - independent restore test
  - PKA snapshot mechanism
  - tasks/TSK-HARD-070/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_070.json
- verifier_command: bash scripts/audit/verify_tsk_hard_070.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_070.json
- schema_path: evidence/schemas/hardening/tsk_hard_070.schema.json
- acceptance_assertions:
  - PKA is a persistent store that is separate from the operational database;
    EXEC_LOG.md explicitly states whether the separation is physical (different
    DB instance), logical (different schema with separate credentials), or other;
    chosen approach confirmed in DECISION_LOG.md
  - PKA entries are append-only: UPDATE and DELETE operations on existing PKA
    entries are blocked at the DB layer (trigger or RLS policy); verifier
    confirms via negative-path test
  - each PKA entry contains: key_id, key_version, key_class, public_key_material,
    trust_anchor_ref, activation_date, deactivation_date (nullable), entry_timestamp
  - PKA can be snapshotted and restored to an isolated environment without
    access to the operational DB; isolated restore test confirms PKA entries
    are intact and queryable after restore
  - isolated restore test: PKA snapshot restored to isolated environment;
    historical verification performed using PKA only; verification succeeds
    for at least one artifact per key class
  - PKA snapshot evidence artifact is schema-valid against pka_snapshot_event
    class (TSK-HARD-002) and contains: snapshot_id, snapshot_timestamp,
    key_versions_included[], restore_test_outcome: PASS
  - negative-path test: attempting UPDATE on an existing PKA entry is rejected
    with a named error
  - negative-path test: attempting DELETE on an existing PKA entry is rejected
    with a named error
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - PKA shares storage with operational DB and cannot be independently restored
    => FAIL_CLOSED
  - UPDATE permitted on PKA entries => FAIL_CLOSED
  - DELETE permitted on PKA entries => FAIL_CLOSED
  - isolated restore test fails => FAIL_CLOSED
  - separation approach not documented in DECISION_LOG.md => FAIL_REVIEW
  - negative-path tests absent => FAIL

---

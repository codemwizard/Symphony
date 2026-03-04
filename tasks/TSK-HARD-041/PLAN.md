# TSK-HARD-041 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-041

- task_id: TSK-HARD-041
- title: Erasure workflow and key shredding controls
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-040]
- goal: Implement per-user, per-period salt management and cryptographic
  shredding on erasure request. Erasure renders subject tokens unresolvable
  by deleting the salt from the vault. Evidence artifacts are preserved —
  they receive a purge_marker that links to the erasure evidence artifact.
  The evidence chain remains intact and auditable after erasure.
- required_deliverables:
  - per-user per-period salt management in vault
  - erasure request workflow with cryptographic shredding
  - purge_marker implementation in evidence artifacts
  - erasure evidence artifact
  - tasks/TSK-HARD-041/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_041.json
- verifier_command: bash scripts/audit/verify_tsk_hard_041.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_041.json
- schema_path: evidence/schemas/hardening/tsk_hard_041.schema.json
- acceptance_assertions:
  - per-user, per-period salt exists in vault; salt rotation supported within
    an audit period without invalidating existing tokens for that period
  - erasure request triggers: (1) salt deleted from vault (cryptographic
    shred), (2) all evidence artifacts for that subject token receive a
    purge_marker field replacing the token reference
  - erasure does not delete evidence artifacts; artifacts remain intact
    with purge_marker containing: erasure_id, erasure_timestamp,
    subject_token_hash (not the token itself), method: CRYPTOGRAPHIC_SHRED
  - purge_marker links to the erasure evidence artifact by erasure_id;
    erasure evidence artifact is independently queryable by erasure_id
  - erasure evidence artifact contains: erasure_id, erasure_timestamp,
    requesting_operator_id, subject_token_hash, method: CRYPTOGRAPHIC_SHRED,
    artifacts_purge_marked_count, outcome
  - post-erasure: subject token is unresolvable; vault lookup for the
    erased subject returns NOT_FOUND
  - post-erasure: audit query for the erased subject token returns the
    purge_marker, not resolved subject data
  - negative-path test: after erasure, vault lookup for erased subject
    returns NOT_FOUND; audit query returns purge_marker; no raw subject
    data accessible
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - erasure deletes evidence artifacts => FAIL_CLOSED
  - token resolvable after salt shredding => FAIL_CLOSED
  - purge_marker absent from any evidence artifact after erasure => FAIL
  - erasure evidence artifact not independently queryable => FAIL
  - negative-path test absent => FAIL

---

# TSK-HARD-050 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-050

- task_id: TSK-HARD-050
- title: Key class separation model
- phase: Hardening
- wave: 4
- depends_on: [TSK-OPS-WAVE3-EXIT-GATE]
- goal: Formally define the key class taxonomy and authorization matrix for all
  signing operations. Four key classes are defined: EASK, PCSK, AAK, and
  transport identities. The authorization matrix defines which caller types may
  invoke sign operations per key class. The matrix is enforced at the signing
  service layer — unauthorized cross-class signing is rejected with a named error.
- required_deliverables:
  - key class taxonomy document at docs/architecture/KEY_CLASS_TAXONOMY.md
  - authorization matrix schema at
    evidence/schemas/hardening/key_auth_matrix.schema.json
  - runtime authorization enforcement in signing service
  - negative-path test per key class
  - tasks/TSK-HARD-050/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_050.json
- verifier_command: bash scripts/audit/verify_tsk_hard_050.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_050.json
- schema_path: evidence/schemas/hardening/tsk_hard_050.schema.json
- acceptance_assertions:
  - key class taxonomy defines exactly four classes: EASK (evidence artifact
    signing key), PCSK (policy and config signing key), AAK (adjustment
    attestation key), TRANSPORT_IDENTITY
  - each key class entry in taxonomy specifies: class_id, permitted_callers[],
    permitted_artifact_types[], key_backend (HSM/KMS/software), exportable: false
  - authorization matrix is loaded at signing service startup and enforced per
    request; matrix is not hardcoded in application code
  - unauthorized caller attempting sign with wrong key class is rejected with
    named error (e.g. P8101 KEY_CLASS_UNAUTHORIZED)
  - cross-class signing attempts produce evidence artifacts containing:
    caller_id, requested_key_class, permitted_key_classes[], outcome: REJECTED
  - negative-path test: caller authorized for AAK attempts to sign with EASK
    key class — rejected with P8101 and produces rejection evidence
  - negative-path test: caller authorized for EASK attempts to sign with PCSK
    key class — rejected with P8101
  - taxonomy document is informational; enforcement surface is the authorization
    matrix schema and runtime enforcement; docs mirror not gating
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - key classes undocumented or fewer than four defined => FAIL
  - authorization matrix not enforced at runtime => FAIL_CLOSED
  - cross-class signing permitted silently => FAIL_CLOSED
  - cross-class rejection produces no evidence artifact => FAIL
  - negative-path tests absent => FAIL

---

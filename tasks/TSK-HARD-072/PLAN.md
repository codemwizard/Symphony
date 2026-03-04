# TSK-HARD-072 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-072

- task_id: TSK-HARD-072
- title: Offline verification package — DR recovery bundle
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-071]
- goal: Generate the encrypted offline DR recovery bundle containing all materials
  required for independent historical verification. The bundle is encrypted at
  rest with a key accessible only via the quorum ceremony in TSK-HARD-073.
  A signed chain-of-custody manifest covers all bundle contents. The bundle
  must be usable in an isolated environment with no operational runtime dependency.
- required_deliverables:
  - DR recovery bundle generator script
  - encrypted bundle (PKA export + canonicalization archive + trust anchor
    archive + revocation material + verification policy archive + verifier
    tooling package)
  - signed chain-of-custody manifest (PCSK-signed)
  - isolated environment verification test
  - tasks/TSK-HARD-072/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_072.json
- verifier_command: bash scripts/audit/verify_tsk_hard_072.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_072.json
- schema_path: evidence/schemas/hardening/tsk_hard_072.schema.json
- acceptance_assertions:
  - DR recovery bundle contains exactly: PKA export, canonicalization archive
    snapshot (TSK-HARD-062), trust anchor archive (TSK-HARD-071), revocation
    material (TSK-HARD-071), verification policy archive (TSK-HARD-071),
    verifier tooling package (self-contained, no network dependency)
  - bundle is encrypted at rest; encryption key is accessible only via quorum
    ceremony defined in TSK-HARD-073; EXEC_LOG.md documents encryption scheme
  - chain-of-custody manifest signed with key class PCSK and contains:
    bundle_timestamp, contents_hash[], signing_key_id, chain_of_custody_refs[],
    assurance_tier
  - isolated environment verification test: using only the bundle contents
    (no operational runtime, no network), verify at least two historical
    artifacts of distinct types; both verifications must succeed
  - isolated test evidence contains: test_timestamp, artifacts_verified[],
    operational_runtime_used: false, network_used: false, outcomes[]
  - evidence artifact is schema-valid against dr_ceremony_event class
    (TSK-HARD-002)
  - negative-path test: bundle with any required component missing fails
    manifest integrity check before isolation test is attempted
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - bundle missing any required component => FAIL_CLOSED
  - bundle not encrypted at rest => FAIL_CLOSED
  - encryption key accessible without quorum ceremony => FAIL_CLOSED
  - chain-of-custody manifest unsigned => FAIL_CLOSED
  - isolated verification test fails or uses operational runtime => FAIL_CLOSED
  - negative-path test absent => FAIL

---

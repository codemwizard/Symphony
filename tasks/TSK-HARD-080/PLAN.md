# TSK-HARD-080 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-080

- task_id: TSK-HARD-080
- title: Signing scale path — batch/Merkle and HSM throughput
- phase: Hardening
- wave: 6
- depends_on: [TSK-OPS-WAVE5-EXIT-GATE]
- goal: Implement the Merkle batch signing engine for high-volume evidence artifact
  production. Define the artifact class taxonomy distinguishing individual from
  batch signing. Conduct HSM/KMS throughput load tests and degradation tests.
  Confirm that HSM or KMS region outage causes fail-closed behavior — no fallback
  to software signing.
- required_deliverables:
  - artifact class taxonomy document at docs/architecture/ARTIFACT_CLASS_TAXONOMY.md
  - Merkle batch signing engine implementation
  - HSM throughput load test with evidence artifact
  - HSM/KMS outage fail-closed tests with evidence artifacts
  - tasks/TSK-HARD-080/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_080.json
- verifier_command: bash scripts/audit/verify_tsk_hard_080.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_080.json
- schema_path: evidence/schemas/hardening/tsk_hard_080.schema.json
- acceptance_assertions:
  - artifact class taxonomy defines at minimum two classes: INDIVIDUAL_SIGNED,
    BATCH_MERKLE_SIGNED; taxonomy document is informational, schema is
    enforcement surface
  - Merkle batch signing engine: accepts a batch of artifact hashes, produces
    a Merkle root and per-leaf proof for each artifact in the batch
  - each batch artifact carries Merkle metadata per TSK-HARD-052 standard:
    merkle_root, leaf_index, merkle_proof
  - individual artifact verification using Merkle proof is confirmed correct:
    given leaf_index, merkle_proof, and merkle_root, the artifact hash is
    verified as a member of the batch
  - HSM throughput load test: load test exercises signing service at peak
    expected TPS (target TPS defined in test config); evidence artifact records:
    test_timestamp, target_tps, achieved_tps, error_rate, outcome
  - degradation test: load exceeding target TPS causes signing service to queue
    requests — not drop or corrupt them; confirmed by verifying all queued
    requests eventually produce correct signatures
  - HSM outage simulation: when HSM is unavailable, signing service fails-closed
    with named error — does not fall back to software signing; outage evidence
    artifact contains: simulated_outage_duration, fallback_attempted: false,
    outcome: FAIL_CLOSED
  - KMS region outage simulation: when KMS region is unavailable, signing
    service fails-closed — does not fall back to alternate region or software;
    region outage evidence artifact contains equivalent fields
  - negative-path test: Merkle proof for wrong leaf index fails verification
    deterministically — not a false pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - Merkle batch produces incorrect proof for any leaf => FAIL_CLOSED
  - leaf verification using proof produces false pass => FAIL_CLOSED
  - HSM outage causes fallback to software signing => FAIL_CLOSED
  - KMS region outage causes fallback => FAIL_CLOSED
  - throughput test not performed => FAIL
  - degradation test shows dropped or corrupted requests under load => FAIL_CLOSED
  - negative-path test absent => FAIL

---

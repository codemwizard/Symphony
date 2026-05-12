# Phase 3 Pre-Entry Remediation Tasks

Phase Key: **P3-PRE**
Phase Name: **Phase 3 Pre-Entry Remediation**
Source: [SYMPHONY_GROUND_TRUTH_REMEDIATION_REPORT.md](../SYMPHONY_GROUND_TRUTH_REMEDIATION_REPORT.md), [BASELINE_REGISTER_vs_REMEDIATION_VERDICT2.md](../BASELINE_REGISTER_vs_REMEDIATION_VERDICT2.md)

---

## Dependency Graph

```
TSK-P3-PRE-001 [ENTRY BLOCKER]
  └─ TSK-P3-W1-DB-007
       ├─ TSK-P3-GOV-002
       │    └─ TSK-P3-GOV-001
       └─ TSK-P3-W8-SEAL-001
            └─ TSK-P3-W8-ARCH-001

TSK-P3-GOV-003 [PARALLEL — no dependency on above]
```

---

## Task Register

| Task ID | Title | Owner | Priority | Status | Depends On |
|---------|-------|-------|----------|--------|------------|
| TSK-P3-PRE-001 | Verify wave8_crypto extension operational status | SECURITY_GUARDIAN | CRITICAL | planned | — |
| TSK-P3-W1-DB-007 | Add data_class column to evidence_nodes (migration 0205) | DB_FOUNDATION | CRITICAL | planned | TSK-P3-PRE-001 |
| TSK-P3-GOV-002 | Seed INV-301–310 into invariant_registry (migration 0206) | DB_FOUNDATION | HIGH | planned | TSK-P3-W1-DB-007 |
| TSK-P3-GOV-001 | Constitutional compilation pipeline | INVARIANTS_CURATOR | HIGH | planned | TSK-P3-GOV-002, TSK-P3-W1-DB-007 |
| TSK-P3-W8-SEAL-001 | Epoch checkpoint activation (EpochSealingCommand) | DB_FOUNDATION | HIGH | planned | TSK-P3-W1-DB-007 |
| TSK-P3-W8-ARCH-001 | Application chain to DB Merkle bridge | ARCHITECT | HIGH | planned | TSK-P3-W8-SEAL-001 |
| TSK-P3-GOV-003 | Task corpus archival gate | SECURITY_GUARDIAN | MEDIUM | planned | — |

---

## Per-Task Detail

### TSK-P3-PRE-001 — Verify wave8_crypto Extension

- **Invariants:** —
- **Touches:** `scripts/audit/verify_ed25519_available.sh`, `evidence/phase3/wave8_crypto_operational_status.json`
- **Verifier:** `scripts/audit/verify_ed25519_available.sh`
- **Evidence:** `evidence/phase3/wave8_crypto_operational_status.json`
- **Acceptance:** ed25519_verify() returns FALSE for bad signature (not function-not-found error)
- **Failure Modes:** Extension absent → Phase 3 cannot open; Evidence file missing → FAIL

### TSK-P3-W1-DB-007 — Add data_class to evidence_nodes

- **Invariants:** INV-301
- **Touches:** `schema/migrations/0205_evidence_nodes_data_class.sql`, `docs/constitutional/data_class_registry.yml`, `evidence/phase3/tsk_p3_w1_db_007_data_class.json`
- **Verifier:** `scripts/db/verify_p3_evidence_nodes_data_class.sh`
- **Evidence:** `evidence/phase3/tsk_p3_w1_db_007_data_class.json`
- **Acceptance:** ENUM has 6 values; column exists; monotonicity trigger blocks evidentiary→operational downgrade with P3101
- **Failure Modes:** Migration fails → all Phase 3 blocked; Evidence file missing → FAIL

### TSK-P3-GOV-002 — Seed Invariant Registry

- **Invariants:** —
- **Touches:** `schema/migrations/0206_phase3_invariant_registry_seed.sql`, `evidence/phase3/tsk_p3_gov_002_invariant_seed.json`
- **Verifier:** `scripts/db/verify_p3_invariant_registry_seed.sh`
- **Evidence:** `evidence/phase3/tsk_p3_gov_002_invariant_seed.json`
- **Acceptance:** 10 rows with INV-3% invariant_ids, all is_blocking=FALSE, 8 CRITICAL + 2 HIGH
- **Failure Modes:** Duplicate invariant_id → migration fails; Evidence file missing → FAIL

### TSK-P3-GOV-001 — Constitutional Compilation Pipeline

- **Invariants:** —
- **Touches:** `scripts/constitutional/compile_phase3_constraints.py`, `evidence/phase3/constitutional_constraint_manifest.json`
- **Verifier:** `scripts/constitutional/compile_phase3_constraints.py`
- **Evidence:** `evidence/phase3/constitutional_constraint_manifest.json`
- **Acceptance:** Parses 10 invariants; validates verifier path, severity, negative test per invariant; validates data_class_registry completeness
- **Failure Modes:** Broken invariant-to-verifier link → FAIL; Evidence file missing → FAIL

### TSK-P3-W8-SEAL-001 — Epoch Checkpoint Activation

- **Invariants:** —
- **Touches:** `services/ledger-api/dotnet/src/LedgerApi/Commands/EpochSealingCommand.cs`, `services/ledger-api/dotnet/tests/LedgerApi.Tests/EpochSealingCommandTests.cs`, `evidence/phase3/tsk_p3_w8_seal_001_epoch_sealing.json`
- **Verifier:** `scripts/db/verify_p3_epoch_sealing.sh`
- **Evidence:** `evidence/phase3/tsk_p3_w8_seal_001_epoch_sealing.json`
- **Acceptance:** proof_pack_batches populated with Merkle root; operational nodes excluded; unit tests pass
- **Failure Modes:** Merkle computation incorrect → CRITICAL_FAIL; Evidence file missing → FAIL

### TSK-P3-W8-ARCH-001 — Hash Chain to Merkle Bridge

- **Invariants:** —
- **Touches:** `services/ledger-api/dotnet/src/LedgerApi/Commands/TamperEvidentChain.cs`, `services/ledger-api/dotnet/tests/LedgerApi.Tests/TamperEvidentChainBridgeTests.cs`, `evidence/phase3/tsk_p3_w8_arch_001_hash_chain_bridge.json`
- **Verifier:** `scripts/audit/verify_p3_hash_chain_bridge.sh`
- **Evidence:** `evidence/phase3/tsk_p3_w8_arch_001_hash_chain_bridge.json`
- **Acceptance:** ExtractLeafHashes method exists; hash match test passes; round-trip test passes; corrupted line rejected
- **Failure Modes:** Hash mismatch between app chain and DB → CRITICAL_FAIL; Evidence file missing → FAIL

### TSK-P3-GOV-003 — Task Corpus Archival Gate

- **Invariants:** —
- **Touches:** `Gove/tasks/_template/meta.yml`, `scripts/audit/verify_task_meta_schema.sh`, `scripts/audit/verify_task_plans_present.sh`, `evidence/phase3/tsk_p3_gov_003_task_archival_gate.json`
- **Verifier:** `scripts/audit/verify_p3_task_archival_gate.sh`
- **Evidence:** `evidence/phase3/tsk_p3_gov_003_task_archival_gate.json`
- **Acceptance:** Template has archived field; CI scripts skip archived=true tasks; non-archived tasks fully validated
- **Failure Modes:** Archived tasks still traversed → FAIL; Evidence file missing → FAIL

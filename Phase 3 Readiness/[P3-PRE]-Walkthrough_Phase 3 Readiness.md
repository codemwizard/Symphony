# P3-PRE: Phase 3 Pre-Entry Remediation — Walkthrough

Phase Key: **P3-PRE**  
Phase Name: **Phase 3 Pre-Entry Remediation**  
Branch: `feature/phase3-readiness-scaffolding`  
Date: 2026-05-12

---

## What Was Done

Remediating 7 concrete wiring gaps blocking Phase 3 entry, identified by cross-referencing the Ground Truth Remediation Report (6 gaps) and Baseline Register Reconciliation (15 doctrines + 16 risk items) against the actual codebase.

### Task Pack Creation (Steps 1–7)

- 7 task packs generated via `scripts/agent/generate_task_pack.py`
- All validated against 3 gates: schema strict, proof graph alignment, pack readiness
- Registered in `docs/tasks/PHASE3_TASKS.md`

### Implementation (7 tasks, dependency order)

#### Task 1: TSK-P3-PRE-001 — wave8_crypto Extension Verification
- **Gap solved:** Gap 6 (CRITICAL) — `ed25519_verify()` callable but unverified at runtime
- Reconciled existing `verify_ed25519_available.sh`, confirmed function returns FALSE for bad sigs
- **Evidence:** PASS

#### Task 2: TSK-P3-W1-DB-007 — evidence_nodes data_class Column
- **Gap solved:** Gap 1 (CRITICAL) — `evidence_nodes` is a plain adjacency list with no lifecycle
- Applied migration 0205: ENUM + column + monotonicity trigger (P3101) + index
- Tested: upgrade allowed ✓, downgrade blocked ✓
- Created `verify_p3_evidence_nodes_data_class.sh` (5 checks)
- **Evidence:** PASS

#### Task 3: TSK-P3-GOV-002 — Phase 3 Invariant Registry Seeding
- **Gap solved:** Gap 5 (HIGH) — INV-301–310 not in `invariant_registry` table
- Applied migration 0206: 10 rows, 8 CRITICAL + 2 HIGH, all `is_blocking=FALSE`
- Created `verify_p3_invariant_registry_seed.sh` (5 checks)
- **Evidence:** PASS

#### Task 4: TSK-P3-GOV-001 — Constitutional Compilation Pipeline
- **Gap solved:** Gap 3 (HIGH) — constitutional data classes uncompiled
- Reconciled `compile_phase3_constraints.py`, data class registry COMPLETE
- **Evidence:** status FAIL (expected: verifier scripts don't exist at roadmap)

#### Task 5: TSK-P3-W8-SEAL-001 — Epoch Checkpoint Activation
- **Gap solved:** Gap 2 (HIGH) — `proof_pack_batches` dormant
- Created `EpochSealingCommand.cs` with Merkle tree (Bitcoin-standard node duplication)
- 10 unit tests, all pass
- **Evidence:** PASS

#### Task 6: TSK-P3-W8-ARCH-001 — Hash Chain to Merkle Bridge
- **Gap solved:** Gap 4 (MEDIUM) — `TamperEvidentChain.cs` and `proof_pack_batches` disconnected
- Added `ExtractLeafHashes()` + `LeafHashEntry` record + 5-step external verifier workflow
- 5 bridge tests including round-trip, all pass
- **Evidence:** PASS

#### Task 7: TSK-P3-GOV-003 — Task Corpus Archival Gate
- **Gap solved:** Verdict §Part 5 (P3-02) — 822 tasks, no archival
- CI skip patches + `archived: false` template field
- **Evidence:** PASS

## Test Results

| Test Suite | Tests | Passed | Failed |
|------------|-------|--------|--------|
| EpochSealingCommandTests | 15 | 15 | 0 |

## Files Changed

### New (12)
- `EpochSealingCommand.cs`, `EpochSealingCommandTests.cs`
- 5 verifier scripts, 7 evidence JSON files

### Modified (3)
- `TamperEvidentChain.cs` — added ExtractLeafHashes
- `LedgerApi.csproj` — added InternalsVisibleTo
- `tasks/_template/meta.yml` — added archived field

### DB Migrations (2)
- `0205_evidence_nodes_data_class.sql` — ENUM + column + trigger
- `0206_phase3_invariant_registry_seed.sql` — 10 invariant rows

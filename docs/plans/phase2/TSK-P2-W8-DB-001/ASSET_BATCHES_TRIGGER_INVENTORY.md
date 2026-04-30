# Asset Batches Trigger Inventory

**Task:** TSK-P2-W8-DB-001
**Date:** 2026-04-29
**Purpose:** Inventory of all current `asset_batches` trigger paths before Wave 8 dispatcher topology consolidation

## Current Triggers on asset_batches

### 1. trg_enforce_asset_batch_authority
- **Migration:** 0122_create_data_authority_triggers.sql
- **Timing:** BEFORE INSERT OR UPDATE
- **Function:** enforce_asset_batch_authority()
- **Purpose:** Enforces data authority level on asset batches
- **Status:** Active

### 2. trg_enforce_attestation_freshness
- **Migration:** 0170_attestation_anti_replay.sql
- **Timing:** BEFORE INSERT OR UPDATE
- **Function:** enforce_attestation_freshness()
- **Purpose:** Anti-replay enforcement via attestation nonce uniqueness
- **Status:** Active

### 3. trg_attestation_gate_asset_batches
- **Migration:** 0171_attestation_kill_switch_gate.sql
- **Timing:** BEFORE INSERT
- **Function:** validate_attestation_gate()
- **Purpose:** DB attestation kill switch gate - aborts INSERT on missing/malformed/stale/contract-mismatched attestations
- **Status:** Active

## Competing Authority Paths

The current topology has **3 independent BEFORE triggers** on `asset_batches`:
- Multiple triggers execute in lexical order (unreliable)
- No single dispatcher coordinates execution
- Wave 8 requires one authoritative dispatcher trigger

## Wave 8 Required Topology

One authoritative dispatcher trigger on `asset_batches` that:
- Invokes all validation gates in explicit sequence
- Does not rely on lexical trigger-order behavior
- Provides deterministic execution path

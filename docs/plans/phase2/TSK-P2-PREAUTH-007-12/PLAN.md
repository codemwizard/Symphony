# TSK-P2-PREAUTH-007-12 PLAN — Attestation Seam Schema

Task: TSK-P2-PREAUTH-007-12
Owner: DB_FOUNDATION
Gap Source: G-10 part 1 (W7_GAP_ANALYSIS.md line 168, lines 243-255)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-12.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only.
- Mandatory markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

Add nullable attestation columns and enums to `asset_batches` to create the invariant attestation seam. This is the **schema portion only** — the anti-replay logic is in TSK-P2-PREAUTH-007-13. Population of these columns is deferred to Wave 8.

**Architect Ruling (G-10, lines 243-255):**
Schema-only is insufficient. Schema + contract is the minimum real seam. This task creates the schema AND defines the contract specifications that constrain how the columns are used.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.
- [ ] `asset_batches` table exists in the database.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/XXXX_attestation_seam_schema.sql` | CREATE | Migration adding attestation columns |
| `scripts/audit/verify_tsk_p2_preauth_007_12.sh` | CREATE | Verifier |
| `evidence/phase2/tsk_p2_preauth_007_12.json` | CREATE | Output artifact |

---

## Stop Conditions

- **If only columns are added without the contract definitions** → STOP (schema-only is explicitly insufficient per architect ruling)
- **If columns are NOT NULL** → STOP (they must be nullable — population deferred to Wave 8)

---

## Implementation Steps

### Step 1: Author Migration

**Exact Columns to Add (from G-10, line 168):**

1. `invariant_attestation_hash VARCHAR(128) NULL`
   - Hash format: SHA-256 hex digest (64 chars) or SHA-512 (128 chars)
   - Must be computed over a canonical serialization (defined in contract, enforced in 007-13)

2. `invariant_attestation_version INTEGER NULL`
   - Monotonically increasing version number
   - Version contract: defines what changes constitute a version bump
   - First version = 1

3. `invariant_attested_at TIMESTAMPTZ NULL`
   - Timestamp of when invariant evaluation occurred
   - Must be UTC

4. `invariant_attestation_source attestation_source_type NULL`
   - New ENUM type `attestation_source_type`
   - Values: `'pre_ci_gate'`, `'runtime_gate'`, `'manual_audit'`, `'deferred'`
   - Defines what system produced the attestation

**Contract Definitions (must be documented in migration comments or separate doc):**
- **Version contract**: What `invariant_attestation_version` means — each bump represents a change in the invariant set, the hash algorithm, or the serialization format.
- **Hash format contract**: SHA-256 over canonical JSON serialization of the invariant evaluation result.
- **Write ownership**: Only the invariant gate function (from 007-14) may populate these columns. Direct writes are prohibited.

**Migration Template:**
```sql
BEGIN;

-- Create attestation source enum
CREATE TYPE attestation_source_type AS ENUM (
  'pre_ci_gate',
  'runtime_gate',
  'manual_audit',
  'deferred'
);

-- Add attestation seam columns (all nullable — population deferred to Wave 8)
ALTER TABLE asset_batches
  ADD COLUMN invariant_attestation_hash VARCHAR(128) NULL,
  ADD COLUMN invariant_attestation_version INTEGER NULL,
  ADD COLUMN invariant_attested_at TIMESTAMPTZ NULL,
  ADD COLUMN invariant_attestation_source attestation_source_type NULL;

-- Add check constraint on hash format (when populated)
ALTER TABLE asset_batches
  ADD CONSTRAINT attestation_hash_format
    CHECK (invariant_attestation_hash IS NULL OR invariant_attestation_hash ~ '^[a-f0-9]{64,128}$');

-- Add check constraint on version (when populated, must be positive)
ALTER TABLE asset_batches
  ADD CONSTRAINT attestation_version_positive
    CHECK (invariant_attestation_version IS NULL OR invariant_attestation_version > 0);

COMMENT ON COLUMN asset_batches.invariant_attestation_hash IS
  'SHA-256 hex digest over canonical JSON serialization of invariant evaluation result. Population deferred to Wave 8.';
COMMENT ON COLUMN asset_batches.invariant_attestation_version IS
  'Monotonic version of the invariant evaluation contract. Bumps on invariant set change, hash algo change, or serialization format change.';

COMMIT;
```

### Step 2: Build Verifier

**Positive Tests:**
1. Verify all 4 columns exist on `asset_batches` via `information_schema.columns`.
2. Verify `attestation_source_type` ENUM exists with expected values.
3. Verify all columns accept NULL (INSERT a row without attestation data → must succeed, then ROLLBACK).

**Negative Tests:**
1. INSERT with `invariant_attestation_hash = 'not-a-hex-string'` → must be REJECTED by check constraint.
2. INSERT with `invariant_attestation_version = 0` → must be REJECTED (version must be > 0).
3. INSERT with `invariant_attestation_version = -1` → must be REJECTED.

### Step 3: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_12.sh > evidence/phase2/tsk_p2_preauth_007_12.json
```

### Step 4: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.

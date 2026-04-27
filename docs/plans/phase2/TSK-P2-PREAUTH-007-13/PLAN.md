# TSK-P2-PREAUTH-007-13 PLAN — Attestation Anti-Replay Contract

Task: TSK-P2-PREAUTH-007-13
Owner: DB_FOUNDATION
Gap Source: G-10 part 2 (W7_GAP_ANALYSIS.md line 168)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-13.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only.
- Mandatory markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

Implement the anti-replay DB logic that prevents attestation reuse. Without anti-replay, an attestation becomes a reusable token instead of a decision-bound proof. This task builds on the attestation seam schema from TSK-P2-PREAUTH-007-12.

**Why Anti-Replay Matters (from G-10):**
The attestation hash must be decision-bound, not reusable. The same attestation hash may NOT gate two distinct issuance events. Without this, a single passing invariant evaluation can be "replayed" to authorize unlimited issuances.

---

## Pre-conditions

- [ ] TSK-P2-PREAUTH-007-12 completed (attestation columns exist on `asset_batches`).
- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/XXXX_attestation_anti_replay.sql` | CREATE | Migration adding anti-replay constraints |
| `scripts/audit/verify_tsk_p2_preauth_007_13.sh` | CREATE | Verifier |
| `evidence/phase2/tsk_p2_preauth_007_13.json` | CREATE | Output artifact |

---

## Stop Conditions

- **If attestation hash uniqueness is not enforced** → STOP
- **If stale attestations (expired TTL) can still gate issuance** → STOP
- **If the anti-replay mechanism is application-layer only (not DB-enforced)** → STOP

---

## Implementation Steps

### Step 1: Author Migration

**Anti-Replay Components (from G-10, line 168):**

1. **Nonce / Monotonic Sequence Number:**
   - Add `attestation_nonce BIGINT NULL` to `asset_batches` (or use a separate tracking table)
   - Each attestation must carry a unique nonce
   - UNIQUE constraint prevents reuse

2. **Evaluation Epoch:**
   - The `invariant_attested_at` column (from 007-12) serves as the epoch
   - Add a CHECK constraint or trigger enforcing freshness

3. **Freshness TTL:**
   - Define a maximum age for attestations (e.g., 300 seconds)
   - BEFORE INSERT trigger on `asset_batches`: if `invariant_attested_at` is populated AND `NOW() - invariant_attested_at > INTERVAL '300 seconds'` → REJECT as stale

4. **Replay Invalidation Rule:**
   - UNIQUE constraint on `invariant_attestation_hash` prevents the same hash from gating two distinct issuance events
   - Alternative: separate `attestation_consumption_log` table tracking consumed attestation hashes

5. **Canonicalization Contract:**
   - `invariant_attestation_hash` must be computed over canonical serialization
   - Canonical rules: explicit field ordering (alphabetical), UTF-8 encoding, NULL represented as JSON `null`, ENUMs as string values, timestamps as UTC ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)
   - Versioned by `invariant_attestation_version` — changing the serialization requires a version bump

**Migration Template:**
```sql
BEGIN;

-- Add nonce column for replay prevention
ALTER TABLE asset_batches
  ADD COLUMN attestation_nonce BIGINT NULL;

-- Unique constraint: no two issuances may use the same attestation hash
ALTER TABLE asset_batches
  ADD CONSTRAINT unique_attestation_hash
    UNIQUE (invariant_attestation_hash);

-- Create freshness enforcement trigger
CREATE OR REPLACE FUNCTION enforce_attestation_freshness()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  max_age INTERVAL := INTERVAL '300 seconds';
BEGIN
  -- Only enforce when attestation is populated
  IF NEW.invariant_attested_at IS NOT NULL THEN
    IF (NOW() - NEW.invariant_attested_at) > max_age THEN
      RAISE EXCEPTION 'Attestation is stale: attested at %, current time %, max age %',
        NEW.invariant_attested_at, NOW(), max_age;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enforce_attestation_freshness
  BEFORE INSERT ON asset_batches
  FOR EACH ROW
  EXECUTE FUNCTION enforce_attestation_freshness();

COMMIT;
```

### Step 2: Build Verifier

**Positive Tests:**
1. Verify `attestation_nonce` column exists.
2. Verify `unique_attestation_hash` constraint exists.
3. Verify `trg_enforce_attestation_freshness` trigger exists.
4. INSERT a row with fresh attestation (within TTL) → must succeed (then ROLLBACK).

**Negative Tests (all ROLLBACK):**
1. INSERT two rows with the SAME `invariant_attestation_hash` → second must be REJECTED by unique constraint.
2. INSERT a row with `invariant_attested_at = NOW() - INTERVAL '600 seconds'` → must be REJECTED as stale.
3. INSERT a row with `invariant_attested_at = NOW() - INTERVAL '301 seconds'` → must be REJECTED (boundary test).

### Step 3: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_13.sh > evidence/phase2/tsk_p2_preauth_007_13.json
```

### Step 4: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.

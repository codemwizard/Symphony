# TSK-P2-PREAUTH-007-14 PLAN — Attestation Kill Switch Gate

Task: TSK-P2-PREAUTH-007-14
Owner: DB_FOUNDATION
Gap Source: G-04 (W7_GAP_ANALYSIS.md line 162, lines 231-241)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-14.PROOF_FAIL
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

Enforce structural attestation integrity and registry-contract binding at the authoritative issuance write boundary. Reject writes when attestation inputs are absent, malformed, stale, duplicate at the persisted decision-token identity boundary, or bound to a stale registry contract. Cryptographic proof-of-execution and signature validation are explicitly deferred to Wave 8.

---

## Pre-conditions

- [ ] TSK-P2-PREAUTH-007-06 completed (`invariant_registry` table exists).
- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0171_attestation_kill_switch_gate.sql` | CREATE | Migration adding strict DDL and the gate trigger |
| `scripts/audit/verify_tsk_p2_preauth_007_14.sh` | CREATE | Verifier using live behavioral tests |
| `evidence/phase2/tsk_p2_preauth_007_14.json` | CREATE | Output artifact |

---

## Stop Conditions

- **If the trigger queries global registry status instead of validating attestation** → STOP
- **If the trigger tries to fully reconstruct cryptographic hashes (Wave 8 scope)** → STOP
- **If the negative tests rely on string-matching instead of physical `INSERT` rejection** → STOP

---

## Implementation Steps

### Step 1: Author Migration (0171_attestation_kill_switch_gate.sql)

**Harden Schema:**
- Add `registry_snapshot_hash VARCHAR(64) NULL` to `asset_batches`.
- Alter `invariant_attestation_hash` to `VARCHAR(64)` and strictly enforce format.
```sql
ALTER TABLE public.asset_batches ADD CONSTRAINT registry_snapshot_hash_format CHECK (registry_snapshot_hash IS NULL OR registry_snapshot_hash ~ '^[0-9a-f]{64}$');
ALTER TABLE public.asset_batches ALTER COLUMN invariant_attestation_hash TYPE VARCHAR(64);
ALTER TABLE public.asset_batches DROP CONSTRAINT IF EXISTS attestation_hash_format;
ALTER TABLE public.asset_batches ADD CONSTRAINT attestation_hash_format CHECK (invariant_attestation_hash IS NULL OR invariant_attestation_hash ~ '^[0-9a-f]{64}$');
```

**Canonical Snapshot Aggregation:**
Use `jsonb_agg` inside `COALESCE` to deterministically hash the live contract.
```sql
SELECT encode(digest(
  COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'invariant_id', invariant_id,
          'checksum', checksum,
          'is_blocking', is_blocking,
          'severity', severity,
          'execution_layer', execution_layer,
          'verifier_type', verifier_type
        ) ORDER BY invariant_id ASC
      )
      FROM invariant_registry 
      WHERE is_blocking = true
    ), 
    '[]'::jsonb
  )::text, 'sha256'), 'hex') INTO live_snapshot_hash;
```

**Validation Predicates:**
Reject if fields are NULL, if timestamp is stale (`< NOW() - INTERVAL '300 seconds'`), or if the snapshot hash mismatches the computed `live_snapshot_hash`.

### Step 2: Build Verifier

**Negative Tests (Behavioral INSERTs inside BEGIN/ROLLBACK):**
1. **Missing Fields**: `INSERT` without attestation fields.
2. **Malformed Structure**: `INSERT` with missing version or missing nonce.
3. **Future Skew**: `INSERT` with `invariant_attested_at` > `NOW() + 5s`.
4. **Contract Mismatch**: `INSERT` with `registry_snapshot_hash = 'badhash'`.
5. **Duplicate Persisted Identity**: `INSERT` two rows with the exact same `invariant_attestation_hash` (the 0170 uniqueness key).
6. **Stale Timestamp**: `INSERT` with `invariant_attested_at` < `NOW() - 300s`.

**Positive Test:**
`INSERT` with valid attestation fields matching the live snapshot hash.

### Step 3: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_14.sh > evidence/phase2/tsk_p2_preauth_007_14.json
```

### Step 4: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.

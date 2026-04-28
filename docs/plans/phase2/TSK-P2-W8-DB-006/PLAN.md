# TSK-P2-W8-DB-006 PLAN - Authoritative trigger integration of cryptographic primitive

Task: TSK-P2-W8-DB-006
Owner: DB_FOUNDATION
failure_signature: P2.W8.TSK_P2_W8_DB_006.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Wire the primitive into the authoritative PostgreSQL write path so Wave 8
stops being helper code and becomes boundary enforcement.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `cryptographic enforcement wiring`
- PostgreSQL independently validates the exact `asset_batches` write.
- PostgreSQL does not trust a service claim or audit row.
- Cryptographic branch causality must be proven.
- Branch provenance must come from the same production execution path that emits the terminal SQLSTATE.

## Work Items

### Step 1
**What:** [ID w8_db_006_work_01] Integrate the Ed25519 verification primitive into the `asset_batches` dispatcher path so PostgreSQL independently validates the exact write inside the authoritative boundary.
**Done when:** [ID w8_db_006_work_01] PostgreSQL independently validates the exact `asset_batches` write and the Ed25519 primitive executes inside that authoritative dispatcher path.

### Step 2
**What:** [ID w8_db_006_work_02] Enforce fail-closed rejection for invalid signatures and unavailable-crypto states with registered failure modes and explicit cryptographic branch causality.
**Done when:** [ID w8_db_006_work_02] Invalid signatures and unavailable-crypto states are rejected fail-closed with registered failure modes and explicit cryptographic branch causality.

### Step 3
**What:** [ID w8_db_006_work_03] Build a verifier that proves PostgreSQL rejects cryptographically invalid writes and unavailable-crypto states at `asset_batches`, does not trust a service claim or audit row, and derives branch provenance from the same production execution path that emits the terminal SQLSTATE.
**Done when:** [ID w8_db_006_work_03] The verifier proves PostgreSQL physically rejects invalid or unavailable-crypto writes at `asset_batches` without trusting a service claim or audit row, and branch provenance comes from the same production execution path as the terminal SQLSTATE.

## Verification

```bash
bash scripts/db/verify_tsk_p2_w8_db_006.sh > evidence/phase2/tsk_p2_w8_db_006.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-DB-006/PLAN.md --meta tasks/TSK-P2-W8-DB-006/meta.yml
```

## Database Connection

The PostgreSQL container IP is dynamic. To find the current IP:
```bash
docker inspect symphony-postgres | grep IPAddress
```

Then set DATABASE_URL:
```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@<dynamic-ip>:55432/symphony"
```

For local development with Docker Compose, the hostname may be `symphony-postgres` or `localhost:55432` depending on network configuration.

## Baseline Drift Handling

If `schema/baseline.sql` changes during this task:
1. The change must be accompanied by at least one migration change in the same PR
2. An explanation artifact must be created (ADR or plan log entry) describing why baseline changed
3. Run `scripts/db/check_baseline_drift.sh` to generate evidence at `./evidence/phase0/baseline_drift.json`
4. Baseline drift checks are fail-closed in CI

Reference: docs/PLANS-addendum_1.md sections 1-3

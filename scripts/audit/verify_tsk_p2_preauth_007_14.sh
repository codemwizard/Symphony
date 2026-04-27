#!/bin/bash
set -e

# Task: TSK-P2-PREAUTH-007-14
# Description: Behavioral proof of the Attestation Kill Switch Gate (Origin-mode)
# Requirement: scripts/dev/seed_canonical_test_data.sql must have been applied.

TASK_ID="TSK-P2-PREAUTH-007-14"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_14.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Ensure EVIDENCE_PATH directory exists
mkdir -p "$(dirname "$EVIDENCE_PATH")"

# Initialize evidence
cat <<EOF > "$EVIDENCE_PATH"
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": []
}
EOF

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL not set" >&2
  exit 1
fi

# 1. Structural Check: Verify Migration 0171 is registered
MIGRATION_CHECK=$(psql "$DATABASE_URL" -t -c "SELECT count(*) FROM schema_migrations WHERE version = '0171_attestation_kill_switch_gate.sql';" | tr -d '[:space:]')
if [ "$MIGRATION_CHECK" -eq 1 ]; then
    jq '.checks += [{"id": "migration_0171_registered", "description": "Verify 0171 is in schema_migrations", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
    echo "ERROR: Migration 0171 not registered" >&2
    exit 1
fi

echo "Executing Origin-mode behavioral test suite..."
TEST_OUTPUT=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -t -c "
BEGIN;

DO \$\$
DECLARE
  v_tenant_id UUID;
  v_project_id UUID;
  v_snapshot_hash VARCHAR(64);
  v_hash1 VARCHAR(64) := '1111111111111111111111111111111111111111111111111111111111111111';
  v_hash2 VARCHAR(64) := '2222222222222222222222222222222222222222222222222222222222222222';
BEGIN
  -- 1. Fetch IDs from canonical seed
  SELECT tenant_id INTO v_tenant_id FROM tenants WHERE tenant_key = 'canonical_test_tenant' LIMIT 1;
  SELECT project_id INTO v_project_id FROM projects WHERE name = 'Symphony Test Project' LIMIT 1;
  
  IF v_tenant_id IS NULL OR v_project_id IS NULL THEN
    RAISE EXCEPTION 'Test failed: Seed data missing. Run scripts/dev/seed_canonical_test_data.sql first.';
  END IF;

  -- 2. Compute Live Snapshot Hash
  SELECT encode(digest(COALESCE((SELECT jsonb_agg(jsonb_build_object('invariant_id', invariant_id, 'checksum', checksum, 'is_blocking', is_blocking, 'severity', severity, 'execution_layer', execution_layer, 'verifier_type', verifier_type) ORDER BY invariant_id ASC) FROM invariant_registry WHERE is_blocking = true), '[]'::jsonb)::text, 'sha256'), 'hex') INTO v_snapshot_hash;

  -- Negative Test 1: Structural Rejection (Missing Fields)
  BEGIN
    INSERT INTO asset_batches (tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation) 
    VALUES (v_tenant_id, v_project_id, 'ISSUANCE', 100, 'PENDING', 'phase1_indicative_only', false, 'test');
    RAISE EXCEPTION 'N1 Failed: Should have rejected missing fields';
  EXCEPTION WHEN sqlstate 'GF074' THEN
    -- PASS N1
  END;

  -- Negative Test 2: Future Skew
  BEGIN
    INSERT INTO asset_batches (tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation, invariant_attestation_hash, invariant_attestation_version, invariant_attested_at, invariant_attestation_source, attestation_nonce, registry_snapshot_hash) 
    VALUES (v_tenant_id, v_project_id, 'ISSUANCE', 100, 'PENDING', 'phase1_indicative_only', false, 'test', v_hash1, 1, NOW() + INTERVAL '10 seconds', 'pre_ci_gate', 1, v_snapshot_hash);
    RAISE EXCEPTION 'N2 Failed: Should have rejected future skew';
  EXCEPTION WHEN sqlstate 'GF076' THEN
    -- PASS N2
  END;

  -- Negative Test 3: Contract Mismatch
  BEGIN
    INSERT INTO asset_batches (tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation, invariant_attestation_hash, invariant_attestation_version, invariant_attested_at, invariant_attestation_source, attestation_nonce, registry_snapshot_hash) 
    VALUES (v_tenant_id, v_project_id, 'ISSUANCE', 100, 'PENDING', 'phase1_indicative_only', false, 'test', v_hash1, 1, NOW(), 'pre_ci_gate', 1, 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef');
    RAISE EXCEPTION 'N3 Failed: Should have rejected contract mismatch';
  EXCEPTION WHEN sqlstate 'GF077' THEN
    -- PASS N3
  END;

  -- Negative Test 4: Stale Timestamp
  BEGIN
    INSERT INTO asset_batches (tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation, invariant_attestation_hash, invariant_attestation_version, invariant_attested_at, invariant_attestation_source, attestation_nonce, registry_snapshot_hash) 
    VALUES (v_tenant_id, v_project_id, 'ISSUANCE', 100, 'PENDING', 'phase1_indicative_only', false, 'test', v_hash1, 1, NOW() - INTERVAL '301 seconds', 'pre_ci_gate', 1, v_snapshot_hash);
    RAISE EXCEPTION 'N4 Failed: Should have rejected stale timestamp';
  EXCEPTION WHEN sqlstate 'GF075' THEN
    -- PASS N4
  END;

  -- Negative Test 5: Duplicate Decision Token Identity (Anti-Replay)
  BEGIN
    INSERT INTO asset_batches (tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation, invariant_attestation_hash, invariant_attestation_version, invariant_attested_at, invariant_attestation_source, attestation_nonce, registry_snapshot_hash) 
    VALUES (v_tenant_id, v_project_id, 'ISSUANCE', 100, 'PENDING', 'phase1_indicative_only', false, 'test', v_hash2, 1, NOW(), 'pre_ci_gate', 2, v_snapshot_hash);
    
    INSERT INTO asset_batches (tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation, invariant_attestation_hash, invariant_attestation_version, invariant_attested_at, invariant_attestation_source, attestation_nonce, registry_snapshot_hash) 
    VALUES (v_tenant_id, v_project_id, 'ISSUANCE', 100, 'PENDING', 'phase1_indicative_only', false, 'test', v_hash2, 1, NOW(), 'pre_ci_gate', 3, v_snapshot_hash);
    RAISE EXCEPTION 'N5 Failed: Should have rejected duplicate identity';
  EXCEPTION WHEN unique_violation THEN
    -- PASS N5
  END;

  -- Positive Test: Valid structural attestation bound to live contract
  INSERT INTO asset_batches (tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation, invariant_attestation_hash, invariant_attestation_version, invariant_attested_at, invariant_attestation_source, attestation_nonce, registry_snapshot_hash) 
  VALUES (v_tenant_id, v_project_id, 'ISSUANCE', 100, 'PENDING', 'phase1_indicative_only', false, 'test', v_hash1, 1, NOW(), 'pre_ci_gate', 4, v_snapshot_hash);

END;
\$\$;

ROLLBACK;
")

if [ $? -eq 0 ]; then
  echo "PASS: Attestation Kill Switch Gate verified in Origin mode."
  jq '.checks += [{"id": "tsk_p2_preauth_007_14_origin_behavioral", "description": "Verify trigger enforcement without replica bypass", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Behavioral tests failed" >&2
  echo "$TEST_OUTPUT" >&2
  exit 1
fi

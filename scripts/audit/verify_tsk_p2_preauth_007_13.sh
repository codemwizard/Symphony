#!/bin/bash
set -e

# Verification script for TSK-P2-PREAUTH-007-13: Attestation Anti-Replay Contract
# This script verifies that anti-replay DB logic (nonce, epoch, freshness TTL constraints) successfully rejects stale or replayed attestations

TASK_ID="TSK-P2-PREAUTH-007-13"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_007_13.json"

# Get git SHA
GIT_SHA=$(git rev-parse HEAD)

# Get timestamp
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize JSON output
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "IN_PROGRESS",
  "checks": [],
  "observed_hashes": []
}
EOF

# Check 1: Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL environment variable not set" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "tsk_p2_preauth_007_13_check_01", "description": "DATABASE_URL is set", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "tsk_p2_preauth_007_13_check_01", "description": "DATABASE_URL is set", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 2: Verify attestation_nonce column exists
NONCE_COL_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'asset_batches' AND column_name = 'attestation_nonce');" 2>/dev/null | tr -d ' ')
if [ "$NONCE_COL_EXISTS" != "t" ]; then
  echo "ERROR: attestation_nonce column does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P1", "description": "Positive test: attestation_nonce column exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P1", "description": "Positive test: attestation_nonce column exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 3: Verify unique_attestation_hash constraint exists
UNIQUE_CONSTRAINT_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_constraint WHERE conname = 'unique_attestation_hash');" 2>/dev/null | tr -d ' ')
if [ "$UNIQUE_CONSTRAINT_EXISTS" != "t" ]; then
  echo "ERROR: unique_attestation_hash constraint does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P2", "description": "Positive test: unique_attestation_hash constraint exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P2", "description": "Positive test: unique_attestation_hash constraint exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 4: Verify trg_enforce_attestation_freshness trigger exists
TRIGGER_EXISTS=$(psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trg_enforce_attestation_freshness');" 2>/dev/null | tr -d ' ')
if [ "$TRIGGER_EXISTS" != "t" ]; then
  echo "ERROR: trg_enforce_attestation_freshness trigger does not exist" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P3", "description": "Positive test: trg_enforce_attestation_freshness trigger exists", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P3", "description": "Positive test: trg_enforce_attestation_freshness trigger exists", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Check 5: Positive test - INSERT with fresh attestation (within TTL) must succeed
POSITIVE_FRESHNESS_TEST=$(psql "$DATABASE_URL" -t -c "
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Create test data chain: billable_clients → tenants → projects → asset_batches
INSERT INTO billable_clients (billable_client_id, legal_name, client_type, client_key, status, created_at) 
VALUES (gen_random_uuid(), 'test_client', 'BANK', 'test_client_key', 'ACTIVE', NOW());
INSERT INTO tenants (tenant_id, tenant_key, tenant_name, tenant_type, billable_client_id, status, created_at) 
SELECT gen_random_uuid(), 'test_tenant_key', 'test_tenant', 'NGO', billable_client_id, 'ACTIVE', NOW() 
FROM billable_clients WHERE legal_name = 'test_client' LIMIT 1;
INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned, created_at) 
SELECT gen_random_uuid(), tenant_id, 'test_project', 'ACTIVE', false, NOW() 
FROM tenants WHERE tenant_name = 'test_tenant' LIMIT 1;
-- Now test fresh attestation
INSERT INTO asset_batches (
  tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation,
  invariant_attestation_hash, invariant_attested_at, attestation_nonce
) SELECT 
  t.tenant_id, p.project_id, 'issuance', 100, 'PENDING', 'phase1_indicative_only', false, 'test explanation',
  encode(digest(gen_random_uuid()::text, 'sha256'), 'hex'), NOW(), 12345
FROM tenants t CROSS JOIN projects p WHERE t.tenant_name = 'test_tenant' AND p.name = 'test_project' LIMIT 1;
ROLLBACK;
SELECT 'INSERT_ACCEPTED';
" 2>&1)

if [[ "$POSITIVE_FRESHNESS_TEST" == *"INSERT_ACCEPTED"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P4", "description": "Positive test: Fresh attestation within TTL accepted", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Positive test failed - fresh attestation was rejected" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-P4", "description": "Positive test: Fresh attestation within TTL accepted", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 6: Negative test - INSERT two rows with SAME invariant_attestation_hash → second must be REJECTED
NEGATIVE_UNIQUE_TEST=$(psql "$DATABASE_URL" -t -c "
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Create test data chain: billable_clients → tenants → projects → asset_batches
INSERT INTO billable_clients (billable_client_id, legal_name, client_type, client_key, status, created_at) 
VALUES (gen_random_uuid(), 'test_client', 'BANK', 'test_client_key', 'ACTIVE', NOW());
INSERT INTO tenants (tenant_id, tenant_key, tenant_name, tenant_type, billable_client_id, status, created_at) 
SELECT gen_random_uuid(), 'test_tenant_key', 'test_tenant', 'NGO', billable_client_id, 'ACTIVE', NOW() 
FROM billable_clients WHERE legal_name = 'test_client' LIMIT 1;
INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned, created_at) 
SELECT gen_random_uuid(), tenant_id, 'test_project', 'ACTIVE', false, NOW() 
FROM tenants WHERE tenant_name = 'test_tenant' LIMIT 1;
-- Insert first row with hash
INSERT INTO asset_batches (
  tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation,
  invariant_attestation_hash, invariant_attested_at, attestation_nonce
) SELECT 
  t.tenant_id, p.project_id, 'issuance', 100, 'PENDING', 'phase1_indicative_only', false, 'test explanation',
  encode(digest('test_duplicate_hash', 'sha256'), 'hex'), NOW(), 12345
FROM tenants t CROSS JOIN projects p WHERE t.tenant_name = 'test_tenant' AND p.name = 'test_project' LIMIT 1;
-- Attempt to insert second row with same hash - should be rejected
INSERT INTO asset_batches (
  tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation,
  invariant_attestation_hash, invariant_attested_at, attestation_nonce
) SELECT 
  t.tenant_id, p.project_id, 'issuance', 100, 'PENDING', 'phase1_indicative_only', false, 'test explanation',
  encode(digest('test_duplicate_hash', 'sha256'), 'hex'), NOW(), 67890
FROM tenants t CROSS JOIN projects p WHERE t.tenant_name = 'test_tenant' AND p.name = 'test_project' LIMIT 1;
ROLLBACK;
SELECT 'DUPLICATE_ACCEPTED';
" 2>&1 || echo "DUPLICATE_REJECTED")

if [[ "$NEGATIVE_UNIQUE_TEST" == *"DUPLICATE_REJECTED"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-N1", "description": "Negative test: Duplicate attestation hash rejected", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - duplicate attestation hash was not rejected" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-N1", "description": "Negative test: Duplicate attestation hash rejected", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 7: Negative test - INSERT with stale attestation (600 seconds old) → must be REJECTED
NEGATIVE_STALE_TEST=$(psql "$DATABASE_URL" -t -c "
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Create test data chain: billable_clients → tenants → projects → asset_batches
INSERT INTO billable_clients (billable_client_id, legal_name, client_type, client_key, status, created_at) 
VALUES (gen_random_uuid(), 'test_client', 'BANK', 'test_client_key', 'ACTIVE', NOW());
INSERT INTO tenants (tenant_id, tenant_key, tenant_name, tenant_type, billable_client_id, status, created_at) 
SELECT gen_random_uuid(), 'test_tenant_key', 'test_tenant', 'NGO', billable_client_id, 'ACTIVE', NOW() 
FROM billable_clients WHERE legal_name = 'test_client' LIMIT 1;
INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned, created_at) 
SELECT gen_random_uuid(), tenant_id, 'test_project', 'ACTIVE', false, NOW() 
FROM tenants WHERE tenant_name = 'test_tenant' LIMIT 1;
-- Attempt to insert stale attestation
INSERT INTO asset_batches (
  tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation,
  invariant_attestation_hash, invariant_attested_at, attestation_nonce
) SELECT 
  t.tenant_id, p.project_id, 'issuance', 100, 'PENDING', 'phase1_indicative_only', false, 'test explanation',
  encode(digest('test_stale_hash', 'sha256'), 'hex'), NOW() - INTERVAL '600 seconds', 12345
FROM tenants t CROSS JOIN projects p WHERE t.tenant_name = 'test_tenant' AND p.name = 'test_project' LIMIT 1;
ROLLBACK;
SELECT 'STALE_ACCEPTED';
" 2>&1 || echo "STALE_REJECTED")

if [[ "$NEGATIVE_STALE_TEST" == *"STALE_REJECTED"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-N2", "description": "Negative test: Stale attestation (600s) rejected", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - stale attestation was not rejected" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-N2", "description": "Negative test: Stale attestation (600s) rejected", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Check 8: Negative test - INSERT with boundary stale attestation (301 seconds old) → must be REJECTED
NEGATIVE_BOUNDARY_TEST=$(psql "$DATABASE_URL" -t -c "
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Create test data chain: billable_clients → tenants → projects → asset_batches
INSERT INTO billable_clients (billable_client_id, legal_name, client_type, client_key, status, created_at) 
VALUES (gen_random_uuid(), 'test_client', 'BANK', 'test_client_key', 'ACTIVE', NOW());
INSERT INTO tenants (tenant_id, tenant_key, tenant_name, tenant_type, billable_client_id, status, created_at) 
SELECT gen_random_uuid(), 'test_tenant_key', 'test_tenant', 'NGO', billable_client_id, 'ACTIVE', NOW() 
FROM billable_clients WHERE legal_name = 'test_client' LIMIT 1;
INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned, created_at) 
SELECT gen_random_uuid(), tenant_id, 'test_project', 'ACTIVE', false, NOW() 
FROM tenants WHERE tenant_name = 'test_tenant' LIMIT 1;
-- Attempt to insert boundary stale attestation
INSERT INTO asset_batches (
  tenant_id, project_id, batch_type, quantity, status, data_authority, audit_grade, authority_explanation,
  invariant_attestation_hash, invariant_attested_at, attestation_nonce
) SELECT 
  t.tenant_id, p.project_id, 'issuance', 100, 'PENDING', 'phase1_indicative_only', false, 'test explanation',
  encode(digest('test_boundary_hash', 'sha256'), 'hex'), NOW() - INTERVAL '301 seconds', 12345
FROM tenants t CROSS JOIN projects p WHERE t.tenant_name = 'test_tenant' AND p.name = 'test_project' LIMIT 1;
ROLLBACK;
SELECT 'BOUNDARY_ACCEPTED';
" 2>&1 || echo "BOUNDARY_REJECTED")

if [[ "$NEGATIVE_BOUNDARY_TEST" == *"BOUNDARY_REJECTED"* ]]; then
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-N3", "description": "Negative test: Boundary stale attestation (301s) rejected", "result": "PASS"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
else
  echo "ERROR: Negative test failed - boundary stale attestation was not rejected" >&2
  jq '.status = "FAIL"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  jq '.checks += [{"id": "TSK-P2-PREAUTH-007-13-N3", "description": "Negative test: Boundary stale attestation (301s) rejected", "result": "FAIL"}]' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"
  exit 1
fi

# Add observed hash for the script
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
jq ".observed_hashes += [{\"path\": \"$0\", \"sha256\": \"$SCRIPT_HASH\"}]" "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

# Final success update
jq '.status = "PASS"' "$EVIDENCE_PATH" > "$EVIDENCE_PATH.tmp" && mv "$EVIDENCE_PATH.tmp" "$EVIDENCE_PATH"

echo "PASS: Attestation Anti-Replay Contract verified"

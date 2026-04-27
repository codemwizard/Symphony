-- Symphony Master Canonical Seed Script (V15)
-- Purpose: Establish a 100% compliant, cascading test baseline for Phase 2 verifiers.
-- Authoritative Schema Source: information_schema (Forensic Audit 2026-04-26)

BEGIN;

-- 1. Seed Billable Client
INSERT INTO billable_clients (billable_client_id, legal_name, client_type, status, client_key)
VALUES (
    '00000000-0000-0000-0000-000000000001', 
    'Symphony Pilot Client', 
    'ENTERPRISE', 
    'ACTIVE', 
    'canonical_test_client'
) ON CONFLICT (billable_client_id) DO NOTHING;

-- 2. Seed Tenant
INSERT INTO tenants (tenant_id, billable_client_id, tenant_key, tenant_name, tenant_type, status)
VALUES (
    '00000000-0000-0000-0000-000000000002', 
    '00000000-0000-0000-0000-000000000001', 
    'ten-zambiagrn', 
    'Zambia Green MFI', 
    'COMMERCIAL', 
    'ACTIVE'
) ON CONFLICT (tenant_id) DO NOTHING;

-- 3. Seed Project
INSERT INTO projects (project_id, tenant_id, name, status, taxonomy_aligned)
VALUES (
    '00000000-0000-0000-0000-000000000003', 
    '00000000-0000-0000-0000-000000000002', 
    'GreenTech4CE · Solar Cluster A', 
    'ACTIVE', 
    false
) ON CONFLICT (project_id) DO NOTHING;

-- 4. Seed Invariant Registry
INSERT INTO invariant_registry (invariant_id, verifier_type, description, severity, execution_layer, is_blocking, checksum)
VALUES (
    'INV-CANONICAL-TEST-001', 
    'sql_assertion', 
    'Canonical Test Invariant', 
    'CRITICAL', 
    'DB', 
    true, 
    '1111111111111111111111111111111111111111111111111111111111111111'
) ON CONFLICT (invariant_id) DO NOTHING;

-- 5. Seed Interpretation Pack
INSERT INTO interpretation_packs (
    interpretation_pack_id, 
    jurisdiction_code, 
    pack_type, 
    project_id, 
    interpretation_pack_code, 
    effective_from,
    pack_payload_json
) VALUES (
    '00000000-0000-0000-0000-000000000004', 
    'ZM', 
    'PRIMARY', 
    '00000000-0000-0000-0000-000000000003', 
    '00000000-0000-0000-0000-00000000000a', 
    NOW(),
    '{}'
) ON CONFLICT (interpretation_pack_id) DO NOTHING;

-- 6. Seed Execution Record
INSERT INTO execution_records (
    execution_id, 
    tenant_id, 
    project_id, 
    status, 
    interpretation_version_id, 
    input_hash, 
    output_hash, 
    runtime_version
) VALUES (
    '00000000-0000-0000-0000-000000000005', 
    '00000000-0000-0000-0000-000000000002', 
    '00000000-0000-0000-0000-000000000003', 
    'COMPLETED', 
    '00000000-0000-0000-0000-000000000004', 
    '1111111111111111111111111111111111111111111111111111111111111111', 
    '1111111111111111111111111111111111111111111111111111111111111111', 
    'v1.0.0-pilot'
) ON CONFLICT (execution_id) DO NOTHING;

-- 7. Seed Policy Decision
INSERT INTO policy_decisions (
    policy_decision_id, 
    execution_id, 
    project_id, 
    decision_type, 
    authority_scope, 
    declared_by, 
    entity_type, 
    entity_id, 
    decision_hash, 
    signature, 
    signed_at
) VALUES (
    '00000000-0000-0000-0000-000000000006', 
    '00000000-0000-0000-0000-000000000005', 
    '00000000-0000-0000-0000-000000000003', 
    'APPROVAL', 
    'GLOBAL', 
    '00000000-0000-0000-0000-000000000001', 
    'ASSET_BATCH', 
    '00000000-0000-0000-0000-00000000000b', 
    '1111111111111111111111111111111111111111111111111111111111111111', 
    '11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111', 
    NOW()
) ON CONFLICT (policy_decision_id) DO NOTHING;

-- 8. Seed State Rules
INSERT INTO state_rules (state_rule_id, entity_type, from_state, to_state, required_decision_type, allowed)
VALUES 
    (gen_random_uuid(), 'ASSET_BATCH', 'draft', 'pending', 'APPROVAL', true),
    (gen_random_uuid(), 'ASSET_BATCH', 'pending', 'completed', 'APPROVAL', true),
    (gen_random_uuid(), 'ASSET_BATCH', 'pending', 'rejected', 'REJECTION', true)
ON CONFLICT (entity_type, from_state, to_state) DO NOTHING;

COMMIT;

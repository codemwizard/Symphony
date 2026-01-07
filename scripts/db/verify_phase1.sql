-- Symphony Phase 1 Verification Script

-- 1. Verify Idempotency Constraints
SELECT conname, contype
FROM pg_constraint
WHERE conname = 'instructions_client_id_client_request_id_key';

-- 2. Verify Orchestration Table structure
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'routes'
AND column_name IN ('client_id', 'provider_id', 'priority_weight', 'is_active');

-- 3. Verify AML/ISO Seam (Outbox)
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'event_outbox';

-- 4. Verify Policy Versions table
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'policy_versions';

-- 5. Verify Immutability (Permissions check)
-- This checks if UPDATE/DELETE are revoked for the audit_log
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'audit_log'
AND privilege_type IN ('UPDATE', 'DELETE');

-- 6. MANUAL VERIFICATION: Idempotency Failure Test
-- Execute the following block. The second insert MUST fail with a unique violation.
/*
INSERT INTO clients (name) VALUES ('Test Client') RETURNING id;
-- Use the returned client_id below:
INSERT INTO instructions (client_id, client_request_id, amount, currency, receiver_reference, status)
VALUES ('<client_id>', 'REQ-001', 100.00, 'USD', 'REF-001', 'RECEIVED');

-- This second one MUST fail:
INSERT INTO instructions (client_id, client_request_id, amount, currency, receiver_reference, status)
VALUES ('<client_id>', 'REQ-001', 100.00, 'USD', 'REF-001', 'RECEIVED');
*/

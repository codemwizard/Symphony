-- Symphony Phase 2 Verification Script
-- Verifies roles and access boundaries.

-- 1. Verify Role Existence
SELECT rolname 
FROM pg_roles 
WHERE rolname IN ('symphony_control', 'symphony_ingest', 'symphony_executor', 'symphony_readonly', 'symphony_auditor');

-- 2. Verify symphony_readonly cannot INSERT
-- Expected result: Permission denied (tested manually)
/*
SET ROLE symphony_readonly;
INSERT INTO clients (name) VALUES ('Rogue Insert');
RESET ROLE;
*/

-- 3. Verify symphony_executor cannot UPDATE routes
-- Expected result: Permission denied
/*
SET ROLE symphony_executor;
UPDATE routes SET is_active = false;
RESET ROLE;
*/

-- 4. Verify symphony_ingest can INSERT instructions
/*
SET ROLE symphony_ingest;
-- Assuming a client exists from Phase 1 test
INSERT INTO instructions (client_id, client_request_id, amount, currency, receiver_reference, status) 
VALUES ('<valid_client_id>', 'REQ-PHASE2-TEST', 10.00, 'USD', 'REF-P2', 'RECEIVED');
RESET ROLE;
*/

-- 5. Verify Immutability for symphony_control (cannot UPDATE audit_log)
/*
SET ROLE symphony_control;
UPDATE audit_log SET action = 'REDACTED';
RESET ROLE;
*/

-- 6. Check specific table grants for symphony_executor
-- This query shows what symphony_executor can do
SELECT table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE grantee = 'symphony_executor' 
ORDER BY table_name;

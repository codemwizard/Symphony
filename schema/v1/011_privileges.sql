-- Symphony Phase 2: Privilege Mappings
-- This script enforces least privilege and directional data flow.

-- 0. Revoke all default privileges from public
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

-- 1. symphony_control (Control Plane Admin)
GRANT SELECT, INSERT, UPDATE ON clients TO symphony_control;
GRANT SELECT, INSERT, UPDATE ON providers TO symphony_control;
GRANT SELECT, INSERT, UPDATE ON routes TO symphony_control;
GRANT SELECT, INSERT, UPDATE ON provider_health_snapshots TO symphony_control;
GRANT SELECT, INSERT ON audit_log TO symphony_control; -- Note: INSERT only for logging admin actions.
GRANT SELECT, INSERT, UPDATE ON policy_versions TO symphony_control;

-- 2. symphony_ingest (Data Plane Ingest)
GRANT SELECT ON clients TO symphony_ingest; -- To verify client exists
GRANT SELECT, INSERT ON instructions TO symphony_ingest;
GRANT SELECT, INSERT ON event_outbox TO symphony_ingest;

-- 3. symphony_executor (Data Plane Execution)
GRANT SELECT ON clients TO symphony_executor;
GRANT SELECT ON providers TO symphony_executor;
GRANT SELECT ON routes TO symphony_executor;
GRANT SELECT ON instructions TO symphony_executor; -- To read context
GRANT SELECT, INSERT ON transaction_attempts TO symphony_executor;
GRANT SELECT, INSERT ON status_history TO symphony_executor;
GRANT SELECT, UPDATE ON event_outbox TO symphony_executor; -- To mark processed

-- 4. symphony_readonly (Read Plane)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO symphony_readonly;

-- 5. symphony_auditor (Regulator Access)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO symphony_auditor;

-- Ensure sequences are usable for IDs if any were using SERIAL (Symphony uses ULID/TEXT, but good practice)
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO symphony_control, symphony_ingest, symphony_executor;

-- Final Hardening: Ensure no role can UPDATE or DELETE from immutable tables
-- (Already revoked from PUBLIC in Phase 1, but we explicitly deny here too)
REVOKE UPDATE, DELETE ON audit_log FROM symphony_control, symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor;
REVOKE UPDATE, DELETE ON status_history FROM symphony_control, symphony_ingest, symphony_executor, symphony_readonly, symphony_auditor;

-- REVOKE DELETE ON instructions FROM symphony_ingest, symphony_executor; -- Instructions are immutable once written.

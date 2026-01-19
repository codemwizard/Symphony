# Database Schema

Source: schema/v1/*.sql and schema/views/*.sql

## schema/v1/000_ulid.sql

```sql
CREATE OR REPLACE FUNCTION generate_ulid()
RETURNS TEXT AS $$
DECLARE
  ts BIGINT;
  rand BYTEA;
BEGIN
  ts := FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000);
  rand := gen_random_bytes(10);
  RETURN encode(
    int8send(ts) || rand,
    'base64'
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION generate_ulid IS 'Generates a time-ordered, sortable 128-bit identifier. Note: This is time-ordered but not strictly canonical ULID spec compliant. Safe for Phase 1/2.';

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';
```

## schema/v1/001_core_entities.sql

```sql
CREATE TABLE clients (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  name TEXT NOT NULL,
  iso20022_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  aml_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE providers (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  name TEXT NOT NULL,
  provider_type TEXT NOT NULL, -- MMO, BANK, SANDBOX
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## schema/v1/002_orchestration.sql

```sql
CREATE TABLE routes (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  client_id TEXT NOT NULL REFERENCES clients(id),
  provider_id TEXT NOT NULL REFERENCES providers(id),
  currency CHAR(3) NOT NULL,
  priority_weight INTEGER NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (client_id, provider_id, currency),
  CONSTRAINT priority_positive_check CHECK (priority_weight >= 0)
);
```

## schema/v1/003_instructions.sql

```sql
CREATE TABLE instructions (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  client_id TEXT NOT NULL REFERENCES clients(id),
  client_request_id TEXT NOT NULL,
  amount NUMERIC(18,2) NOT NULL,
  currency CHAR(3) NOT NULL,
  receiver_reference TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (client_id, client_request_id),
  CONSTRAINT instructions_status_check CHECK (status IN ('RECEIVED', 'PROCESSING', 'COMPLETED', 'FAILED'))
);
```

## schema/v1/004_transaction_attempts.sql

```sql
CREATE TABLE transaction_attempts (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  instruction_id TEXT NOT NULL REFERENCES instructions(id),
  provider_id TEXT NOT NULL REFERENCES providers(id),
  attempt_number INTEGER NOT NULL,
  routing_logic_version TEXT NOT NULL,
  latency_ms INTEGER,
  provider_error_code TEXT,
  provider_metadata JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT attempts_status_check CHECK (status IN ('INITIATED', 'SUCCESS', 'FAILED', 'TIMEOUT'))
);
```

## schema/v1/005_status_history.sql

```sql
CREATE TABLE status_history (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  instruction_id TEXT NOT NULL REFERENCES instructions(id),
  old_status TEXT,
  new_status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX idx_status_history_time
ON status_history (created_at);

-- IMMUTABILITY ENFORCEMENT
REVOKE UPDATE, DELETE ON status_history FROM PUBLIC;
```

## schema/v1/006_provider_health.sql

```sql
CREATE TABLE provider_health_snapshots (
  provider_id TEXT PRIMARY KEY REFERENCES providers(id),
  success_rate_last_10m NUMERIC(5,2) NOT NULL,
  avg_latency_last_10m INTEGER NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_provider_health_updated_at
    BEFORE UPDATE ON provider_health_snapshots
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

## schema/v1/007_audit_log.sql

```sql
CREATE TABLE audit_log (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  actor TEXT NOT NULL,
  action TEXT NOT NULL,
  target_id TEXT,
  metadata JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- IMMUTABILITY ENFORCEMENT
REVOKE UPDATE, DELETE ON audit_log FROM PUBLIC;
```

## schema/v1/008_event_outbox.sql

```sql
CREATE TABLE event_outbox (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## schema/v1/009_policy_versions.sql

```sql
-- Policy Versions Table (Production-Safe Version Windows)
-- 
-- Supports ACTIVE, GRACE, and RETIRED states to prevent "Thunderous Logout"
-- when policy versions are updated.
--
-- ACTIVE:  Current policy, always accepted
-- GRACE:   Previous policy, temporarily accepted during migration window
-- RETIRED: No longer accepted, tokens must re-authenticate

CREATE TABLE IF NOT EXISTS policy_versions (
    id TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'GRACE', 'RETIRED')),
    activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Legacy column for backwards compatibility (derived from status)
    active BOOLEAN GENERATED ALWAYS AS (status = 'ACTIVE') STORED
);

-- Index for fast lookup of accepted versions
CREATE INDEX IF NOT EXISTS idx_policy_versions_status 
    ON policy_versions(status) 
    WHERE status IN ('ACTIVE', 'GRACE');

-- Ensure only one ACTIVE version at a time
CREATE UNIQUE INDEX IF NOT EXISTS idx_policy_versions_unique_active 
    ON policy_versions(status) 
    WHERE status = 'ACTIVE';

COMMENT ON TABLE policy_versions IS 
    'Anchor table for policy-bound invariants and regulatory governance. Supports version windows for graceful transitions.';

COMMENT ON COLUMN policy_versions.status IS 
    'ACTIVE = current policy | GRACE = temporarily accepted | RETIRED = rejected';

```

## schema/v1/010_roles.sql

```sql
-- Symphony Phase 2: Role Definitions
-- No privileges granted here, just the existence of the roles.

-- Control Plane: Admin & Configuration
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_control') THEN
    CREATE ROLE symphony_control;
  END IF;
END $$;

-- Data Plane Ingest: Front-line instruction entry
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_ingest') THEN
    CREATE ROLE symphony_ingest;
  END IF;
END $$;

-- Data Plane Executor: Backend workers processing attempts
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_executor') THEN
    CREATE ROLE symphony_executor;
  END IF;
END $$;

-- Read Plane: General reporting
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_readonly') THEN
    CREATE ROLE symphony_readonly;
  END IF;
END $$;

-- Read Plane: External auditors
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_auditor') THEN
    CREATE ROLE symphony_auditor;
  END IF;
END $$;

COMMENT ON ROLE symphony_control IS 'Control Plane administrator. Manages configuration and routing policy.';
COMMENT ON ROLE symphony_ingest IS 'Data Plane Ingest service. Responsible for recording new instructions.';
COMMENT ON ROLE symphony_executor IS 'Data Plane Executor worker. Responsible for processing transaction attempts and state transitions.';
COMMENT ON ROLE symphony_readonly IS 'Read Plane access for reporting and internal observability.';
COMMENT ON ROLE symphony_auditor IS 'Read Plane access for external regulators and independent audits.';
```

## schema/v1/010_seed_policy.sql

```sql
-- Seed initial policy version (ACTIVE status)
INSERT INTO policy_versions (id, description, status, activated_at)
VALUES ('v1.0.0', 'Initial Policy Version', 'ACTIVE', NOW())
ON CONFLICT (id) DO UPDATE SET status = 'ACTIVE', activated_at = NOW();

```

## schema/v1/011_payment_outbox.sql

```sql
-- Phase-7B Option 2A: Hot/Archive Outbox (Authoritative DB Invariants)
-- Replace-in-place. No legacy tables or compatibility paths.

BEGIN;

DROP VIEW IF EXISTS supervisor_outbox_status CASCADE;
DROP TABLE IF EXISTS payment_outbox CASCADE;
DROP TYPE IF EXISTS outbox_status CASCADE;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'outbox_attempt_state') THEN
    CREATE TYPE outbox_attempt_state AS ENUM (
      'DISPATCHING',
      'DISPATCHED',
      'RETRYABLE',
      'FAILED',
      'ZOMBIE_REQUEUE'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS participant_outbox_sequences (
  participant_id TEXT PRIMARY KEY,
  next_sequence_id BIGINT NOT NULL CHECK (next_sequence_id >= 1)
);

CREATE OR REPLACE FUNCTION bump_participant_outbox_seq(p_participant_id TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  allocated BIGINT;
BEGIN
  INSERT INTO participant_outbox_sequences(participant_id, next_sequence_id)
  VALUES (p_participant_id, 2)
  ON CONFLICT (participant_id)
  DO UPDATE
    SET next_sequence_id = participant_outbox_sequences.next_sequence_id + 1
  RETURNING (participant_outbox_sequences.next_sequence_id - 1) INTO allocated;

  RETURN allocated;
END;
$$;

CREATE TABLE IF NOT EXISTS payment_outbox_pending (
  outbox_id UUID PRIMARY KEY DEFAULT uuidv7(),
  instruction_id TEXT NOT NULL,
  participant_id TEXT NOT NULL,
  sequence_id BIGINT NOT NULL,
  idempotency_key TEXT NOT NULL,
  rail_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  attempt_count INT NOT NULL DEFAULT 0 CHECK (attempt_count >= 0 AND attempt_count <= 20),
  next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id),
  CONSTRAINT ux_pending_idempotency UNIQUE (instruction_id, idempotency_key),
  CONSTRAINT ck_pending_payload_is_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_pending_due
  ON payment_outbox_pending (next_attempt_at, created_at);

CREATE INDEX IF NOT EXISTS ix_pending_participant
  ON payment_outbox_pending (participant_id, next_attempt_at);

COMMENT ON COLUMN payment_outbox_pending.attempt_count IS
  'Non-authoritative cache of last_attempt_no; next attempt is derived from attempts history.';

CREATE TABLE IF NOT EXISTS payment_outbox_attempts (
  attempt_id UUID PRIMARY KEY DEFAULT uuidv7(),
  outbox_id UUID NOT NULL,
  instruction_id TEXT NOT NULL,
  participant_id TEXT NOT NULL,
  sequence_id BIGINT NOT NULL,
  idempotency_key TEXT NOT NULL,
  rail_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  attempt_no INT NOT NULL CHECK (attempt_no >= 1),
  state outbox_attempt_state NOT NULL,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  rail_reference TEXT,
  rail_code TEXT,
  error_code TEXT,
  error_message TEXT,
  latency_ms INT CHECK (latency_ms IS NULL OR latency_ms >= 0),
  worker_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ux_attempt_unique_per_outbox UNIQUE (outbox_id, attempt_no),
  CONSTRAINT ck_attempts_payload_is_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_attempts_outbox_latest
  ON payment_outbox_attempts (outbox_id, claimed_at DESC);

CREATE INDEX IF NOT EXISTS ix_attempts_dispatching_age
  ON payment_outbox_attempts (claimed_at)
  WHERE state = 'DISPATCHING';

CREATE INDEX IF NOT EXISTS ix_attempts_instruction
  ON payment_outbox_attempts (instruction_id, claimed_at DESC);

CREATE INDEX IF NOT EXISTS ix_attempts_idempotency
  ON payment_outbox_attempts (instruction_id, idempotency_key, claimed_at DESC);

CREATE OR REPLACE FUNCTION notify_outbox_pending()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM pg_notify('outbox_pending', 'new_work');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_outbox_pending ON payment_outbox_pending;

CREATE TRIGGER trg_notify_outbox_pending
AFTER INSERT ON payment_outbox_pending
FOR EACH ROW
EXECUTE FUNCTION notify_outbox_pending();

ALTER FUNCTION bump_participant_outbox_seq(TEXT) OWNER TO symphony_control;

CREATE OR REPLACE FUNCTION deny_outbox_attempts_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'payment_outbox_attempts is append-only'
    USING ERRCODE = 'P0001';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_outbox_attempts_mutation ON payment_outbox_attempts;

CREATE TRIGGER trg_deny_outbox_attempts_mutation
BEFORE UPDATE OR DELETE ON payment_outbox_attempts
FOR EACH ROW
EXECUTE FUNCTION deny_outbox_attempts_mutation();

CREATE OR REPLACE FUNCTION enqueue_payment_outbox(
  p_instruction_id TEXT,
  p_participant_id TEXT,
  p_idempotency_key TEXT,
  p_rail_type TEXT,
  p_payload JSONB
)
RETURNS TABLE (
  outbox_id UUID,
  sequence_id BIGINT,
  created_at TIMESTAMPTZ,
  state TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  existing_pending RECORD;
  existing_attempt RECORD;
  allocated_sequence BIGINT;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_instruction_id, 1),
    hashtextextended(p_idempotency_key, 2)
  );

  SELECT p.outbox_id, p.sequence_id, p.created_at
  INTO existing_pending
  FROM payment_outbox_pending p
  WHERE p.instruction_id = p_instruction_id
    AND p.idempotency_key = p_idempotency_key
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
    RETURN;
  END IF;

  SELECT a.outbox_id, a.sequence_id, a.created_at, a.state
  INTO existing_attempt
  FROM payment_outbox_attempts a
  WHERE a.instruction_id = p_instruction_id
    AND a.idempotency_key = p_idempotency_key
  ORDER BY a.claimed_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT existing_attempt.outbox_id, existing_attempt.sequence_id, existing_attempt.created_at, existing_attempt.state::TEXT;
    RETURN;
  END IF;

  allocated_sequence := bump_participant_outbox_seq(p_participant_id);

  BEGIN
    INSERT INTO payment_outbox_pending (
      instruction_id,
      participant_id,
      sequence_id,
      idempotency_key,
      rail_type,
      payload
    )
    VALUES (
      p_instruction_id,
      p_participant_id,
      allocated_sequence,
      p_idempotency_key,
      p_rail_type,
      p_payload
    )
    RETURNING payment_outbox_pending.outbox_id, payment_outbox_pending.sequence_id, payment_outbox_pending.created_at
    INTO existing_pending;
  EXCEPTION
    WHEN unique_violation THEN
      SELECT p.outbox_id, p.sequence_id, p.created_at
      INTO existing_pending
      FROM payment_outbox_pending p
      WHERE p.instruction_id = p_instruction_id
        AND p.idempotency_key = p_idempotency_key
      LIMIT 1;
      IF NOT FOUND THEN
        RAISE;
      END IF;
  END;

  RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
END;
$$;

CREATE OR REPLACE VIEW supervisor_outbox_status AS
WITH latest_attempts AS (
  SELECT DISTINCT ON (outbox_id)
    outbox_id,
    state,
    attempt_no,
    claimed_at,
    completed_at,
    created_at
  FROM payment_outbox_attempts
  ORDER BY outbox_id, claimed_at DESC
)
SELECT
  '7B.2.1' AS view_version,
  NOW() AS generated_at,
  (SELECT COUNT(*) FROM payment_outbox_pending) AS pending_count,
  (SELECT COUNT(*) FROM payment_outbox_pending WHERE next_attempt_at <= NOW()) AS due_pending_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHING') AS dispatching_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHED') AS dispatched_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED') AS failed_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'RETRYABLE') AS retryable_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED' AND attempt_no >= 5) AS dlq_count,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 1) AS attempt_1,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 2) AS attempt_2,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 3) AS attempt_3,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 4) AS attempt_4,
  (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no >= 5) AS attempt_5_plus,
  (
    SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::INTEGER
    FROM payment_outbox_pending
  ) AS oldest_pending_age_seconds,
  (
    SELECT COUNT(*)
    FROM latest_attempts
    WHERE state = 'DISPATCHING'
      AND claimed_at < NOW() - INTERVAL '120 seconds'
  ) AS stuck_dispatching_count,
  (
    SELECT COUNT(*)
    FROM payment_outbox_attempts
    WHERE state = 'DISPATCHED'
      AND completed_at >= NOW() - INTERVAL '1 hour'
  ) AS dispatched_last_hour,
  (
    SELECT COUNT(*)
    FROM payment_outbox_attempts
    WHERE state = 'FAILED'
      AND completed_at >= NOW() - INTERVAL '1 hour'
  ) AS failed_last_hour;

COMMIT;
```

## schema/v1/011_policy_profiles.sql

```sql
-- Symphony Phase 7.1: Policy Profiles for Sandbox Controls
-- Phase Key: SYS-7-1
-- System of Record: Platform Orchestration Layer (Node.js)
--
-- Policy profiles do not constrain system capability.
-- They apply configurable, externally adjustable limits to existing
-- execution capability without requiring code changes or redeployment.

CREATE TABLE policy_profiles (
    policy_profile_id TEXT PRIMARY KEY DEFAULT generate_ulid(),
    name TEXT NOT NULL UNIQUE,
    
    -- Sandbox exposure limits (configurational, not infrastructural)
    max_transaction_amount NUMERIC(18,2),
    max_transactions_per_second INTEGER,
    daily_aggregate_limit NUMERIC(18,2),
    
    -- Message type whitelist
    allowed_message_types TEXT[] NOT NULL DEFAULT '{}',
    
    -- Additional policy constraints (extensible)
    constraints JSONB NOT NULL DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,
    
    -- Constraints
    CONSTRAINT valid_constraints CHECK (jsonb_typeof(constraints) = 'object'),
    CONSTRAINT positive_limits CHECK (
        (max_transaction_amount IS NULL OR max_transaction_amount > 0) AND
        (max_transactions_per_second IS NULL OR max_transactions_per_second > 0) AND
        (daily_aggregate_limit IS NULL OR daily_aggregate_limit > 0)
    )
);

-- Index for active profile lookup
CREATE INDEX idx_policy_profiles_active ON policy_profiles(is_active) WHERE is_active = true;

-- Trigger for updated_at
CREATE TRIGGER update_policy_profiles_updated_at
    BEFORE UPDATE ON policy_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Documentation
COMMENT ON TABLE policy_profiles IS 'Sandbox policy configurations for participant limits. Orchestration Layer SoR. Phase 7.1.';
COMMENT ON COLUMN policy_profiles.max_transaction_amount IS 'Per-transaction limit. Used solely for sandbox exposure control, not financial correctness.';
COMMENT ON COLUMN policy_profiles.daily_aggregate_limit IS 'Daily aggregate cap. Used solely for sandbox exposure control, not financial correctness.';
COMMENT ON COLUMN policy_profiles.allowed_message_types IS 'Whitelist of ISO-20022 message types this profile may submit.';
```

## schema/v1/011_privileges.sql

```sql
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
```

## schema/v1/012_ingress_attestations.sql

```sql
-- Phase-7R: Ingress Attestation Table with Hash-Chaining (Tamper-Evident)
-- This table implements the "No Ingress → No Execution" principle with cryptographic proof.

-- Ingress Attestation Table (7-day rolling partitions)
CREATE TABLE IF NOT EXISTS ingress_attestations (
    -- PG18: Native UUIDv7 for time-ordered locality
    id UUID DEFAULT uuidv7(),
    
    -- Request Provenance
    request_id UUID NOT NULL,
    idempotency_key TEXT NOT NULL,
    caller_identity TEXT NOT NULL,
    signature TEXT NOT NULL,
    
    -- Hash-Chaining for Tamper-Evidence (Record_n includes Hash(Record_{n-1}))
    prev_hash TEXT NOT NULL DEFAULT '',
    record_hash TEXT GENERATED ALWAYS AS (
        encode(sha256(
            (id::TEXT || request_id::TEXT || idempotency_key || caller_identity || prev_hash)::BYTEA
        ), 'hex')
    ) STORED,
    
    -- Timing
    attested_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Execution tracking
    execution_started BOOLEAN DEFAULT FALSE,
    execution_completed BOOLEAN DEFAULT FALSE,
    terminal_status TEXT,
    
    -- Export Metadata (Phase-7R: Export-Ready, Phase-7B+: Export-Enabled)
    -- Makes future out-of-domain persistence pluggable without schema changes
    exported_at TIMESTAMPTZ,
    export_batch_id UUID,

    -- PK must include partition key
    PRIMARY KEY (id, attested_at)
) PARTITION BY RANGE (attested_at);

-- Index for gap detection (unexecuted attestations)
CREATE INDEX IF NOT EXISTS idx_attestation_gaps ON ingress_attestations (attested_at)
WHERE execution_completed = FALSE;

-- Index for hash-chain verification
CREATE INDEX IF NOT EXISTS idx_attestation_hash ON ingress_attestations (record_hash);

-- 7-day rolling partitions for January 2026
CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w1 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-01') TO ('2026-01-08');

CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w2 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-08') TO ('2026-01-15');

CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w3 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-15') TO ('2026-01-22');

CREATE TABLE IF NOT EXISTS ingress_attestations_2026_01_w4 PARTITION OF ingress_attestations
    FOR VALUES FROM ('2026-01-22') TO ('2026-02-01');

COMMENT ON TABLE ingress_attestations IS 'Phase-7R Ingress Attestation Log. Tamper-evident via hash-chaining. 7-day rolling partitions.';
COMMENT ON COLUMN ingress_attestations.prev_hash IS 'Hash of the previous record for chain integrity.';
COMMENT ON COLUMN ingress_attestations.record_hash IS 'Computed hash of this record for verification.';
```

## schema/v1/012_participants.sql

```sql
-- Symphony Phase 7.1: Regulated Participant Identity
-- Phase Key: SYS-7-1
-- System of Record: Platform Orchestration Layer (Node.js)
-- Reference: TDD Section 7.1.2
--
-- Each sandbox participant is treated as a regulated actor, not a SaaS tenant.
-- This aligns with NPS Act supervisory framing and sandbox expectations.
--
-- Regulatory Guarantee:
-- Participant authorization is revocable at runtime without redeployment.
-- Suspended or revoked participants are fail-closed at ingress.

-- Participant role enumeration
-- SUPERVISOR is non-executing: read-only, evidence-access only
CREATE TYPE participant_role AS ENUM ('BANK', 'PSP', 'OPERATOR', 'SUPERVISOR');

-- Participant status for runtime revocation
CREATE TYPE participant_status AS ENUM ('ACTIVE', 'SUSPENDED', 'REVOKED');

CREATE TABLE participants (
    -- Identity
    participant_id TEXT PRIMARY KEY DEFAULT generate_ulid(),
    legal_entity_ref TEXT NOT NULL UNIQUE,
    mtls_cert_fingerprint TEXT NOT NULL UNIQUE,
    
    -- Role and authorization
    role participant_role NOT NULL,
    policy_profile_id TEXT NOT NULL REFERENCES policy_profiles(policy_profile_id),
    
    -- Scope constraints
    -- ledger_scope defines what accounts/wallets this participant may REQUEST operations on
    -- Actual enforcement is authoritative in .NET Financial Core
    ledger_scope JSONB NOT NULL DEFAULT '{}',
    
    -- Sandbox limits override (inherits from policy_profile if not set)
    sandbox_limits JSONB NOT NULL DEFAULT '{}',
    
    -- Status and revocation (runtime-controllable)
    status participant_status NOT NULL DEFAULT 'ACTIVE',
    status_changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status_reason TEXT,
    
    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,
    
    -- Constraints
    CONSTRAINT valid_ledger_scope CHECK (jsonb_typeof(ledger_scope) = 'object'),
    CONSTRAINT valid_sandbox_limits CHECK (jsonb_typeof(sandbox_limits) = 'object')
);

-- Indexes for lookup patterns
CREATE INDEX idx_participants_fingerprint ON participants(mtls_cert_fingerprint);
CREATE INDEX idx_participants_status ON participants(status) WHERE status = 'ACTIVE';
CREATE INDEX idx_participants_role ON participants(role);
CREATE INDEX idx_participants_legal_entity ON participants(legal_entity_ref);

-- Trigger for updated_at
CREATE TRIGGER update_participants_updated_at
    BEFORE UPDATE ON participants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for status_changed_at
CREATE OR REPLACE FUNCTION update_status_changed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        NEW.status_changed_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_participants_status_changed_at
    BEFORE UPDATE ON participants
    FOR EACH ROW
    EXECUTE FUNCTION update_status_changed_at();

-- Documentation
COMMENT ON TABLE participants IS 'Regulated participant identities. Each participant is a regulated actor, not a SaaS tenant. Orchestration Layer SoR. Phase 7.1.';
COMMENT ON COLUMN participants.legal_entity_ref IS 'External legal identity reference (e.g., BoZ registration number, bank license).';
COMMENT ON COLUMN participants.mtls_cert_fingerprint IS 'SHA-256 fingerprint of bound mTLS certificate. 1:1 mapping enforced.';
COMMENT ON COLUMN participants.role IS 'Participant classification. SUPERVISOR is non-executing observer with read-only evidence access.';
COMMENT ON COLUMN participants.ledger_scope IS 'Accounts/wallets this participant may REQUEST operations on. Defense-in-depth only; .NET enforces authoritatively.';
COMMENT ON COLUMN participants.status IS 'Runtime-controllable authorization status. Non-ACTIVE participants are fail-closed at ingress.';
COMMENT ON COLUMN participants.status_reason IS 'Audit trail for status changes (e.g., "Suspended by BoZ directive 2026-01-15").';
```

## schema/v1/014_execution_attempts.sql

```sql
-- Symphony Phase 7.2: Execution Attempts
-- Phase Key: SYS-7-2
-- System of Record: Platform Orchestration Layer (Node.js)
--
-- Attempt tracking is diagnostic and non-authoritative.
-- No execution decision may be derived solely from attempt state.
--
-- Attempts are append-only: state transitions are forward-only,
-- and resolved_at is set exactly once.

CREATE TABLE execution_attempts (
    -- Identity
    attempt_id TEXT PRIMARY KEY DEFAULT generate_ulid(),
    instruction_id TEXT NOT NULL,
    sequence_number INTEGER NOT NULL,
    
    -- State (forward-only transitions)
    state TEXT NOT NULL DEFAULT 'CREATED'
        CHECK (state IN ('CREATED', 'SENT', 'ACKED', 'NACKED', 'TIMEOUT')),
    
    -- External response (if received)
    rail_response JSONB,
    
    -- Failure classification (if failed)
    failure_class TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    
    -- Correlation (INV SYS-7-1-A)
    ingress_sequence_id TEXT NOT NULL,
    request_id TEXT NOT NULL,
    
    -- Constraints
    CONSTRAINT unique_attempt_sequence UNIQUE (instruction_id, sequence_number),
    CONSTRAINT valid_rail_response CHECK (
        rail_response IS NULL OR jsonb_typeof(rail_response) = 'object'
    )
);

-- Indexes
CREATE INDEX idx_attempts_instruction ON execution_attempts(instruction_id);
CREATE INDEX idx_attempts_state ON execution_attempts(state) WHERE state = 'SENT';
CREATE INDEX idx_attempts_request ON execution_attempts(request_id);

-- Documentation
COMMENT ON TABLE execution_attempts IS 'Diagnostic attempt tracking. Non-authoritative. Append-only semantics. Phase 7.2.';
COMMENT ON COLUMN execution_attempts.state IS 'Attempt state. Forward-only transitions. Does not determine instruction success.';
COMMENT ON COLUMN execution_attempts.rail_response IS 'External rail response. For diagnostics only.';
COMMENT ON COLUMN execution_attempts.failure_class IS 'Classified failure type per Phase 7.2 taxonomy.';
```

## schema/v1/015_instructions.sql

```sql
-- Instruction State Enum
-- AUTHORIZED indicates that the instruction has passed all pre-execution
-- policy, balance, and eligibility checks. It does not imply external rail acceptance.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'instruction_state') THEN
        CREATE TYPE instruction_state AS ENUM (
            'RECEIVED',
            'AUTHORIZED',
            'EXECUTING',
            'COMPLETED',
            'FAILED'
        );
    END IF;
END $$;

-- Handle legacy instructions table (Phase 1/2) by renaming it if it exists and has the old schema
DO $$
BEGIN
    -- Check if 'instructions' exists and has 'client_id' (hallmark of v1 schema)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'instructions' AND column_name = 'client_id'
    ) THEN
        ALTER TABLE instructions RENAME TO instructions_legacy;
    END IF;
END $$;

-- Instructions Table (Authoritative State)
CREATE TABLE IF NOT EXISTS instructions (
    instruction_id         TEXT PRIMARY KEY,
    idempotency_key        TEXT NOT NULL UNIQUE,

    participant_id         TEXT NOT NULL,
    instruction_type       TEXT NOT NULL,

    amount                 NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    currency               CHAR(3) NOT NULL,

    debit_account_id       TEXT NOT NULL,
    credit_account_id      TEXT NOT NULL,

    state                  instruction_state NOT NULL,
    is_terminal            BOOLEAN NOT NULL DEFAULT FALSE,

    rail_reference         TEXT,
    failure_reason         TEXT,

    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    version                INTEGER NOT NULL DEFAULT 0,

    CHECK (
        (state IN ('COMPLETED', 'FAILED') AND is_terminal = TRUE)
        OR
        (state NOT IN ('COMPLETED', 'FAILED') AND is_terminal = FALSE)
    )
);

-- Enforce single terminal success (INV-FIN-02)
CREATE UNIQUE INDEX IF NOT EXISTS ux_instruction_single_success
ON instructions (instruction_id)
WHERE state = 'COMPLETED';

-- Fast terminal checks
CREATE INDEX IF NOT EXISTS ix_instruction_terminal
ON instructions (instruction_id, is_terminal);

-- Trigger for updated_at
CREATE OR REPLACE TRIGGER update_instructions_updated_at
    BEFORE UPDATE ON instructions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE instructions IS 'Authoritative instruction state. Single row per intent. Phase 7.3.';
```

## schema/v1/016_ledger_entries.sql

```sql
-- Ledger Entries Table (Append-Only, Financial Truth)
CREATE TABLE ledger_entries (
    ledger_entry_id        TEXT PRIMARY KEY,
    instruction_id         TEXT NOT NULL,

    account_id             TEXT NOT NULL,
    direction              CHAR(1) NOT NULL CHECK (direction IN ('D','C')),

    amount                 NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    currency               CHAR(3) NOT NULL,

    posting_key            TEXT NOT NULL,
    posting_sequence       INTEGER NOT NULL,

    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_instruction
        FOREIGN KEY (instruction_id)
        REFERENCES instructions (instruction_id),

    CONSTRAINT ux_posting_idempotency
        UNIQUE (instruction_id, posting_key)
);

-- Enforce deterministic posting order per instruction
CREATE UNIQUE INDEX ux_instruction_posting_sequence
ON ledger_entries (instruction_id, posting_sequence);

-- Fast account lookups
CREATE INDEX ix_ledger_account
ON ledger_entries (account_id, created_at);

COMMENT ON TABLE ledger_entries IS 'Append-only ledger. No UPDATE, no DELETE, ever. Phase 7.3.';
```

## schema/v1/017_account_balances_view.sql

```sql
-- Balance View (Derived, Non-Authoritative)
-- If this view is wrong, the ledger is wrong — not the view.
-- Balance checks are performed as read-only queries over this view
-- and do not introduce additional state.
CREATE VIEW account_balances AS
SELECT
    account_id,
    currency,
    SUM(
        CASE direction
            WHEN 'C' THEN amount
            WHEN 'D' THEN -amount
        END
    ) AS balance
FROM ledger_entries
GROUP BY account_id, currency;

COMMENT ON VIEW account_balances IS 'Derived balance. Non-authoritative. Computed from ledger. Phase 7.3.';
```

## schema/v1/018_kill_switches.sql

```sql
-- Phase-7R: Kill Switch Schema
-- Provides global execution blocking capability for regulatory compliance.
-- 
-- When a kill_switch is active with scope = 'GLOBAL', 'INGEST', or 'EXECUTION',
-- all matching operations are blocked until the switch is deactivated.

CREATE TABLE IF NOT EXISTS kill_switches (
    id TEXT PRIMARY KEY,
    scope TEXT NOT NULL CHECK (scope IN ('GLOBAL', 'INGEST', 'EXECUTION', 'DISPATCH', 'PARTICIPANT')),
    reason TEXT NOT NULL,
    activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activated_by TEXT NOT NULL,
    policy_version TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deactivated_at TIMESTAMPTZ,
    deactivated_by TEXT
);

-- Index for checking active kill switches
CREATE INDEX IF NOT EXISTS idx_kill_switches_active 
    ON kill_switches(is_active) 
    WHERE is_active = TRUE;

-- Index for scope-based lookups
CREATE INDEX IF NOT EXISTS idx_kill_switches_scope 
    ON kill_switches(scope, is_active);

COMMENT ON TABLE kill_switches IS 
    'Phase-7R: Kill switch registry for emergency execution blocking.';

-- Trigger function to block execution (applied separately based on table dependencies)
CREATE OR REPLACE FUNCTION block_execution_if_killed()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM kill_switches
        WHERE is_active = TRUE
          AND scope IN ('GLOBAL', 'INGEST', 'EXECUTION')
    ) THEN
        RAISE EXCEPTION 'Execution blocked by active kill-switch' 
            USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## schema/v1/020_clearing_anchors.sql

```sql
/**
 * PHASE 7 DNA: 020_clearing_anchors.sql
 * Establishes the authoritative system anchors for double-entry integrity.
 */

-- Ensure we are in a transaction
BEGIN;

DO $$
BEGIN
    RAISE NOTICE 'Running fixed version of 020_clearing_anchors.sql with Account table creation';
END $$;

-- INV-FIN-01: Every ledger must have an offset account
-- These accounts are the "Mathematical Anchors" for the Zero-Sum Law.

-- Ensure "Account" table exists (Missing Dependency Fix)
CREATE TABLE IF NOT EXISTS "Account" (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    currency CHAR(3) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed the Clearing Roles if they don't exist
INSERT INTO "Account" (id, type, currency, metadata)
VALUES 
    ('SYS_PROGRAM_CLEARING_USD', 'SYSTEM_ANCHOR', 'USD', '{"description": "Master Clearing Anchor for USD postings"}'),
    ('SYS_VENDOR_SETTLEMENT_USD', 'SYSTEM_ANCHOR', 'USD', '{"description": "Authoritative Vendor Settlement Anchor"}')
ON CONFLICT (id) DO NOTHING;

-- Verification Invariant: These accounts NEVER carry a 'balance' column.
-- They are only ever derived from the 'LedgerPost' table.

COMMIT;
```

## schema/views/attestation_gap_view.sql

```sql
-- Phase-7B: Attestation Gap View
-- Exposes a read-only metric indicating ingress-to-execution completeness.
-- 
-- Metric: Attested but not executed within threshold
-- Time Windows: Last hour, Last 24 hours
--
-- NOTE: Thresholds are observational only and do not affect execution.

-- View Version: 7B.1.0
-- Generated At: Runtime (via view_version and generated_at columns)

CREATE OR REPLACE VIEW supervisor_attestation_gap AS
SELECT
    '7B.1.0' AS view_version,
    NOW() AS generated_at,
    
    -- Last Hour Metrics
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
    ) AS total_attested_1h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
          AND execution_completed = TRUE
    ) AS total_executed_1h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
          AND execution_started = FALSE
    ) AS gap_not_started_1h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '1 hour'
          AND execution_started = TRUE
          AND execution_completed = FALSE
    ) AS gap_in_progress_1h,
    
    -- Last 24 Hours Metrics
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
    ) AS total_attested_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND execution_completed = TRUE
    ) AS total_executed_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND execution_started = FALSE
    ) AS gap_not_started_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND execution_started = TRUE
          AND execution_completed = FALSE
    ) AS gap_in_progress_24h,
    
    -- Terminal Status Breakdown (24h)
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND terminal_status = 'SUCCESS'
    ) AS success_count_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND terminal_status = 'FAILED'
    ) AS failed_count_24h,
    
    (
        SELECT COUNT(*)
        FROM ingress_attestations
        WHERE created_at >= NOW() - INTERVAL '24 hours'
          AND terminal_status = 'REPAIRED'
    ) AS repaired_count_24h;

COMMENT ON VIEW supervisor_attestation_gap IS 
    'Phase-7B: Read-only supervisor view for attestation-to-execution completeness. Thresholds are observational only.';
```

## schema/views/outbox_status_view.sql

```sql
-- Phase-7B: Outbox Status View (Option 2A)
-- Exposes the state of the hot pending queue and append-only attempts log.

CREATE OR REPLACE VIEW supervisor_outbox_status AS
WITH latest_attempts AS (
    SELECT DISTINCT ON (outbox_id)
        outbox_id,
        state,
        attempt_no,
        claimed_at,
        completed_at,
        created_at
    FROM payment_outbox_attempts
    ORDER BY outbox_id, claimed_at DESC
)
SELECT
    '7B.2.1' AS view_version,
    NOW() AS generated_at,

    -- Pending counts
    (SELECT COUNT(*) FROM payment_outbox_pending) AS pending_count,
    (SELECT COUNT(*) FROM payment_outbox_pending WHERE next_attempt_at <= NOW()) AS due_pending_count,

    -- Latest attempt state counts
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHING') AS dispatching_count,
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'DISPATCHED') AS dispatched_count,
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED') AS failed_count,
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'RETRYABLE') AS retryable_count,

    -- DLQ heuristic (attempt_no >= 5 and terminal)
    (SELECT COUNT(*) FROM latest_attempts WHERE state = 'FAILED' AND attempt_no >= 5) AS dlq_count,

    -- Attempt distribution (latest attempt_no)
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 1) AS attempt_1,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 2) AS attempt_2,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 3) AS attempt_3,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no = 4) AS attempt_4,
    (SELECT COUNT(*) FROM latest_attempts WHERE attempt_no >= 5) AS attempt_5_plus,

    -- Aging analysis
    (
        SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::INTEGER
        FROM payment_outbox_pending
    ) AS oldest_pending_age_seconds,

    -- Stuck dispatching count
    (
        SELECT COUNT(*)
        FROM latest_attempts
        WHERE state = 'DISPATCHING'
          AND claimed_at < NOW() - INTERVAL '120 seconds'
    ) AS stuck_dispatching_count,

    -- Throughput (last hour)
    (
        SELECT COUNT(*)
        FROM payment_outbox_attempts
        WHERE state = 'DISPATCHED'
          AND completed_at >= NOW() - INTERVAL '1 hour'
    ) AS dispatched_last_hour,

    (
        SELECT COUNT(*)
        FROM payment_outbox_attempts
        WHERE state = 'FAILED'
          AND completed_at >= NOW() - INTERVAL '1 hour'
    ) AS failed_last_hour;

COMMENT ON VIEW supervisor_outbox_status IS
    'Phase-7B Option 2A: Supervisor view for pending depth, attempt states, aging, and dispatch throughput.';
```

## schema/views/revocation_status_view.sql

```sql
-- Phase-7B: Revocation Window Visibility View
-- Exposes certificate TTL and revocation posture.
--
-- Scope:
-- - Maximum certificate age
-- - Active vs revoked counts
-- - Revocation propagation window
--
-- Acceptance Criteria:
-- - Supervisor can verify kill-switch effectiveness
-- - No key material exposed

CREATE OR REPLACE VIEW supervisor_revocation_status AS
SELECT
    '7B.1.0' AS view_version,
    NOW() AS generated_at,
    
    -- Certificate Counts
    (SELECT COUNT(*) FROM participant_certificates WHERE revoked = FALSE AND expires_at > NOW()) AS active_count,
    (SELECT COUNT(*) FROM participant_certificates WHERE revoked = TRUE) AS revoked_count,
    (SELECT COUNT(*) FROM participant_certificates WHERE expires_at <= NOW()) AS expired_count,
    
    -- TTL Analysis
    (
        SELECT EXTRACT(EPOCH FROM MAX(expires_at - issued_at)) / 3600
        FROM participant_certificates
        WHERE revoked = FALSE AND expires_at > NOW()
    )::NUMERIC(10,2) AS max_ttl_hours,
    
    (
        SELECT EXTRACT(EPOCH FROM AVG(expires_at - issued_at)) / 3600
        FROM participant_certificates
        WHERE revoked = FALSE AND expires_at > NOW()
    )::NUMERIC(10,2) AS avg_ttl_hours,
    
    -- Kill-Switch Metrics
    (
        SELECT COUNT(*)
        FROM participant_certificates
        WHERE revoked = TRUE
          AND revoked_at >= NOW() - INTERVAL '24 hours'
    ) AS revoked_last_24h,
    
    -- Renewal Window
    (
        SELECT COUNT(*)
        FROM participant_certificates
        WHERE revoked = FALSE
          AND expires_at > NOW()
          AND expires_at <= NOW() + INTERVAL '30 minutes'
    ) AS expiring_within_30m,
    
    -- Worst-Case Revocation Window
    -- Calculated as: max_ttl_hours * 3600 + policy_propagation_seconds (60)
    (
        SELECT COALESCE(
            (EXTRACT(EPOCH FROM MAX(expires_at - issued_at)) + 60)::INTEGER,
            14460  -- Default: 4h + 60s
        )
        FROM participant_certificates
        WHERE revoked = FALSE AND expires_at > NOW()
    ) AS worst_case_revocation_seconds,
    
    -- Certificate Health by Participant (Top 10 by Active Certs)
    (
        SELECT json_agg(participant_stats)
        FROM (
            SELECT 
                participant_id,
                COUNT(*) FILTER (WHERE revoked = FALSE AND expires_at > NOW()) AS active,
                COUNT(*) FILTER (WHERE revoked = TRUE) AS revoked
            FROM participant_certificates
            GROUP BY participant_id
            ORDER BY active DESC
            LIMIT 10
        ) participant_stats
    ) AS top_participants_by_certs;

COMMENT ON VIEW supervisor_revocation_status IS 
    'Phase-7B: Read-only supervisor view for certificate TTL, revocation posture, and kill-switch effectiveness. No key material exposed.';
```
ALTER FUNCTION enqueue_payment_outbox(TEXT, TEXT, TEXT, TEXT, JSONB) OWNER TO symphony_control;

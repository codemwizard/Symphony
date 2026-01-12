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

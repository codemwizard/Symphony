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

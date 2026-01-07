/**
 * PHASE 7 DNA: 020_clearing_anchors.sql
 * Establishes the authoritative system anchors for double-entry integrity.
 */

-- Ensure we are in a transaction
BEGIN;

-- INV-FIN-01: Every ledger must have an offset account
-- These accounts are the "Mathematical Anchors" for the Zero-Sum Law.

-- Seed the Clearing Roles if they don't exist
INSERT INTO "Account" (id, type, currency, metadata)
VALUES 
    ('SYS_PROGRAM_CLEARING_USD', 'SYSTEM_ANCHOR', 'USD', '{"description": "Master Clearing Anchor for USD postings"}'),
    ('SYS_VENDOR_SETTLEMENT_USD', 'SYSTEM_ANCHOR', 'USD', '{"description": "Authoritative Vendor Settlement Anchor"}')
ON CONFLICT (id) DO NOTHING;

-- Verification Invariant: These accounts NEVER carry a 'balance' column.
-- They are only ever derived from the 'LedgerPost' table.

COMMIT;

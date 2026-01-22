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

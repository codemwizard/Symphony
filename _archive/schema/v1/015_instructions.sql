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

-- Instruction State Enum
-- AUTHORIZED indicates that the instruction has passed all pre-execution
-- policy, balance, and eligibility checks. It does not imply external rail acceptance.
CREATE TYPE instruction_state AS ENUM (
    'RECEIVED',
    'AUTHORIZED',
    'EXECUTING',
    'COMPLETED',
    'FAILED'
);

-- Instructions Table (Authoritative State)
CREATE TABLE instructions (
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
CREATE UNIQUE INDEX ux_instruction_single_success
ON instructions (instruction_id)
WHERE state = 'COMPLETED';

-- Fast terminal checks
CREATE INDEX ix_instruction_terminal
ON instructions (instruction_id, is_terminal);

COMMENT ON TABLE instructions IS 'Authoritative instruction state. Single row per intent. Phase 7.3.';

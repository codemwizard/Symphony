-- Migration 0118: Create execution_records table and add interpretation_version_id FK
-- Task: TSK-P2-PREAUTH-003-01 (table creation)
-- Task: TSK-P2-PREAUTH-003-02 (FK addition)
-- This table anchors execution truth with timestamps and project references

CREATE TABLE IF NOT EXISTS execution_records (
    execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL,
    execution_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR NOT NULL DEFAULT 'pending',
    interpretation_version_id UUID REFERENCES interpretation_packs(interpretation_pack_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index on project_id for efficient querying of project execution history
CREATE INDEX idx_execution_records_project_id ON execution_records(project_id);

-- Index on execution_timestamp for time-based queries
CREATE INDEX idx_execution_records_timestamp ON execution_records(execution_timestamp);

-- Index on interpretation_version_id for FK lookups
CREATE INDEX idx_execution_records_interpretation_version_id ON execution_records(interpretation_version_id);

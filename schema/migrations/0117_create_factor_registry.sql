-- Migration 0117: Create factor_registry and unit_conversions tables
-- Task: TSK-P2-PREAUTH-002-01, TSK-P2-PREAUTH-002-02

-- Task: TSK-P2-PREAUTH-002-01
-- Table: factor_registry

CREATE TABLE factor_registry (
    factor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    factor_code VARCHAR NOT NULL,
    factor_name VARCHAR NOT NULL,
    unit VARCHAR NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_factor_code UNIQUE (factor_code)
);

-- Index for factor code lookup
CREATE INDEX idx_factor_registry_code ON factor_registry (factor_code);

-- Index for unit lookup
CREATE INDEX idx_factor_registry_unit ON factor_registry (unit);

-- Comment explaining the table
COMMENT ON TABLE factor_registry IS 'Tracks emission factors with unique factor codes';
COMMENT ON CONSTRAINT unique_factor_code ON factor_registry IS 'Ensures factor codes are not duplicated';

-- Task: TSK-P2-PREAUTH-002-02
-- Table: unit_conversions

CREATE TABLE unit_conversions (
    conversion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_unit VARCHAR NOT NULL,
    to_unit VARCHAR NOT NULL,
    conversion_factor NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_unit_pair UNIQUE (from_unit, to_unit)
);

-- Index for unit pair lookup
CREATE INDEX idx_unit_conversions_pair ON unit_conversions (from_unit, to_unit);

-- Index for from_unit lookup
CREATE INDEX idx_unit_conversions_from ON unit_conversions (from_unit);

-- Index for to_unit lookup
CREATE INDEX idx_unit_conversions_to ON unit_conversions (to_unit);

-- Comment explaining the table
COMMENT ON TABLE unit_conversions IS 'Tracks unit conversion factors with unique (from_unit, to_unit) pairs';
COMMENT ON CONSTRAINT unique_unit_pair ON unit_conversions IS 'Ensures conversion factors are not duplicated for the same unit pair';

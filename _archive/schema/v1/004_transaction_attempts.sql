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

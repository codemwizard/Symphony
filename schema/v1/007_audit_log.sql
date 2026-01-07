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

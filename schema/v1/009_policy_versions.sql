CREATE TABLE policy_versions (
  id TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE policy_versions IS 'Anchor table for policy-bound invariants and regulatory governance.';

CREATE TABLE routes (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  client_id TEXT NOT NULL REFERENCES clients(id),
  provider_id TEXT NOT NULL REFERENCES providers(id),
  currency CHAR(3) NOT NULL,
  priority_weight INTEGER NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (client_id, provider_id, currency),
  CONSTRAINT priority_positive_check CHECK (priority_weight >= 0)
);

CREATE TABLE event_outbox (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

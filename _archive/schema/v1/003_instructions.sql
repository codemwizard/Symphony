CREATE TABLE instructions (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  client_id TEXT NOT NULL REFERENCES clients(id),
  client_request_id TEXT NOT NULL,
  amount NUMERIC(18,2) NOT NULL,
  currency CHAR(3) NOT NULL,
  receiver_reference TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (client_id, client_request_id),
  CONSTRAINT instructions_status_check CHECK (status IN ('RECEIVED', 'PROCESSING', 'COMPLETED', 'FAILED'))
);

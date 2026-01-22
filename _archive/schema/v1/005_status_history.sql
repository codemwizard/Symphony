CREATE TABLE status_history (
  id TEXT PRIMARY KEY DEFAULT generate_ulid(),
  instruction_id TEXT NOT NULL REFERENCES instructions(id),
  old_status TEXT,
  new_status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
 
CREATE INDEX idx_status_history_time
ON status_history (created_at);

-- IMMUTABILITY ENFORCEMENT
REVOKE UPDATE, DELETE ON status_history FROM PUBLIC;

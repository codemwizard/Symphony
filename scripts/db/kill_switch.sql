CREATE TABLE kill_switches (
  id TEXT PRIMARY KEY,
  scope TEXT NOT NULL,
  reason TEXT NOT NULL,
  activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  activated_by TEXT NOT NULL,
  policy_version TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true
);

-- Enforcement Trigger
CREATE OR REPLACE FUNCTION block_execution_if_killed()
RETURNS trigger AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM kill_switches
    WHERE is_active = true
      AND scope IN ('GLOBAL', 'INGEST', 'EXECUTION')
  ) THEN
    RAISE EXCEPTION 'Execution blocked by kill-switch';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER kill_switch_block
BEFORE INSERT ON instructions
FOR EACH ROW
EXECUTE FUNCTION block_execution_if_killed();

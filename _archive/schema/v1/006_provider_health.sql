CREATE TABLE provider_health_snapshots (
  provider_id TEXT PRIMARY KEY REFERENCES providers(id),
  success_rate_last_10m NUMERIC(5,2) NOT NULL,
  avg_latency_last_10m INTEGER NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_provider_health_updated_at
    BEFORE UPDATE ON provider_health_snapshots
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

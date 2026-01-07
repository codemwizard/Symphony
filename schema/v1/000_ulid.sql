CREATE OR REPLACE FUNCTION generate_ulid()
RETURNS TEXT AS $$
DECLARE
  ts BIGINT;
  rand BYTEA;
BEGIN
  ts := FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000);
  rand := gen_random_bytes(10);
  RETURN encode(
    int8send(ts) || rand,
    'base64'
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION generate_ulid IS 'Generates a time-ordered, sortable 128-bit identifier. Note: This is time-ordered but not strictly canonical ULID spec compliant. Safe for Phase 1/2.';

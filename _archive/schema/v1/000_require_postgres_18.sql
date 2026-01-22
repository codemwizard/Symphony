-- Require PostgreSQL 18+ and built-in uuidv7() before applying schema.
DO $$
BEGIN
  IF current_setting('server_version_num')::int < 180000 THEN
    RAISE EXCEPTION 'Symphony requires PostgreSQL 18+ (server_version_num=%)',
      current_setting('server_version_num');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'uuidv7'
      AND n.nspname IN ('pg_catalog', 'public')
  ) THEN
    RAISE EXCEPTION 'uuidv7() not available; ensure PostgreSQL 18+';
  END IF;
END $$;

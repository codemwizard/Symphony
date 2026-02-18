-- ============================================================
-- 0005_policy_versions.sql
-- Boot-critical policy version ledger (future-proof for grace)
-- ============================================================

-- Status enum supports future rotation with grace:
-- ACTIVE -> GRACE -> RETIRED
DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'policy_version_status') THEN
      CREATE TYPE policy_version_status AS ENUM ('ACTIVE', 'GRACE', 'RETIRED');
    END IF;
  END $$;

CREATE TABLE IF NOT EXISTS public.policy_versions (
  version TEXT PRIMARY KEY,

  status policy_version_status NOT NULL DEFAULT 'ACTIVE',
  activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  grace_expires_at TIMESTAMPTZ,

  -- Integrity binding to policy content (REQUIRED, no lying policy rows)
  checksum TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Compatibility with current runtime check:
  -- SELECT version FROM policy_versions WHERE is_active = true
  is_active BOOLEAN GENERATED ALWAYS AS (status = 'ACTIVE') STORED,

  CONSTRAINT ck_policy_checksum_nonempty CHECK (length(checksum) > 0),

  CONSTRAINT ck_policy_grace_requires_expiry
    CHECK (status <> 'GRACE' OR grace_expires_at IS NOT NULL),
  CONSTRAINT ck_policy_active_has_no_grace_expiry
    CHECK (status <> 'ACTIVE' OR grace_expires_at IS NULL)
);

COMMENT ON TABLE public.policy_versions IS
  'Boot-critical policy version ledger. Current runtime expects is_active=true row; future supports rotation with GRACE.';

-- Enforce exactly one ACTIVE policy row (per DB).
-- Unique-on-constant with predicate is the simplest, reliable pattern.
CREATE UNIQUE INDEX IF NOT EXISTS ux_policy_versions_single_active
  ON public.policy_versions ((1))
  WHERE status = 'ACTIVE';

-- Helpful lookup for boot checks
CREATE INDEX IF NOT EXISTS idx_policy_versions_is_active
  ON public.policy_versions (is_active)
  WHERE is_active = true;

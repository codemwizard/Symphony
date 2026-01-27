#!/usr/bin/env bash
# ============================================================
# seed_policy_from_env.sh — Seed initial ACTIVE policy row
# ============================================================
# NOT a migration. Run as an admin step (dev/CI/docker init).
#
# Required env:
#   DATABASE_URL
#   POLICY_VERSION
# Optional:
#   POLICY_CHECKSUM
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${POLICY_VERSION:?POLICY_VERSION is required}"

POLICY_CHECKSUM="${POLICY_CHECKSUM:-}"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<SQL
DO \$\$
DECLARE
  existing_active TEXT;
BEGIN
  SELECT version INTO existing_active
  FROM public.policy_versions
  WHERE is_active = true
  LIMIT 1;

  IF existing_active IS NOT NULL AND existing_active <> '${POLICY_VERSION}' THEN
    RAISE EXCEPTION 'Active policy already set to %, refusing to seed %', existing_active, '${POLICY_VERSION}';
  END IF;

  IF existing_active = '${POLICY_VERSION}' THEN
    -- idempotent
    RETURN;
  END IF;

  INSERT INTO public.policy_versions(version, status, checksum)
  VALUES ('${POLICY_VERSION}', 'ACTIVE', NULLIF('${POLICY_CHECKSUM}', ''));
END
\$\$;
SQL

echo "✅ Seeded policy_versions ACTIVE=${POLICY_VERSION}"

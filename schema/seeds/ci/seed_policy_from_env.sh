#!/usr/bin/env bash
# ============================================================
# seed_policy_from_env.sh — Seed policy from env vars (CI / minimal env)
# ============================================================
# Idempotent seeding: inserts if not exists, does NOT mutate existing ACTIVE rows.
# Control-plane rotation handles policy changes.
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

if [[ -z "${POLICY_VERSION:-}" && -n "${SEED_POLICY_VERSION:-}" ]]; then
  POLICY_VERSION="$SEED_POLICY_VERSION"
fi
if [[ -z "${POLICY_CHECKSUM:-}" && -n "${SEED_POLICY_CHECKSUM:-}" ]]; then
  POLICY_CHECKSUM="$SEED_POLICY_CHECKSUM"
fi

: "${POLICY_VERSION:?POLICY_VERSION is required}"
: "${POLICY_CHECKSUM:?POLICY_CHECKSUM is required}"

# Phase 1 semantics:
# - If an ACTIVE policy exists:
#     * If it's a different version -> fail closed (no rotation here)
#     * If it's the same version -> verify checksum and succeed (idempotent)
# - If no ACTIVE exists: seed as ACTIVE (idempotent by version)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<SQL
DO \$\$
DECLARE
  v_active_version TEXT;
  v_active_checksum TEXT;
  v_existing_checksum TEXT;
BEGIN
  SELECT version, checksum
    INTO v_active_version, v_active_checksum
    FROM policy_versions
   WHERE is_active = true
   LIMIT 1;

  IF v_active_version IS NOT NULL THEN
    IF v_active_version <> '$POLICY_VERSION' THEN
      RAISE EXCEPTION
        'Active policy already exists (version %, checksum %). Phase 1 seeding cannot activate version %.',
        v_active_version, v_active_checksum, '$POLICY_VERSION';
    END IF;

    IF v_active_checksum <> '$POLICY_CHECKSUM' THEN
      RAISE EXCEPTION
        'Policy checksum mismatch for version %: expected %, found %',
        '$POLICY_VERSION', '$POLICY_CHECKSUM', v_active_checksum;
    END IF;

    RETURN;
  END IF;

  INSERT INTO policy_versions (version, status, checksum)
  VALUES ('$POLICY_VERSION', 'ACTIVE', '$POLICY_CHECKSUM')
  ON CONFLICT (version) DO NOTHING;

  SELECT checksum
    INTO v_existing_checksum
    FROM policy_versions
   WHERE version = '$POLICY_VERSION';

  IF v_existing_checksum IS NULL THEN
    RAISE EXCEPTION 'Policy version % missing after seed attempt', '$POLICY_VERSION';
  END IF;

  IF v_existing_checksum <> '$POLICY_CHECKSUM' THEN
    RAISE EXCEPTION 'Policy checksum mismatch for version %: expected %, found %',
      '$POLICY_VERSION', '$POLICY_CHECKSUM', v_existing_checksum;
  END IF;
END
\$\$;
SQL

echo "✅ Policy version '$POLICY_VERSION' seeded (checksum: ${POLICY_CHECKSUM:0:16}...)."

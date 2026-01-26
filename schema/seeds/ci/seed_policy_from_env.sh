#!/usr/bin/env bash
# ============================================================
# seed_policy_from_env.sh — Seed policy from env vars (CI)
# ============================================================
# Idempotent seeding: inserts if not exists, does NOT mutate existing ACTIVE rows.
# Control-plane rotation handles policy changes.
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${POLICY_VERSION:?POLICY_VERSION is required}"
: "${POLICY_CHECKSUM:?POLICY_CHECKSUM is required}"

# Idempotent: only insert if version does not exist
# Does NOT mutate existing rows (control-plane rotation handles changes)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<SQL
INSERT INTO policy_versions (version, status, checksum)
VALUES ('$POLICY_VERSION', 'ACTIVE', '$POLICY_CHECKSUM')
ON CONFLICT (version) DO NOTHING;
SQL

echo "✅ Policy version '$POLICY_VERSION' seeded (checksum: ${POLICY_CHECKSUM:0:16}...)."

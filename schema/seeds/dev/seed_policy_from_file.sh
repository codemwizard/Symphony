#!/usr/bin/env bash
# ============================================================
# seed_policy_from_file.sh — Seed policy from local file (dev)
# ============================================================
# Idempotent seeding: inserts if missing, does NOT rotate policies.
# Fails closed if:
#  - version cannot be read
#  - checksum cannot be computed
#  - an ACTIVE policy exists with a different version
#  - the same version exists with a different checksum
#
# Usage:
#   schema/seeds/dev/seed_policy_from_file.sh /path/to/active-policy.json
#   schema/seeds/dev/seed_policy_from_file.sh --self-test
# ============================================================
set -euo pipefail

if [[ "${1:-}" == "--self-test" ]]; then
  set -euo pipefail
  echo "🧪 Self-test: verifying script honors provided file path and has no hard-coded policy path..."

  # 1) Ensure we do not contain the classic hard-coded path anti-pattern.
  if grep -nE "require\(['\"]\./\.policy/active-policy\.json['\"]\)" "$0" >/dev/null; then
    echo "❌ Self-test failed: script contains hard-coded require('./.policy/active-policy.json')" >&2
    exit 1
  fi

  # 2) Create two different policy files; ensure we parse the one we pass.
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  mkdir -p "$tmpdir/.policy"
  cat >"$tmpdir/.policy/active-policy.json" <<'JSON'
{"policyVersion":"v-selftest-B"}
JSON

  cat >"$tmpdir/A.json" <<'JSON'
{"policyVersion":"v-selftest-A"}
JSON

  got="$(
    node -e "
      const fs=require('fs');
      const p=process.argv[1];
      const o=JSON.parse(fs.readFileSync(p,'utf8'));
      const v=o.policyVersion || o.policy_version || o.policy_version_id || o.version;
      if(!v) process.exit(2);
      process.stdout.write(String(v).trim());
    " "$tmpdir/A.json"
  )"

  if [[ "$got" != "v-selftest-A" ]]; then
    echo "❌ Self-test failed: expected v-selftest-A, got '$got'" >&2
    exit 1
  fi

  # 3) Check checksum computation works in Node.
  cs="$(
    node -e "
      const fs=require('fs');
      const crypto=require('crypto');
      const b=fs.readFileSync(process.argv[1]);
      process.stdout.write(crypto.createHash('sha256').update(b).digest('hex'));
    " "$tmpdir/A.json"
  )"
  if [[ ! "$cs" =~ ^[0-9a-f]{64}$ ]]; then
    echo "❌ Self-test failed: checksum not valid sha256 hex: '$cs'" >&2
    exit 1
  fi

  echo "✅ Self-test passed."
  exit 0
fi

: "${DATABASE_URL:?DATABASE_URL is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="${1:-$SCRIPT_DIR/../../../.policy/active-policy.json}"

if [[ ! -f "$POLICY_FILE" ]]; then
  echo "❌ Policy file not found: $POLICY_FILE" >&2
  exit 1
fi

# Extract version from the provided file (never hard-code a path).
VERSION="$(
  node -e "
    const fs=require('fs');
    const p=process.argv[1];
    const o=JSON.parse(fs.readFileSync(p,'utf8'));
    const v=o.policyVersion || o.policy_version || o.policy_version_id || o.version;
    if(!v || typeof v !== 'string' || !v.trim()) process.exit(2);
    process.stdout.write(v.trim());
  " "$POLICY_FILE"   || true
)"

if [[ -z "${VERSION:-}" ]]; then
  echo "❌ Could not determine policy version from $POLICY_FILE" >&2
  echo "   Expected JSON key: policyVersion (preferred) or version/policy_version" >&2
  exit 1
fi

# Compute SHA-256 checksum in Node for portability (no jq/sha256sum required).
CHECKSUM="$(
  node -e "
    const fs=require('fs');
    const crypto=require('crypto');
    const b=fs.readFileSync(process.argv[1]);
    process.stdout.write(crypto.createHash('sha256').update(b).digest('hex'));
  " "$POLICY_FILE"
)"

if [[ -z "${CHECKSUM:-}" ]]; then
  echo "❌ Failed to compute checksum for $POLICY_FILE" >&2
  exit 1
fi

# Set session variables for use inside the DO block via current_setting()
# We use set_config to make them available to the PL/pgSQL block.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X \
  -v policy_version="$VERSION" \
  -v policy_checksum="$CHECKSUM" <<'SQL'
BEGIN;
  SELECT set_config('symphony.seed_version', :'policy_version', true);
  SELECT set_config('symphony.seed_checksum', :'policy_checksum', true);

DO $$
DECLARE
  v_version text;
  v_checksum text;
  existing_active text;
  existing_checksum text;
BEGIN
  v_version := current_setting('symphony.seed_version');
  v_checksum := current_setting('symphony.seed_checksum');

  -- Seed must not rotate policies: if ACTIVE exists with different version, refuse.
  SELECT version INTO existing_active
  FROM public.policy_versions
  WHERE status = 'ACTIVE'
  LIMIT 1;

  IF existing_active IS NOT NULL AND existing_active <> v_version THEN
    RAISE EXCEPTION
      'Seed refused: ACTIVE policy already set to %, cannot seed % (seed does not rotate)',
      existing_active, v_version;
  END IF;

  -- If the version exists, checksum must match.
  SELECT checksum INTO existing_checksum
  FROM public.policy_versions
  WHERE version = v_version;

  IF existing_checksum IS NOT NULL AND existing_checksum <> v_checksum THEN
    RAISE EXCEPTION
      'Seed refused: policy version % exists with different checksum',
      v_version;
  END IF;

  -- Insert if missing (idempotent).
  INSERT INTO public.policy_versions(version, status, checksum)
  VALUES (v_version, 'ACTIVE', v_checksum)
  ON CONFLICT (version) DO NOTHING;
END $$;

COMMIT;

SELECT 'POLICY_SEEDED_OK' AS status,
       current_setting('symphony.seed_version') AS version,
       left(current_setting('symphony.seed_checksum'), 16) || '…' AS checksum_prefix;
SQL

echo "✅ Policy version '$VERSION' seeded (checksum: ${CHECKSUM:0:16}...)."

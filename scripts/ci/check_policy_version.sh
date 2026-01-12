#!/usr/bin/env bash
set -euo pipefail

POLICY_FILE=".symphony/policies/active-policy.json"

POLICY_VERSION_FILE=$(jq -r '.policy_version' $POLICY_FILE)

DB_POLICY_VERSION=$(psql "$DATABASE_URL" -t -c \
  "SELECT id FROM policy_versions WHERE active = true;")

if [[ "$POLICY_VERSION_FILE" != "$DB_POLICY_VERSION" ]]; then
  echo "❌ Policy version mismatch"
  echo "File: $POLICY_VERSION_FILE"
  echo "DB:   $DB_POLICY_VERSION"
  exit 1
fi

echo "✅ Policy version verified: $POLICY_VERSION_FILE"

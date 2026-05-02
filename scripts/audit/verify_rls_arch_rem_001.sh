#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"

FAIL=0

if [[ -f "schema/migrations/0095_pre_snapshot.sql" ]]; then
  echo "FAIL: 0095_pre_snapshot.sql should not be in schema/migrations/" >&2
  FAIL=1
fi

if [[ -f "schema/migrations/0095_rollback.sql" ]]; then
  echo "FAIL: 0095_rollback.sql should not be in schema/migrations/" >&2
  FAIL=1
fi

if [[ ! -f "schema/rollbacks/0095_pre_snapshot.sql" ]]; then
  echo "FAIL: 0095_pre_snapshot.sql should be in schema/rollbacks/" >&2
  FAIL=1
fi

if [[ ! -f "schema/rollbacks/0095_rollback.sql" ]]; then
  echo "FAIL: 0095_rollback.sql should be in schema/rollbacks/" >&2
  FAIL=1
fi

if [[ ! -f "schema/migrations/0095_rls_dual_policy_architecture.sql" ]]; then
  echo "FAIL: 0095_rls_dual_policy_architecture.sql not found" >&2
  FAIL=1
else
  # Check if it was populated
  if ! grep -q 'CREATE TABLE IF NOT EXISTS public._migration_guards' "schema/migrations/0095_rls_dual_policy_architecture.sql"; then
    echo "FAIL: 0095_rls_dual_policy_architecture.sql is not populated correctly" >&2
    FAIL=1
  fi
fi

if [[ $FAIL -eq 1 ]]; then
  exit 1
fi

cat <<EOF
{
  "task_id": "TSK-RLS-ARCH-REM-001",
  "status": "PASS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "timestamp_utc": "$EVIDENCE_TS",
  "observed_hashes": {},
  "checks": [
    "0095_pre_snapshot.sql relocated to schema/rollbacks/",
    "0095_rollback.sql relocated to schema/rollbacks/",
    "0095_rls_dual_policy_architecture.sql populated with Phase 0/1 SQL"
  ]
}
EOF

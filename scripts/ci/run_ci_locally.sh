#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/local_ci_parity.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ "${CI_WIPE:-}" != "1" ]]; then
  echo "CI_WIPE=1 is required for destructive local CI parity run." >&2
  exit 1
fi

make_db_url() {
  local base_url="$1"
  local dbname="$2"
  BASE_URL="$base_url" NEW_DB="$dbname" python3 - <<'PY'
import os
from urllib.parse import urlparse, urlunparse

base = os.environ["BASE_URL"]
new_db = os.environ["NEW_DB"]
u = urlparse(base)
path = f"/{new_db}"
print(urlunparse((u.scheme, u.netloc, path, u.params, u.query, u.fragment)))
PY
}

ADMIN_URL="$(make_db_url "$DATABASE_URL" "postgres")"
TARGET_DB="$(python3 - <<'PY'
import os
from urllib.parse import urlparse
u = urlparse(os.environ["DATABASE_URL"])
print(u.path.lstrip("/") or "postgres")
PY
)"

echo "==> Local CI parity (destructive)"
echo "==> Wiping database: $TARGET_DB"

psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TARGET_DB' AND pid <> pg_backend_pid();" >/dev/null 2>&1 || true
psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS \"$TARGET_DB\";" >/dev/null 2>&1 || true
psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$TARGET_DB\";" >/dev/null

echo "==> 1) Fast invariants checks"
export SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1
scripts/audit/run_invariants_fast_checks.sh
unset SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS

echo "==> 1b) Structural change linkage evidence"
scripts/audit/enforce_change_rule.sh

echo "==> 2) DB verify (fresh)"
SKIP_POLICY_SEED=1 scripts/db/verify_invariants.sh

echo "==> 3) N-1 compatibility"
scripts/db/n_minus_one_check.sh

echo "==> 4) DB function tests"
scripts/db/tests/test_db_functions.sh

echo "==> 4b) Idempotency zombie test"
scripts/db/tests/test_idempotency_zombie.sh

echo "==> 4c) No-tx migrations test"
scripts/db/tests/test_no_tx_migrations.sh

echo "==> 5) Security fast checks"
scripts/audit/run_security_fast_checks.sh

echo "==> 5b) OpenBao smoke"
if [[ -x scripts/security/openbao_bootstrap.sh && -x scripts/security/openbao_smoke_test.sh ]]; then
  scripts/security/openbao_bootstrap.sh
  scripts/security/openbao_smoke_test.sh
else
  echo "ERROR: OpenBao scripts missing"
  exit 1
fi

echo "==> 5c) Contract evidence status"
CI_ONLY=1 scripts/audit/verify_phase0_contract_evidence_status.sh

echo "==> 6) Evidence gate (CI_ONLY)"
CI_ONLY=1 scripts/ci/check_evidence_required.sh evidence/phase0

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "LOCAL-CI-PARITY",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "PASS",
  "runner": "run_ci_locally.sh",
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

echo "✅ Local CI parity run complete. Evidence: $EVIDENCE_FILE"

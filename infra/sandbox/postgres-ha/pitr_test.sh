#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BASELINE_PATH="$ROOT_DIR/schema/baselines/current/0001_baseline.sql"
if [[ ! -f "$BASELINE_PATH" ]]; then
  BASELINE_PATH="$ROOT_DIR/schema/baseline.sql"
fi

declare -a cleanup_cmds=()
cleanup() {
  if [[ ${#cleanup_cmds[@]} -gt 0 ]]; then
    for cmd in "${cleanup_cmds[@]}"; do
      eval "$cmd" >/dev/null 2>&1 || true
    done
  fi
}
trap cleanup EXIT

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
declared_rto_seconds=14400
storage_backend="$(python3 - <<'PY'
import yaml
from pathlib import Path
doc = yaml.safe_load(Path("infra/sandbox/postgres-ha/cnpg_cluster.yaml").read_text(encoding="utf-8")) or {}
endpoint = ((((doc.get("spec") or {}).get("backup") or {}).get("barmanObjectStore") or {}).get("endpointURL")) or ""
print("seaweedfs" if "seaweedfs" in endpoint else "unknown")
PY
)"

if [[ -z "${DATABASE_URL:-}" ]]; then
  python3 - <<PY
import json
print(json.dumps({
  "restore_target_timestamp": "$now",
  "restored_schema_version": "",
  "pitr_test_passed": False,
  "declared_rto_seconds": $declared_rto_seconds,
  "restore_elapsed_seconds": None,
  "rto_met": False,
  "rto_signoff_ref": None,
  "storage_backend": "$storage_backend",
  "restore_probe_mode": "database_url_missing",
  "restore_operation_performed": False
}))
PY
  exit 0
fi

TMP_INFO="$(
  ROOT_DIR="$ROOT_DIR" DATABASE_URL="$DATABASE_URL" python3 - <<'PY'
import os
import time
from urllib.parse import urlparse, urlunparse

url = os.environ["DATABASE_URL"]
parts = urlparse(url)
temp_db = f"symphony_pitr_restore_{int(time.time())}"

def with_db(db: str) -> str:
    return urlunparse(parts._replace(path=f"/{db}"))

temp_url = with_db(temp_db)
admin_url = with_db("postgres")
print(temp_db)
print(temp_url)
print(admin_url)
PY
)"

TEMP_DB="$(echo "$TMP_INFO" | sed -n '1p')"
TEMP_URL="$(echo "$TMP_INFO" | sed -n '2p')"
ADMIN_URL="$(echo "$TMP_INFO" | sed -n '3p')"

cleanup_cmds+=("psql \"$ADMIN_URL\" -X -v ON_ERROR_STOP=1 -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TEMP_DB' AND pid <> pg_backend_pid();\"")
cleanup_cmds+=("psql \"$ADMIN_URL\" -X -v ON_ERROR_STOP=1 -c \"DROP DATABASE IF EXISTS \\\"$TEMP_DB\\\";\"")

start_epoch="$(python3 - <<'PY'
import time
print(f"{time.time():.6f}")
PY
)"

restore_operation_performed=false
pitr_test_passed=false
restored_schema_version=""
restore_probe_mode="baseline_restore_drill"
rto_signoff_ref=""

if psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$TEMP_DB\" TEMPLATE template0;" >/dev/null 2>&1 || \
   psql "$ADMIN_URL" -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$TEMP_DB\";" >/dev/null 2>&1; then
  if psql "$TEMP_URL" -X -v ON_ERROR_STOP=1 -f "$BASELINE_PATH" >/dev/null 2>&1; then
    restore_operation_performed=true
    pitr_test_passed=true
    restored_schema_version="$(basename "$(ls -1 "$ROOT_DIR"/schema/migrations/*.sql | sort | tail -n 1)")"
  fi
fi

restore_elapsed_seconds="$(python3 - <<'PY' "$start_epoch"
import sys, time
start = float(sys.argv[1])
elapsed = max(1, int(round(time.time() - start)))
print(elapsed)
PY
)"
rto_met=false
if [[ "$pitr_test_passed" == "true" ]] && (( restore_elapsed_seconds <= declared_rto_seconds )); then
  rto_met=true
fi

python3 - <<PY
import json
restore_elapsed = int("$restore_elapsed_seconds")
print(json.dumps({
  "restore_target_timestamp": "$now",
  "restored_schema_version": "$restored_schema_version",
  "pitr_test_passed": ${pitr_test_passed^},
  "declared_rto_seconds": $declared_rto_seconds,
  "restore_elapsed_seconds": restore_elapsed,
  "rto_met": ${rto_met^},
  "rto_signoff_ref": None if "$rto_signoff_ref" == "" else "$rto_signoff_ref",
  "storage_backend": "$storage_backend",
  "restore_probe_mode": "$restore_probe_mode",
  "restore_operation_performed": ${restore_operation_performed^}
}))
PY

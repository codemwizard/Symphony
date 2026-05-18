#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMP_DB="symphony_p3_support_db_002_$$_$(date +%s)"

ADMIN_URL="$(python3 - <<'PY' "$DATABASE_URL"
import sys
from urllib.parse import urlparse, urlunparse
u = urlparse(sys.argv[1])
path = "/postgres"
print(urlunparse(u._replace(path=path)))
PY
)"

TEMP_DB_URL="$(python3 - <<'PY' "$DATABASE_URL" "$TEMP_DB"
import sys
from urllib.parse import urlparse, urlunparse
u = urlparse(sys.argv[1])
print(urlunparse(u._replace(path="/" + sys.argv[2])))
PY
)"

cleanup() {
  psql "$ADMIN_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$TEMP_DB\";" >/dev/null 2>&1 || true
}
trap cleanup EXIT

psql "$ADMIN_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$TEMP_DB\";" >/dev/null
psql "$ADMIN_URL" -v ON_ERROR_STOP=1 -X -c "CREATE DATABASE \"$TEMP_DB\";" >/dev/null

(
  export DATABASE_URL="$TEMP_DB_URL"
  bash "$ROOT/scripts/db/migrate.sh" >/dev/null
  bash "$ROOT/scripts/db/generate_baseline_snapshot.sh" 2026-05-17 >/dev/null
)

python3 - "$ROOT" "$TEMP_DB_URL" <<'PY'
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = sys.argv[1]
db_url = sys.argv[2]
meta_path = Path(root) / "schema/baselines/current/baseline.meta.json"
evidence_path = Path(root) / "evidence/phase0/baseline_drift.json"

with meta_path.open() as fh:
    meta = json.load(fh)

checks = []
checks.append({"check": "baseline_meta_contains_privilege_hash", "pass": bool(meta.get("privilege_state_sha256"))})
checks.append({"check": "baseline_meta_contains_privilege_state", "pass": isinstance(meta.get("privilege_state"), list)})
checks.append({"check": "baseline_meta_contains_privilege_entry_count", "pass": isinstance(meta.get("privilege_entry_count"), int)})

subprocess.run(
    ["psql", db_url, "-v", "ON_ERROR_STOP=1", "-X", "-c", "REVOKE SELECT ON TABLE public.p3_dependency_nodes FROM symphony_readonly;"],
    check=True,
    stdout=subprocess.DEVNULL,
)

drift = subprocess.run(
    ["bash", str(Path(root) / "scripts/db/check_baseline_drift.sh")],
    env={**os.environ, "DATABASE_URL": db_url},
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
checks.append({"check": "privilege_only_drift_fails", "pass": drift.returncode != 0})

with evidence_path.open() as fh:
    drift_evidence = json.load(fh)

checks.append({"check": "drift_evidence_reports_privilege_drift", "pass": drift_evidence.get("privilege_drift") is True})
checks.append({"check": "drift_evidence_preserves_schema_drift_false", "pass": drift_evidence.get("schema_drift") is False})

status = "PASS" if all(item["pass"] for item in checks) else "FAIL"
git_sha = subprocess.check_output(["git", "-C", root, "rev-parse", "HEAD"], text=True).strip()

observed_paths = [
    str(Path(root) / "scripts/db/generate_baseline_snapshot.sh"),
    str(Path(root) / "scripts/db/check_baseline_drift.sh"),
    str(Path(root) / "scripts/db/verify_tsk_p3_support_db_002_privilege_baseline_visibility.sh"),
    str(meta_path),
    str(evidence_path),
    str(Path(root) / "docs/decisions/ADR-0010-baseline-policy.md"),
]

def sha256(path: str) -> str:
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()

payload = {
    "task_id": "TSK-P3-SUPPORT-DB-002",
    "git_sha": git_sha,
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "status": status,
    "checks": checks,
    "observed_paths": observed_paths,
    "observed_hashes": {path: sha256(path) for path in observed_paths},
    "command_outputs": [
        {"command": "scripts/db/migrate.sh", "status": "PASS"},
        {"command": "scripts/db/generate_baseline_snapshot.sh 2026-05-17", "status": "PASS"},
        {"command": "REVOKE SELECT ON TABLE public.p3_dependency_nodes FROM symphony_readonly;", "status": "PASS"},
        {"command": "scripts/db/check_baseline_drift.sh", "status": "PASS" if drift.returncode != 0 else "FAIL"}
    ],
    "execution_trace": [
        "Created an isolated verification database and applied all migrations.",
        "Generated a fresh baseline snapshot and confirmed privilege fingerprint fields exist in baseline metadata.",
        "Applied a privilege-only REVOKE and confirmed baseline drift now fails on privilege divergence without schema drift."
    ]
}

json.dump(payload, sys.stdout, indent=2)
if status != "PASS":
    sys.exit(1)
PY

#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/role_login_posture.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

roles=(
  "symphony_ingest"
  "symphony_executor"
  "symphony_readonly"
  "symphony_auditor"
  "symphony_control"
)

bad=()
for r in "${roles[@]}"; do
  val="$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -t -A -c \
    "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_roles WHERE rolname='${r}' AND rolcanlogin) THEN 'BAD' ELSE 'OK' END;")"
  if [[ "$val" == "BAD" ]]; then
    bad+=("$r")
  fi
done

status="PASS"
if [[ "${#bad[@]}" -gt 0 ]]; then
  status="FAIL"
fi

BAD_ROLES_CSV="$(IFS=,; echo "${bad[*]-}")"
export BAD_ROLES_CSV
export STATUS="$status"
export ROLES_CHECKED="${#roles[@]}"
export EVIDENCE_FILE

python3 - <<'PY'
import json
import os
from pathlib import Path
out = {
  "check_id": "DB-ROLE-LOGIN-POSTURE",
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": os.environ.get("STATUS"),
  "roles_checked": int(os.environ.get("ROLES_CHECKED", "0")),
  "bad_roles": [r for r in (os.environ.get("BAD_ROLES_CSV", "").split(",")) if r],
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n")
PY

echo "Role login posture evidence: $EVIDENCE_FILE"

if [[ "$status" != "PASS" ]]; then
  echo "❌ Role login posture failed (roles must be NOLOGIN): ${bad[*]}" >&2
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="/tmp/symphony_openbao"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/openbao_smoke.json"
AUDIT_EVIDENCE_FILE="$EVIDENCE_DIR/openbao_audit_log.json"
BAO_ADDR="http://127.0.0.1:8200"

mkdir -p "$EVIDENCE_DIR"

ROLE_ID_FILE="$STATE_DIR/role_id"
SECRET_ID_FILE="$STATE_DIR/secret_id"

if [[ ! -f "$ROLE_ID_FILE" || ! -f "$SECRET_ID_FILE" ]]; then
  echo "Missing OpenBao role_id/secret_id. Run openbao_bootstrap.sh first." >&2
  exit 1
fi

ROLE_ID=$(cat "$ROLE_ID_FILE")
SECRET_ID=$(cat "$SECRET_ID_FILE")

bao_exec() {
  docker exec -e BAO_ADDR="$BAO_ADDR" symphony-openbao bao "$@"
}

# Login via approle
TOKEN=$(bao_exec write -field=token auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID")

# Allowed read should succeed
ALLOWED=$(docker exec -e BAO_ADDR="$BAO_ADDR" -e BAO_TOKEN="$TOKEN" symphony-openbao bao kv get -field=value kv/allowed/test || true)

# Forbidden read should fail
set +e
FORBIDDEN=$(docker exec -e BAO_ADDR="$BAO_ADDR" -e BAO_TOKEN="$TOKEN" symphony-openbao bao kv get -field=value kv/forbidden/test 2>/dev/null)
FORBIDDEN_STATUS=$?
set -e

python3 - <<PY
import json
out = {
  "allowed_read": "$ALLOWED",
  "forbidden_status": $FORBIDDEN_STATUS,
  "status": "pass" if "$ALLOWED" == "ok" and $FORBIDDEN_STATUS != 0 else "fail",
}
with open("$EVIDENCE_FILE", "w", encoding="utf-8") as f:
  json.dump(out, f, indent=2)
PY

# Check audit log file produced by declarative audit config
AUDIT_BYTES=$(docker exec symphony-openbao sh -c 'stat -c %s /openbao/audit.log 2>/dev/null || echo 0')
AUDIT_PRESENT="false"
if [[ "$AUDIT_BYTES" -gt 0 ]]; then
  AUDIT_PRESENT="true"
fi

python3 - <<PY
import json
from pathlib import Path
out = {
  "status": "pass" if "$AUDIT_PRESENT" == "true" else "fail",
  "audit_log_bytes": int("$AUDIT_BYTES"),
  "audit_log_present": "$AUDIT_PRESENT" == "true",
  "path": "/openbao/audit.log"
}
Path("$AUDIT_EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ "$ALLOWED" != "ok" ]]; then
  echo "OpenBao allowed read failed" >&2
  exit 1
fi
if [[ $FORBIDDEN_STATUS -eq 0 ]]; then
  echo "OpenBao forbidden read unexpectedly succeeded" >&2
  exit 1
fi
if [[ "$AUDIT_PRESENT" != "true" ]]; then
  echo "OpenBao audit log not present or empty" >&2
  exit 1
fi

echo "OpenBao smoke test passed. Evidence: $EVIDENCE_FILE"

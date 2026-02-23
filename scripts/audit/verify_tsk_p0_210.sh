#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$EVIDENCE_PATH" ]]; then
  echo "Usage: $0 --evidence <path>" >&2
  exit 2
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  ENV_FILE="$ROOT_DIR/infra/docker/.env"
  if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    set +a
  fi
  if [[ -n "${POSTGRES_USER:-}" && -n "${POSTGRES_PASSWORD:-}" && -n "${POSTGRES_DB:-}" ]]; then
    DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${HOST_POSTGRES_PORT:-5432}/${POSTGRES_DB}"
    export DATABASE_URL
  fi
fi

: "${DATABASE_URL:?DATABASE_URL is required}"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"

if [[ ! -x "$ROOT_DIR/scripts/db/verify_boz_observability_role.sh" ]]; then
  echo "ERROR: missing_verifier:scripts/db/verify_boz_observability_role.sh" >&2
  exit 1
fi

# Refresh canonical BoZ role evidence first.
"$ROOT_DIR/scripts/db/verify_boz_observability_role.sh"

ROOT_DIR="$ROOT_DIR" EVIDENCE_PATH="$EVIDENCE_PATH" EVIDENCE_TS="$EVIDENCE_TS" EVIDENCE_GIT_SHA="$EVIDENCE_GIT_SHA" EVIDENCE_SCHEMA_FP="$EVIDENCE_SCHEMA_FP" DATABASE_URL="$DATABASE_URL" \
python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
evidence = root / os.environ["EVIDENCE_PATH"]
boz_evidence = root / "evidence/phase0/boz_observability_role.json"
errors: list[str] = []

def q(sql: str) -> str:
    out = subprocess.check_output(
        ["psql", os.environ["DATABASE_URL"], "-q", "-t", "-A", "-v", "ON_ERROR_STOP=1", "-X", "-c", sql],
        text=True,
    )
    return out.strip()

if not boz_evidence.exists():
    errors.append("missing_boz_evidence:evidence/phase0/boz_observability_role.json")
else:
    try:
        boz = json.loads(boz_evidence.read_text(encoding="utf-8"))
        if boz.get("status") != "PASS":
            errors.append("boz_observability_role_not_pass")
    except Exception as exc:
        errors.append(f"invalid_boz_evidence_json:{exc}")

role_exists = q("SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='boz_auditor');") == "t"
role_nologin = q("SELECT COALESCE((SELECT NOT rolcanlogin FROM pg_roles WHERE rolname='boz_auditor'), false);") == "t"
# SET ROLE denial posture: no role membership grants into boz_auditor.
boz_membership_grants = q(
    "SELECT COUNT(*) FROM pg_auth_members m JOIN pg_roles r ON r.oid = m.roleid WHERE r.rolname='boz_auditor';"
)
no_set_role_path = boz_membership_grants == "0"

if not role_exists:
    errors.append("missing_role:boz_auditor")
if not role_nologin:
    errors.append("boz_role_must_be_nologin")
if not no_set_role_path:
    errors.append("set_role_denial_failed:boz_auditor_has_members")

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "TSK-P0-210",
    "task_id": "TSK-P0-210",
    "timestamp_utc": os.environ["EVIDENCE_TS"],
    "git_sha": os.environ["EVIDENCE_GIT_SHA"],
    "schema_fingerprint": os.environ["EVIDENCE_SCHEMA_FP"],
    "status": status,
    "pass": status == "PASS",
    "details": {
        "role_exists": role_exists,
        "role_nologin": role_nologin,
        "boz_membership_grants": int(boz_membership_grants),
        "set_role_denial_posture": no_set_role_path,
        "boz_evidence_path": "evidence/phase0/boz_observability_role.json",
        "errors": errors,
    },
}
evidence.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(f"TSK-P0-210 verifier status: {status}")
print(f"Evidence: {evidence}")
raise SystemExit(0 if status == "PASS" else 1)
PY

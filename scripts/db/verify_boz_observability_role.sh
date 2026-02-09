#!/usr/bin/env bash
set -euo pipefail

# verify_boz_observability_role.sh
#
# Phase-0 structural verifier for a regulator-readonly seat.
# Proves:
# - role exists and is NOLOGIN
# - role has USAGE on schema public
# - role has SELECT on a fixed allowlist of tables
# - role has no CREATE on schemas and no DML on those tables
#
# Evidence: evidence/phase0/boz_observability_role.json

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/boz_observability_role.json"
mkdir -p "$EVIDENCE_DIR"

CHECK_ID="DB-BOZ-OBSERVABILITY-ROLE"
GATE_ID="INT-G23"
INVARIANT_ID="INV-111"
ROLE_NAME="boz_auditor"

echo "==> BoZ observability role verifier (${ROLE_NAME})"

psql_q() {
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$1"
}

# Fixed allowlist for Phase-0 regulator observability.
TABLES=(
  "public.payment_outbox_pending"
  "public.payment_outbox_attempts"
  "public.participants"
  "public.billable_clients"
  "public.billing_usage_events"
  "public.external_proofs"
  "public.evidence_packs"
  "public.evidence_pack_items"
)

export CHECK_ID GATE_ID INVARIANT_ID
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
export EVIDENCE_FILE DATABASE_URL ROLE_NAME

if TABLES_JOINED="${TABLES[*]}" python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path

dburl = os.environ["DATABASE_URL"]
role = os.environ["ROLE_NAME"]
tables = os.environ["TABLES_JOINED"].split()

def q(sql: str) -> str:
    out = subprocess.check_output(
        ["psql", dburl, "-q", "-t", "-A", "-v", "ON_ERROR_STOP=1", "-X", "-c", sql],
        text=True,
    )
    return out.strip()

errors = []

role_row = q(
    f"SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole, rolreplication, rolbypassrls "
    f"FROM pg_roles WHERE rolname='{role}';"
)
role_info = None
if not role_row:
    errors.append("missing_role")
else:
    parts = role_row.split("|")
    role_info = {
        "name": parts[0],
        "rolcanlogin": parts[1],
        "rolsuper": parts[2],
        "rolcreatedb": parts[3],
        "rolcreaterole": parts[4],
        "rolreplication": parts[5],
        "rolbypassrls": parts[6],
    }
    if role_info["rolcanlogin"] != "f":
        errors.append("role_must_be_nologin")
    if role_info["rolsuper"] != "f":
        errors.append("role_must_not_be_superuser")
    if role_info["rolcreatedb"] != "f":
        errors.append("role_must_not_createdb")
    if role_info["rolcreaterole"] != "f":
        errors.append("role_must_not_createrole")
    if role_info["rolreplication"] != "f":
        errors.append("role_must_not_replication")
    if role_info["rolbypassrls"] != "f":
        errors.append("role_must_not_bypassrls")

schema_usage = q(f"SELECT has_schema_privilege('{role}','public','USAGE');") == "t"
schema_create = q(f"SELECT has_schema_privilege('{role}','public','CREATE');") == "t"
if not schema_usage:
    errors.append("missing_schema_usage")
if schema_create:
    errors.append("schema_create_not_allowed")

per_table = []
missing_select = []
dml_present = []
for t in tables:
    sel = q(f"SELECT has_table_privilege('{role}','{t}','SELECT');") == "t"
    ins = q(f"SELECT has_table_privilege('{role}','{t}','INSERT');") == "t"
    upd = q(f"SELECT has_table_privilege('{role}','{t}','UPDATE');") == "t"
    dele = q(f"SELECT has_table_privilege('{role}','{t}','DELETE');") == "t"
    trunc = q(f"SELECT has_table_privilege('{role}','{t}','TRUNCATE');") == "t"
    per_table.append(
        {
            "table": t,
            "select": sel,
            "insert": ins,
            "update": upd,
            "delete": dele,
            "truncate": trunc,
        }
    )
    if not sel:
        missing_select.append(t)
    if ins or upd or dele or trunc:
        dml_present.append(t)

if missing_select:
    errors.append("missing_select_on_allowlist")
if dml_present:
    errors.append("dml_privileges_present")

ok = len(errors) == 0
out = {
    "check_id": os.environ["CHECK_ID"],
    "gate_id": os.environ["GATE_ID"],
    "invariant_id": os.environ["INVARIANT_ID"],
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if ok else "FAIL",
    "ok": ok,
    "role": role_info or {"name": role},
    "schema_privileges": {"public_usage": schema_usage, "public_create": schema_create},
    "allowlist_tables": per_table,
    "missing_select": missing_select,
    "dml_privileges_present": dml_present,
    "errors": errors,
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")

raise SystemExit(0 if ok else 1)
PY
then
  echo "✅ BoZ observability role verifier passed"
else
  echo "❌ BoZ observability role verifier failed"
  exit 1
fi

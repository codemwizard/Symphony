#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/ingress_hotpath_indexes.json"
mkdir -p "$EVIDENCE_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

# Query index metadata once and evaluate deterministically in Python.
if INDEX_ROWS="$(psql "$DATABASE_URL" -X -A -t -F $'\t' -v ON_ERROR_STOP=1 <<'SQL'
SELECT
  i.relname AS index_name,
  COALESCE(string_agg(a.attname, ',' ORDER BY x.ordinality), '') AS columns,
  ix.indisunique,
  ix.indisvalid,
  COALESCE(pg_get_expr(ix.indpred, t.oid), '') AS predicate,
  am.amname AS method
FROM pg_class t
JOIN pg_namespace n ON n.oid = t.relnamespace
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_am am ON am.oid = i.relam
LEFT JOIN LATERAL unnest(ix.indkey) WITH ORDINALITY AS x(attnum, ordinality) ON true
LEFT JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = x.attnum
WHERE n.nspname = 'public'
  AND t.relname = 'ingress_attestations'
GROUP BY i.relname, ix.indisunique, ix.indisvalid, ix.indpred, t.oid, am.amname
ORDER BY i.relname;
SQL
)"
then
  psql_rc=0
else
  psql_rc=$?
fi

if [[ $psql_rc -ne 0 ]]; then
  INDEX_ROWS=""
fi

INDEX_ROWS="$INDEX_ROWS" PSQL_RC="$psql_rc" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

rows = []
for line in os.environ.get("INDEX_ROWS", "").splitlines():
    if not line.strip():
        continue
    parts = line.split("\t")
    if len(parts) != 6:
        continue
    rows.append(
        {
            "index_name": parts[0],
            "columns": parts[1],
            "indisunique": parts[2] == "t",
            "indisvalid": parts[3] == "t",
            "predicate": parts[4],
            "method": parts[5],
        }
    )

required = [
    {
        "name": "ux_ingress_attestations_tenant_instruction",
        "columns": "tenant_id,instruction_id",
        "unique": True,
        "method": "btree",
        "predicate_contains": "",
    },
    {
        "name": "idx_ingress_attestations_tenant_received",
        "columns": "tenant_id,received_at",
        "unique": False,
        "method": "btree",
        "predicate_contains": "tenant_id IS NOT NULL",
    },
    {
        "name": "idx_ingress_attestations_tenant_correlation",
        "columns": "tenant_id,correlation_id",
        "unique": False,
        "method": "btree",
        "predicate_contains": "correlation_id IS NOT NULL",
    },
    {
        "name": "idx_ingress_attestations_correlation_id",
        "columns": "correlation_id",
        "unique": False,
        "method": "btree",
        "predicate_contains": "correlation_id IS NOT NULL",
    },
]

index_map = {r["index_name"]: r for r in rows}
checks = []
errors = []
for req in required:
    found = index_map.get(req["name"])
    result = {
        "index_name": req["name"],
        "required_columns": req["columns"],
        "required_unique": req["unique"],
        "required_method": req["method"],
        "required_predicate_contains": req["predicate_contains"],
        "found": found is not None,
    }
    if not found:
        errors.append(f"missing:{req['name']}")
    else:
        result["actual_columns"] = found["columns"]
        result["actual_unique"] = found["indisunique"]
        result["actual_valid"] = found["indisvalid"]
        result["actual_method"] = found["method"]
        result["actual_predicate"] = found["predicate"]

        if found["columns"] != req["columns"]:
            errors.append(f"columns_mismatch:{req['name']}")
        if found["indisunique"] != req["unique"]:
            errors.append(f"uniqueness_mismatch:{req['name']}")
        if found["method"] != req["method"]:
            errors.append(f"method_mismatch:{req['name']}")
        if not found["indisvalid"]:
            errors.append(f"invalid_index:{req['name']}")
        if req["predicate_contains"] and req["predicate_contains"] not in found["predicate"]:
            errors.append(f"predicate_mismatch:{req['name']}")

    checks.append(result)

psql_rc = int(os.environ.get("PSQL_RC", "1"))
if psql_rc != 0:
    errors.append("catalog_query_failed")

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "DB-INGRESS-HOTPATH-INDEXES",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "checks": checks,
    "errors": errors,
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")

if status != "PASS":
    raise SystemExit(1)
PY

echo "✅ Ingress hot-path index test passed"

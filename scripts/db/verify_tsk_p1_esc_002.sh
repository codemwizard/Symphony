#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-ESC-002"
DEFAULT_EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json"
EVIDENCE_FILE="$DEFAULT_EVIDENCE"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_FILE="$2"
      shift 2
      ;;
    *)
      echo "unknown_arg:$1" >&2
      exit 1
      ;;
  esac
done

if [[ "$EVIDENCE_FILE" != /* ]]; then
  EVIDENCE_FILE="$ROOT_DIR/$EVIDENCE_FILE"
fi
mkdir -p "$(dirname "$EVIDENCE_FILE")"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

failures=()
add_failure() { failures+=("$1"); }

query_text() {
  local sql="$1"
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" | tr -d '[:space:]'
}

query_bool() {
  local sql="$1"
  local val
  val="$(query_text "$sql")"
  [[ "$val" == "t" ]] && echo "true" || echo "false"
}

# --- prereqs / structural checks ---
migration_exists="false"
if [[ -f "$ROOT_DIR/schema/migrations/0046_escrow_ceiling_enforcement_cross_tenant.sql" ]]; then
  migration_exists="true"
else
  add_failure "migration_missing:0046_escrow_ceiling_enforcement_cross_tenant.sql"
fi

tables_exist="$(query_bool "
SELECT to_regclass('public.programs') IS NOT NULL
   AND to_regclass('public.escrow_envelopes') IS NOT NULL
   AND to_regclass('public.escrow_reservations') IS NOT NULL;
")"
[[ "$tables_exist" == "true" ]] || add_failure "table_missing:programs_or_escrow_envelopes_or_escrow_reservations"

program_fk_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public'
    AND t.relname='programs'
    AND c.contype='f'
    AND pg_get_constraintdef(c.oid) ILIKE '%(program_escrow_id)%REFERENCES escrow_accounts(escrow_id)%ON DELETE RESTRICT%'
);
")"
[[ "$program_fk_verified" == "true" ]] || add_failure "program_escrow_fk_missing_or_not_restrict"

envelope_lock_present="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='authorize_escrow_reservation'
    AND pg_get_functiondef(p.oid) ILIKE '%FOR UPDATE%'
    AND pg_get_functiondef(p.oid) ILIKE '%FROM public.escrow_envelopes%'
);
")"
[[ "$envelope_lock_present" == "true" ]] || add_failure "authorize_escrow_reservation_missing_for_update_lock"

reservation_function_hardened="$(query_bool "
SELECT p.prosecdef
   AND EXISTS (
     SELECT 1
     FROM unnest(COALESCE(p.proconfig, ARRAY[]::text[])) cfg
     WHERE cfg = 'search_path=pg_catalog, public'
   )
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname='public'
  AND p.proname='authorize_escrow_reservation'
LIMIT 1;
")"
[[ "$reservation_function_hardened" == "true" ]] || add_failure "authorize_escrow_reservation_not_hardened"

tenant_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT tenant_id::text FROM public.tenants ORDER BY created_at LIMIT 1;" | tr -d '[:space:]')"
if [[ -z "$tenant_id" ]]; then
  tenant_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
WITH bc AS (
  INSERT INTO public.billable_clients(legal_name, client_type, status, client_key)
  VALUES ('TSK-P1-ESC-002 billable root', 'ENTERPRISE', 'ACTIVE', 'tsk-p1-esc-002')
  RETURNING billable_client_id
)
INSERT INTO public.tenants(tenant_key, tenant_name, tenant_type, status, billable_client_id)
SELECT 'tsk_p1_esc_002_tenant', 'TSK-P1-ESC-002 tenant', 'COMMERCIAL', 'ACTIVE', billable_client_id
FROM bc
RETURNING tenant_id::text;
" | tr -d '[:space:]')"
fi
if [[ -z "$tenant_id" ]]; then
  add_failure "prereq_missing:public.tenants unavailable"
fi

# --- scenario: 50 concurrent reservations must not exceed ceiling ---
ceiling_enforced="false"
ok_count=0
ceiling_reject_count=0
other_error_count=0
final_reserved_amount_minor=""
reservation_rows=""
program_escrow_id=""

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

if [[ ${#failures[@]} -eq 0 ]]; then
  # Create a program escrow account row (envelope anchor).
  program_escrow_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
INSERT INTO public.escrow_accounts(
  tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at
) VALUES (
  '$tenant_id', NULL, NULL, 'AUTHORIZED', 1000000, 'ZMW', NOW() + interval '2 hours'
)
RETURNING escrow_id::text;
" | tr -d '[:space:]')"

  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
INSERT INTO public.escrow_envelopes(escrow_id, tenant_id, currency_code, ceiling_amount_minor, reserved_amount_minor)
VALUES ('$program_escrow_id'::uuid, '$tenant_id'::uuid, 'ZMW', 1000, 0)
ON CONFLICT (escrow_id) DO UPDATE
SET ceiling_amount_minor=EXCLUDED.ceiling_amount_minor, reserved_amount_minor=0, updated_at=NOW();
" >/dev/null

  # Program record bound to envelope.
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
INSERT INTO public.programs(tenant_id, program_key, program_name, status, program_escrow_id)
VALUES ('$tenant_id'::uuid, 'tsk_p1_esc_002_program', 'TSK-P1-ESC-002 Program', 'ACTIVE', '$program_escrow_id'::uuid)
ON CONFLICT (tenant_id, program_key) DO UPDATE
SET program_escrow_id=EXCLUDED.program_escrow_id, updated_at=NOW();
" >/dev/null

  # Launch 50 concurrent reservation attempts of 100 minor units each (ceiling=1000).
  for i in $(seq 1 50); do
    (
      set +e
      out="$(psql "$DATABASE_URL" -X -q -t -A --set=VERBOSITY=verbose -v ON_ERROR_STOP=1 -c \
        "SELECT public.authorize_escrow_reservation('${program_escrow_id}'::uuid, 100, 'verifier', 'concurrency_test', '{}'::jsonb)::text;" 2>&1)"
      rc=$?
      if [[ $rc -eq 0 ]]; then
        echo "OK:$(tr -d '[:space:]' <<<"$out")" >"$tmpdir/$i.txt"
      else
        # Extract SQL state / P-code from psql output. psql can emit either:
        # - "SQL state: P7304" (VERBOSITY=verbose)
        # - "ERROR:  P7304: ..." (default)
        st="$(grep -Eo 'SQL state: [A-Z0-9]{5}' <<<"$out" | head -n1 | awk '{print $3}')"
        if [[ -z "$st" ]]; then
          st="$(grep -Eo 'P[0-9]{4}' <<<"$out" | head -n1 || true)"
        fi
        [[ -n "$st" ]] || st="UNKNOWN"
        echo "ERR:$st" >"$tmpdir/$i.txt"
      fi
      exit 0
    ) &
  done
  wait

  # Deterministic count parsing; avoid pipefail issues when there are zero matches.
  read -r ok_count ceiling_reject_count other_error_count < <(
    python3 - <<'PY' "$tmpdir"
import sys
from pathlib import Path

root = Path(sys.argv[1])
ok = 0
ceil = 0
other = 0
for p in sorted(root.glob("*.txt")):
    line = (p.read_text(encoding="utf-8", errors="replace") or "").strip()
    if line.startswith("OK:"):
        ok += 1
        continue
    if line.startswith("ERR:"):
        code = line.split(":", 1)[1].strip()
        if code == "P7304":
            ceil += 1
        else:
            other += 1
        continue
    # unknown line format
    other += 1
print(ok, ceil, other)
PY
  )

  final_reserved_amount_minor="$(query_text "SELECT reserved_amount_minor::text FROM public.escrow_envelopes WHERE escrow_id='${program_escrow_id}'::uuid;")"
  reservation_rows="$(query_text "SELECT COUNT(*)::text FROM public.escrow_reservations WHERE program_escrow_id='${program_escrow_id}'::uuid;")"

  if [[ "$final_reserved_amount_minor" == "1000" && "$reservation_rows" == "10" && "$ok_count" == "10" && "$other_error_count" == "0" ]]; then
    ceiling_enforced="true"
  else
    add_failure "ceiling_enforcement_failed:reserved=${final_reserved_amount_minor}:reservations=${reservation_rows}:ok=${ok_count}:other_err=${other_error_count}"
  fi
fi

status="PASS"
pass=true
if [[ ${#failures[@]} -gt 0 ]]; then
  status="FAIL"
  pass=false
fi

EVIDENCE_FILE="$EVIDENCE_FILE" TASK_ID="$TASK_ID" \
MIGRATION_EXISTS="$migration_exists" TABLES_EXIST="$tables_exist" PROGRAM_FK_VERIFIED="$program_fk_verified" \
AUTHORIZE_LOCK_PRESENT="$envelope_lock_present" AUTHORIZE_HARDENED="$reservation_function_hardened" \
CEILING_ENFORCED="$ceiling_enforced" OK_COUNT="$ok_count" CEILING_REJECT_COUNT="$ceiling_reject_count" \
OTHER_ERROR_COUNT="$other_error_count" FINAL_RESERVED="$final_reserved_amount_minor" RESERVATION_ROWS="$reservation_rows" \
PROGRAM_ESCROW_ID="$program_escrow_id" python3 - <<'PY'
import json
import os
from pathlib import Path


def to_bool(val: str) -> bool:
    return str(val).strip().lower() in {"1", "true", "t", "yes", "y"}


def to_int_or_none(val: str):
    s = str(val).strip()
    if not s:
        return None
    try:
        return int(s)
    except Exception:
        return None


payload = {
    "task_id": os.environ["TASK_ID"],
    "check_id": "TSK-P1-ESC-002",
    "timestamp_utc": os.environ["EVIDENCE_TS"],
    "git_sha": os.environ["EVIDENCE_GIT_SHA"],
    "schema_fingerprint": os.environ["EVIDENCE_SCHEMA_FP"],
    "status": "PASS",
    "pass": True,
    "details": {
        "migration_exists": to_bool(os.environ.get("MIGRATION_EXISTS", "")),
        "tables_exist": to_bool(os.environ.get("TABLES_EXIST", "")),
        "program_fk_verified": to_bool(os.environ.get("PROGRAM_FK_VERIFIED", "")),
        "authorize_for_update_lock_present": to_bool(os.environ.get("AUTHORIZE_LOCK_PRESENT", "")),
        "authorize_function_hardened": to_bool(os.environ.get("AUTHORIZE_HARDENED", "")),
        "scenario": {
            "program_escrow_id": os.environ.get("PROGRAM_ESCROW_ID", ""),
            "ceiling_amount_minor": 1000,
            "attempt_amount_minor": 100,
            "concurrency": 50,
            "ok_count": int(os.environ.get("OK_COUNT", "0") or "0"),
            "ceiling_reject_count": int(os.environ.get("CEILING_REJECT_COUNT", "0") or "0"),
            "other_error_count": int(os.environ.get("OTHER_ERROR_COUNT", "0") or "0"),
            "final_reserved_amount_minor": to_int_or_none(os.environ.get("FINAL_RESERVED", "")),
            "reservation_rows": to_int_or_none(os.environ.get("RESERVATION_ROWS", "")),
            "ceiling_enforced": to_bool(os.environ.get("CEILING_ENFORCED", "")),
        },
    },
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"wrote_evidence:{os.environ['EVIDENCE_FILE']}")
PY

if [[ ${#failures[@]} -gt 0 ]]; then
  EVIDENCE_FILE="$EVIDENCE_FILE" FAILURES_JSON="$(printf '%s\n' "${failures[@]}" | python3 -c 'import json,sys; print(json.dumps([ln.strip() for ln in sys.stdin if ln.strip()]))')" python3 - <<'PY'
import json
import os
from pathlib import Path

p = Path(os.environ["EVIDENCE_FILE"])
d = json.loads(p.read_text(encoding="utf-8"))
d["status"] = "FAIL"
d["pass"] = False
d["failures"] = json.loads(os.environ["FAILURES_JSON"])
p.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")
PY
  echo "escrow ceiling enforcement verification failed" >&2
  printf '%s\n' "${failures[@]}" >&2
  exit 1
fi

echo "escrow ceiling enforcement verification OK. Evidence: $EVIDENCE_FILE"

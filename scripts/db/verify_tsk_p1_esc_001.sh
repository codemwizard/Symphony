#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-ESC-001"
DEFAULT_EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json"
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

query_bool() {
  local sql="$1"
  local val
  val="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "$sql" | tr -d '[:space:]')"
  [[ "$val" == "t" ]] && echo "true" || echo "false"
}

expect_sqlstate() {
  local sql="$1"
  local expected="$2"
  local output
  set +e
  output="$(psql "$DATABASE_URL" -X -q --set=VERBOSITY=verbose -v ON_ERROR_STOP=1 -c "$sql" 2>&1)"
  local rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    add_failure "expected_sqlstate_not_raised:$expected"
    return
  fi
  if ! grep -Eq "(SQL state: ${expected}|${expected})" <<<"$output"; then
    add_failure "sqlstate_mismatch:expected_${expected}"
  fi
}

migration_exists="false"
if [[ -f "$ROOT_DIR/schema/migrations/0045_escrow_state_machine_atomic_reservation.sql" ]]; then
  migration_exists="true"
else
  add_failure "migration_missing:0045_escrow_state_machine_atomic_reservation.sql"
fi

tables_exist="$(query_bool "
SELECT to_regclass('public.escrow_accounts') IS NOT NULL
   AND to_regclass('public.escrow_events') IS NOT NULL;
")"
[[ "$tables_exist" == "true" ]] || add_failure "table_missing:escrow_accounts_or_escrow_events"

states_contract_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_constraint c
  JOIN pg_class t ON t.oid=c.conrelid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public'
    AND t.relname='escrow_accounts'
    AND c.contype='c'
    AND pg_get_constraintdef(c.oid) ILIKE '%CREATED%'
    AND pg_get_constraintdef(c.oid) ILIKE '%AUTHORIZED%'
    AND pg_get_constraintdef(c.oid) ILIKE '%RELEASE_REQUESTED%'
    AND pg_get_constraintdef(c.oid) ILIKE '%RELEASED%'
    AND pg_get_constraintdef(c.oid) ILIKE '%CANCELED%'
    AND pg_get_constraintdef(c.oid) ILIKE '%EXPIRED%'
);
")"
[[ "$states_contract_verified" == "true" ]] || add_failure "states_constraint_missing_or_invalid"

append_only_event_verified="$(query_bool "
SELECT EXISTS (
  SELECT 1
  FROM pg_trigger tg
  JOIN pg_class t ON t.oid=tg.tgrelid
  JOIN pg_proc p ON p.oid=tg.tgfoid
  JOIN pg_namespace n ON n.oid=t.relnamespace
  WHERE n.nspname='public'
    AND t.relname='escrow_events'
    AND tg.tgname='trg_deny_escrow_events_mutation'
    AND p.proname='deny_append_only_mutation'
);
")"
[[ "$append_only_event_verified" == "true" ]] || add_failure "escrow_events_append_only_trigger_missing"

transition_function_hardened="$(query_bool "
SELECT p.prosecdef
   AND EXISTS (
     SELECT 1
     FROM unnest(COALESCE(p.proconfig, ARRAY[]::text[])) cfg
     WHERE cfg = 'search_path=pg_catalog, public'
   )
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname='public'
  AND p.proname='transition_escrow_state'
LIMIT 1;
")"
[[ "$transition_function_hardened" == "true" ]] || add_failure "transition_function_not_hardened"

expire_function_hardened="$(query_bool "
SELECT p.prosecdef
   AND EXISTS (
     SELECT 1
     FROM unnest(COALESCE(p.proconfig, ARRAY[]::text[])) cfg
     WHERE cfg = 'search_path=pg_catalog, public'
   )
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname='public'
  AND p.proname='expire_escrows'
LIMIT 1;
")"
[[ "$expire_function_hardened" == "true" ]] || add_failure "expire_function_not_hardened"

release_function_hardened="$(query_bool "
SELECT p.prosecdef
   AND EXISTS (
     SELECT 1
     FROM unnest(COALESCE(p.proconfig, ARRAY[]::text[])) cfg
     WHERE cfg = 'search_path=pg_catalog, public'
   )
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname='public'
  AND p.proname='release_escrow'
LIMIT 1;
")"
[[ "$release_function_hardened" == "true" ]] || add_failure "release_function_not_hardened"

tenant_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT tenant_id::text FROM public.tenants ORDER BY created_at LIMIT 1;" | tr -d '[:space:]')"
if [[ -z "$tenant_id" ]]; then
  add_failure "prereq_missing:public.tenants seed row required"
fi

legal_transitions_verified="false"
illegal_transition_rejected="false"
expiry_reachable_from_created="false"
expiry_reachable_from_authorized="false"
release_semantics_verified="false"
stable_sqlstates_verified="false"

if [[ ${#failures[@]} -eq 0 ]]; then
  created_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
INSERT INTO public.escrow_accounts(
  tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at, release_due_at
) VALUES (
  '$tenant_id', public.uuid_v7_or_random(), 'ENTITY-A', 'CREATED', 10000, 'ZMW', NOW() + interval '20 minutes', NOW() + interval '40 minutes'
)
RETURNING escrow_id::text;
" | tr -d '[:space:]')"

  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c \
    "SELECT new_state FROM public.transition_escrow_state('$created_id'::uuid, 'AUTHORIZED', 'verifier', 'legal_transition', '{}'::jsonb, NOW());" >/dev/null

  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c \
    "SELECT new_state FROM public.transition_escrow_state('$created_id'::uuid, 'RELEASE_REQUESTED', 'verifier', 'request_release', '{}'::jsonb, NOW());" >/dev/null

  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c \
    "SELECT public.release_escrow('$created_id'::uuid, 'verifier', 'release_ok', '{}'::jsonb);" >/dev/null

  released_state="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT state FROM public.escrow_accounts WHERE escrow_id='$created_id'::uuid;" | tr -d '[:space:]')"
  released_event_count="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT COUNT(*)::text FROM public.escrow_events WHERE escrow_id='$created_id'::uuid AND event_type='RELEASED';" | tr -d '[:space:]')"

  if [[ "$released_state" == "RELEASED" && "$released_event_count" =~ ^[1-9][0-9]*$ ]]; then
    release_semantics_verified="true"
  else
    add_failure "release_semantics_invalid"
  fi

  created_expirable_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
INSERT INTO public.escrow_accounts(
  tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at
) VALUES (
  '$tenant_id', public.uuid_v7_or_random(), 'ENTITY-B', 'CREATED', 20000, 'ZMW', NOW() - interval '2 minutes'
)
RETURNING escrow_id::text;
" | tr -d '[:space:]')"

  authorized_expirable_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
INSERT INTO public.escrow_accounts(
  tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at
) VALUES (
  '$tenant_id', public.uuid_v7_or_random(), 'ENTITY-C', 'CREATED', 30000, 'ZMW', NOW() + interval '10 minutes'
)
RETURNING escrow_id::text;
" | tr -d '[:space:]')"

  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c \
    "SELECT new_state FROM public.transition_escrow_state('$authorized_expirable_id'::uuid, 'AUTHORIZED', 'verifier', 'authorized', '{}'::jsonb, NOW());" >/dev/null
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c \
    "UPDATE public.escrow_accounts SET authorization_expires_at = NOW() - interval '1 minute' WHERE escrow_id='$authorized_expirable_id'::uuid;" >/dev/null

  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT public.expire_escrows(NOW(), 'expiry_worker');" >/dev/null

  created_expired_state="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT state FROM public.escrow_accounts WHERE escrow_id='$created_expirable_id'::uuid;" | tr -d '[:space:]')"
  authorized_expired_state="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "SELECT state FROM public.escrow_accounts WHERE escrow_id='$authorized_expirable_id'::uuid;" | tr -d '[:space:]')"
  [[ "$created_expired_state" == "EXPIRED" ]] && expiry_reachable_from_created="true" || add_failure "expiry_not_reachable_from_created"
  [[ "$authorized_expired_state" == "EXPIRED" ]] && expiry_reachable_from_authorized="true" || add_failure "expiry_not_reachable_from_authorized"

  created_illegal_id="$(psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X -c "
INSERT INTO public.escrow_accounts(
  tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code
) VALUES (
  '$tenant_id', public.uuid_v7_or_random(), 'ENTITY-D', 'CREATED', 12000, 'ZMW'
)
RETURNING escrow_id::text;
" | tr -d '[:space:]')"

  expect_sqlstate "SELECT * FROM public.transition_escrow_state('$created_illegal_id'::uuid, 'RELEASED', 'verifier', 'illegal', '{}'::jsonb, NOW());" "P7303"
  expect_sqlstate "SELECT * FROM public.transition_escrow_state('$created_id'::uuid, 'AUTHORIZED', 'verifier', 'terminal_illegal', '{}'::jsonb, NOW());" "P7303"

  if [[ ${#failures[@]} -eq 0 ]]; then
    legal_transitions_verified="true"
    illegal_transition_rejected="true"
    stable_sqlstates_verified="true"
  fi
fi

EVIDENCE_FILE="$EVIDENCE_FILE" TASK_ID="$TASK_ID" MIGRATION_EXISTS="$migration_exists" TABLES_EXIST="$tables_exist" \
STATES_CONTRACT_VERIFIED="$states_contract_verified" APPEND_ONLY_EVENT_VERIFIED="$append_only_event_verified" \
TRANSITION_FUNCTION_HARDENED="$transition_function_hardened" EXPIRE_FUNCTION_HARDENED="$expire_function_hardened" \
RELEASE_FUNCTION_HARDENED="$release_function_hardened" LEGAL_TRANSITIONS_VERIFIED="$legal_transitions_verified" \
ILLEGAL_TRANSITION_REJECTED="$illegal_transition_rejected" EXPIRY_REACHABLE_FROM_CREATED="$expiry_reachable_from_created" \
EXPIRY_REACHABLE_FROM_AUTHORIZED="$expiry_reachable_from_authorized" RELEASE_SEMANTICS_VERIFIED="$release_semantics_verified" \
STABLE_SQLSTATES_VERIFIED="$stable_sqlstates_verified" python3 - <<'PY'
import json
import os
from pathlib import Path


def to_bool(val: str) -> bool:
    return str(val).strip().lower() in {"1", "true", "t", "yes", "y"}


payload = {
    "task_id": os.environ["TASK_ID"],
    "check_id": "TSK-P1-ESC-001",
    "timestamp_utc": os.environ["EVIDENCE_TS"],
    "git_sha": os.environ["EVIDENCE_GIT_SHA"],
    "schema_fingerprint": os.environ["EVIDENCE_SCHEMA_FP"],
    "status": "PASS",
    "pass": True,
    "details": {
        "migration_exists": to_bool(os.environ["MIGRATION_EXISTS"]),
        "tables_exist": to_bool(os.environ["TABLES_EXIST"]),
        "states_contract_verified": to_bool(os.environ["STATES_CONTRACT_VERIFIED"]),
        "append_only_event_verified": to_bool(os.environ["APPEND_ONLY_EVENT_VERIFIED"]),
        "transition_function_hardened": to_bool(os.environ["TRANSITION_FUNCTION_HARDENED"]),
        "expire_function_hardened": to_bool(os.environ["EXPIRE_FUNCTION_HARDENED"]),
        "release_function_hardened": to_bool(os.environ["RELEASE_FUNCTION_HARDENED"]),
        "legal_transitions_verified": to_bool(os.environ["LEGAL_TRANSITIONS_VERIFIED"]),
        "illegal_transition_rejected": to_bool(os.environ["ILLEGAL_TRANSITION_REJECTED"]),
        "expiry_reachable_from_created": to_bool(os.environ["EXPIRY_REACHABLE_FROM_CREATED"]),
        "expiry_reachable_from_authorized": to_bool(os.environ["EXPIRY_REACHABLE_FROM_AUTHORIZED"]),
        "release_semantics_verified": to_bool(os.environ["RELEASE_SEMANTICS_VERIFIED"]),
        "stable_sqlstates_verified": to_bool(os.environ["STABLE_SQLSTATES_VERIFIED"]),
    },
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
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
  printf '%s\n' "${failures[@]}" >&2
  echo "escrow state model verification failed" >&2
  exit 1
fi

echo "escrow state model verification OK. Evidence: $EVIDENCE_FILE"


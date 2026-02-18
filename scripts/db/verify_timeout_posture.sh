#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/db_timeout_posture.json"
mkdir -p "$EVIDENCE_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

# Bounded defaults; override via env when needed.
LOCK_TIMEOUT_MAX_MS="${LOCK_TIMEOUT_MAX_MS:-2000}"
STATEMENT_TIMEOUT_MAX_MS="${STATEMENT_TIMEOUT_MAX_MS:-30000}"
IDLE_IN_TX_TIMEOUT_MAX_MS="${IDLE_IN_TX_TIMEOUT_MAX_MS:-60000}"
DEADLOCK_TIMEOUT_MAX_MS="${DEADLOCK_TIMEOUT_MAX_MS:-5000}"
CHECK_DEADLOCK_TIMEOUT="${CHECK_DEADLOCK_TIMEOUT:-0}"

STATUS="FAIL"
ERROR=""
VALUES_JSON='{}'
OBSERVED_LOCK_MS=""
OBSERVED_STATEMENT_MS=""
OBSERVED_IDLE_MS=""
OBSERVED_DEADLOCK_MS=""

if VALUES_JSON="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 <<'SQL'
SELECT json_build_object(
  'lock_timeout_ms', (SELECT setting::bigint FROM pg_settings WHERE name = 'lock_timeout'),
  'statement_timeout_ms', (SELECT setting::bigint FROM pg_settings WHERE name = 'statement_timeout'),
  'idle_in_transaction_session_timeout_ms', (SELECT setting::bigint FROM pg_settings WHERE name = 'idle_in_transaction_session_timeout'),
  'deadlock_timeout_ms', (SELECT setting::bigint FROM pg_settings WHERE name = 'deadlock_timeout')
)::text;
SQL
)"
then
  psql_rc=0
else
  psql_rc=$?
fi

if [[ $psql_rc -ne 0 || -z "$VALUES_JSON" ]]; then
  ERROR="psql_query_failed"
else
  read -r OBSERVED_LOCK_MS OBSERVED_STATEMENT_MS OBSERVED_IDLE_MS OBSERVED_DEADLOCK_MS < <(
    VALUES_JSON="$VALUES_JSON" python3 - <<'PY'
import json
import os

raw = os.environ.get("VALUES_JSON", "{}")
obj = json.loads(raw)
vals = [
    obj.get("lock_timeout_ms"),
    obj.get("statement_timeout_ms"),
    obj.get("idle_in_transaction_session_timeout_ms"),
    obj.get("deadlock_timeout_ms"),
]
print(" ".join("" if v is None else str(v) for v in vals))
PY
  )

  fail_reason=""

  if [[ -z "$OBSERVED_LOCK_MS" || "$OBSERVED_LOCK_MS" -le 0 || "$OBSERVED_LOCK_MS" -gt "$LOCK_TIMEOUT_MAX_MS" ]]; then
    fail_reason="lock_timeout_out_of_bounds"
  fi

  if [[ -z "$OBSERVED_STATEMENT_MS" || "$OBSERVED_STATEMENT_MS" -le 0 || "$OBSERVED_STATEMENT_MS" -gt "$STATEMENT_TIMEOUT_MAX_MS" ]]; then
    if [[ -n "$fail_reason" ]]; then
      fail_reason+=";"
    fi
    fail_reason+="statement_timeout_out_of_bounds"
  fi

  if [[ -z "$OBSERVED_IDLE_MS" || "$OBSERVED_IDLE_MS" -le 0 || "$OBSERVED_IDLE_MS" -gt "$IDLE_IN_TX_TIMEOUT_MAX_MS" ]]; then
    if [[ -n "$fail_reason" ]]; then
      fail_reason+=";"
    fi
    fail_reason+="idle_in_transaction_session_timeout_out_of_bounds"
  fi

  if [[ "$CHECK_DEADLOCK_TIMEOUT" == "1" ]]; then
    if [[ -z "$OBSERVED_DEADLOCK_MS" || "$OBSERVED_DEADLOCK_MS" -le 0 || "$OBSERVED_DEADLOCK_MS" -gt "$DEADLOCK_TIMEOUT_MAX_MS" ]]; then
      if [[ -n "$fail_reason" ]]; then
        fail_reason+=";"
      fi
      fail_reason+="deadlock_timeout_out_of_bounds"
    fi
  fi

  if [[ -z "$fail_reason" ]]; then
    STATUS="PASS"
  else
    ERROR="$fail_reason"
  fi
fi

STATUS="$STATUS" ERROR="$ERROR" VALUES_JSON="$VALUES_JSON" EVIDENCE_FILE="$EVIDENCE_FILE" \
LOCK_TIMEOUT_MAX_MS="$LOCK_TIMEOUT_MAX_MS" STATEMENT_TIMEOUT_MAX_MS="$STATEMENT_TIMEOUT_MAX_MS" \
IDLE_IN_TX_TIMEOUT_MAX_MS="$IDLE_IN_TX_TIMEOUT_MAX_MS" DEADLOCK_TIMEOUT_MAX_MS="$DEADLOCK_TIMEOUT_MAX_MS" \
CHECK_DEADLOCK_TIMEOUT="$CHECK_DEADLOCK_TIMEOUT" python3 - <<'PY'
import json
import os
from pathlib import Path

values_raw = os.environ.get("VALUES_JSON", "{}")
try:
    observed = json.loads(values_raw)
except Exception:
    observed = {}

out = {
    "check_id": "DB-TIMEOUT-POSTURE",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": os.environ.get("STATUS", "FAIL"),
    "policy": {
        "lock_timeout_max_ms": int(os.environ.get("LOCK_TIMEOUT_MAX_MS", "2000")),
        "statement_timeout_max_ms": int(os.environ.get("STATEMENT_TIMEOUT_MAX_MS", "30000")),
        "idle_in_transaction_session_timeout_max_ms": int(os.environ.get("IDLE_IN_TX_TIMEOUT_MAX_MS", "60000")),
        "check_deadlock_timeout": os.environ.get("CHECK_DEADLOCK_TIMEOUT", "0") == "1",
        "deadlock_timeout_max_ms": int(os.environ.get("DEADLOCK_TIMEOUT_MAX_MS", "5000")),
    },
    "observed": observed,
    "error": os.environ.get("ERROR", ""),
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if [[ "$STATUS" != "PASS" ]]; then
  echo "❌ DB timeout posture verification failed: $ERROR" >&2
  exit 1
fi

echo "✅ DB timeout posture verification passed"

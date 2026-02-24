#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_FILE="${1:-}"
if [[ "${1:-}" == "--evidence" ]]; then
  OUT_FILE="${2:-}"
fi
if [[ -z "$OUT_FILE" ]]; then
  OUT_FILE="evidence/phase0/tsk_p0_102__enforce_file_evidence_dev_only_fail.json"
fi
[[ "$OUT_FILE" = /* ]] || OUT_FILE="$ROOT_DIR/$OUT_FILE"

status="PASS"
errors=()

if ! rg -n "ensure_evidence_write_allowed" "$ROOT_DIR/scripts/lib/evidence.sh" >/dev/null 2>&1; then
  status="FAIL"
  errors+=("missing_guard_function:scripts/lib/evidence.sh")
fi

test_write() {
  local env_name="$1"
  local target="$2"
  local expect_ok="$3"
  local log_file
  log_file="$(mktemp)"

  if SYMPHONY_ENV="$env_name" bash -lc "source '$ROOT_DIR/scripts/lib/evidence.sh'; write_json '$target' '\"check_id\":\"TEST\"' '\"timestamp_utc\":\"1970-01-01T00:00:00Z\"' '\"git_sha\":\"deadbeef\"' '\"status\":\"PASS\"'" >"$log_file" 2>&1; then
    if [[ "$expect_ok" != "1" ]]; then
      status="FAIL"
      errors+=("expected_fail_but_passed:$env_name")
    fi
  else
    if [[ "$expect_ok" == "1" ]]; then
      status="FAIL"
      errors+=("expected_pass_but_failed:$env_name")
    else
      if ! rg -n "EVIDENCE_WRITE_FORBIDDEN_IN_ENV:${env_name}" "$log_file" >/dev/null 2>&1; then
        status="FAIL"
        errors+=("missing_fail_closed_message:$env_name")
      fi
    fi
  fi
  rm -f "$log_file" "$target"
}

tmp_dev="$ROOT_DIR/evidence/phase0/.tsk_p0_102_dev.json"
tmp_ci="$ROOT_DIR/evidence/phase0/.tsk_p0_102_ci.json"
tmp_prod="$ROOT_DIR/evidence/phase0/.tsk_p0_102_prod.json"

test_write "development" "$tmp_dev" "1"
test_write "ci" "$tmp_ci" "1"
test_write "production" "$tmp_prod" "0"

ERRORS_JOINED=""
if (( ${#errors[@]} > 0 )); then
  ERRORS_JOINED="$(printf '%s\n' "${errors[@]}")"
fi

ERRORS_JOINED="$ERRORS_JOINED" python3 - <<PY
import json
import os
from pathlib import Path
from datetime import datetime, timezone

out = Path(r"$OUT_FILE")
out.parent.mkdir(parents=True, exist_ok=True)
status = "$status"
error_list = [e for e in os.environ.get("ERRORS_JOINED", "").splitlines() if e]
payload = {
    "check_id": "TSK-P0-102-VERIFY",
    "task_id": "TSK-P0-102",
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": "UNKNOWN",
    "status": status,
    "pass": status == "PASS",
    "details": {
        "allowed_envs": ["development", "ci"],
        "denied_envs": ["production"],
        "errors": error_list
    }
}
try:
    import subprocess
    payload["git_sha"] = subprocess.check_output(["git", "-C", r"$ROOT_DIR", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    pass
out.write_text(json.dumps(payload, indent=2) + "\\n", encoding="utf-8")
print(f"TSK-P0-102 verifier status: {status}")
print(f"Evidence: {out}")
if status != "PASS":
    raise SystemExit(1)
PY

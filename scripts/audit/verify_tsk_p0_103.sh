#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_FILE="${1:-}"
if [[ "${1:-}" == "--evidence" ]]; then
  OUT_FILE="${2:-}"
fi
if [[ -z "$OUT_FILE" ]]; then
  OUT_FILE="evidence/phase0/tsk_p0_103__single_payload_materialization.json"
fi
[[ "$OUT_FILE" = /* ]] || OUT_FILE="$ROOT_DIR/$OUT_FILE"

status="PASS"
errors=()

if ! rg -n "validate_evidence_json\\.sh" "$ROOT_DIR/scripts/audit/run_phase0_ordered_checks.sh" >/dev/null 2>&1; then
  status="FAIL"
  errors+=("ordered_checks_not_wired:validate_evidence_json.sh")
fi

tmp_root="$(mktemp -d)"
mkdir -p "$tmp_root/evidence/phase0" "$tmp_root/evidence/phase1"

cat > "$tmp_root/evidence/phase0/valid.json" <<'JSON'
{
  "check_id": "TEST-VALID",
  "task_id": "TEST",
  "timestamp_utc": "2026-02-24T00:00:00Z",
  "git_sha": "deadbeef",
  "status": "PASS",
  "inputs": {},
  "outputs": {},
  "measurement_truth": {}
}
JSON

cat > "$tmp_root/evidence/phase1/invalid_extra.json" <<'JSON'
{
  "check_id": "TEST-INVALID",
  "task_id": "TEST",
  "timestamp_utc": "2026-02-24T00:00:00Z",
  "git_sha": "deadbeef",
  "status": "PASS",
  "forbidden_key": true
}
JSON

if SYMPHONY_ENV=development "$ROOT_DIR/scripts/audit/validate_evidence_json.sh" \
  --phase0-dir "$tmp_root/evidence/phase0" \
  --phase1-dir "$tmp_root/evidence/phase1" \
  --strict \
  --evidence "$tmp_root/report_strict.json" >/dev/null 2>&1; then
  status="FAIL"
  errors+=("strict_mode_expected_fail_on_unknown_fields")
fi

rm -f "$tmp_root/evidence/phase1/invalid_extra.json"
if ! SYMPHONY_ENV=development "$ROOT_DIR/scripts/audit/validate_evidence_json.sh" \
  --phase0-dir "$tmp_root/evidence/phase0" \
  --phase1-dir "$tmp_root/evidence/phase1" \
  --strict \
  --evidence "$tmp_root/report_pass.json" >/dev/null 2>&1; then
  status="FAIL"
  errors+=("strict_mode_expected_pass_on_valid_payload")
fi

rm -rf "$tmp_root"

ERRORS_JOINED=""
if (( ${#errors[@]} > 0 )); then
  ERRORS_JOINED="$(printf '%s\n' "${errors[@]}")"
fi

ERRORS_JOINED="$ERRORS_JOINED" python3 - <<PY
import json
import os
from datetime import datetime, timezone
from pathlib import Path
import subprocess

status = "$status"
error_list = [e for e in os.environ.get("ERRORS_JOINED", "").splitlines() if e]
out = {
    "check_id": "TSK-P0-103-VERIFY",
    "task_id": "TSK-P0-103",
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": "UNKNOWN",
    "status": status,
    "pass": status == "PASS",
    "details": {
        "validator_script": "scripts/audit/validate_evidence_json.sh",
        "strict_mode_checked": True,
        "ordered_checks_wired": not any(e.startswith("ordered_checks_not_wired") for e in error_list),
        "errors": error_list
    }
}
try:
    out["git_sha"] = subprocess.check_output(["git", "-C", r"$ROOT_DIR", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    pass

target = Path(r"$OUT_FILE")
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(out, indent=2) + "\\n", encoding="utf-8")
print(f"TSK-P0-103 verifier status: {status}")
print(f"Evidence: {target}")
if status != "PASS":
    raise SystemExit(1)
PY


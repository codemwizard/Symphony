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

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"

status="PASS"
errors=()

BASELINE_FILE="$ROOT_DIR/docs/operations/perf_smoke_baseline.json"
RUNNER_FILE="$ROOT_DIR/scripts/audit/run_perf_smoke.sh"

if [[ ! -f "$BASELINE_FILE" ]]; then
  status="FAIL"
  errors+=("missing_baseline_file:docs/operations/perf_smoke_baseline.json")
fi

if [[ ! -f "$RUNNER_FILE" ]]; then
  status="FAIL"
  errors+=("missing_runner_file:scripts/audit/run_perf_smoke.sh")
fi

if [[ "$status" == "PASS" ]]; then
  python3 - <<PY || status="FAIL"
import json, pathlib, re, sys
base = pathlib.Path(r"$BASELINE_FILE")
runner = pathlib.Path(r"$RUNNER_FILE")
errors = []
cfg = json.loads(base.read_text())
if cfg.get("baseline_locked") is not True:
    errors.append("baseline_locked_not_true")
p95 = cfg.get("p95_ms")
if not isinstance(p95, (int, float)) or p95 <= 0:
    errors.append("invalid_baseline_p95")
text = runner.read_text(encoding="utf-8")
if '"mode": "informational"' in text:
    errors.append("informational_mode_string_present")
if 'baseline_not_locked' not in text:
    errors.append("missing_fail_closed_guard_baseline_not_locked")
if errors:
    print(";".join(errors))
    sys.exit(1)
PY
  if [[ "$status" == "FAIL" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && errors+=("$line")
    done < <(python3 - <<PY
import json, pathlib
errs=[]
cfg=json.loads(pathlib.Path(r"$BASELINE_FILE").read_text())
if cfg.get("baseline_locked") is not True:
    errs.append("baseline_locked_not_true")
p95=cfg.get("p95_ms")
if not isinstance(p95,(int,float)) or p95 <= 0:
    errs.append("invalid_baseline_p95")
text=pathlib.Path(r"$RUNNER_FILE").read_text(encoding='utf-8')
if '"mode": "informational"' in text:
    errs.append("informational_mode_string_present")
if 'baseline_not_locked' not in text:
    errs.append("missing_fail_closed_guard_baseline_not_locked")
print("\n".join(errs))
PY
)
  fi
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  errors_json="$(printf '%s\n' "${errors[@]}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
else
  errors_json="[]"
fi

pass_value=False
if [[ "$status" == "PASS" ]]; then
  pass_value=True
fi

python3 - <<PY
import json
from pathlib import Path
p=Path(r"$ROOT_DIR/$EVIDENCE_PATH")
out={
  "check_id":"TSK-CLEAN-002",
  "task_id":"TSK-CLEAN-002",
  "timestamp_utc":"$EVIDENCE_TS",
  "git_sha":"$EVIDENCE_GIT_SHA",
  "schema_fingerprint":"$EVIDENCE_SCHEMA_FP",
  "status":"$status",
  "pass": $pass_value,
  "details":{
    "baseline_file":"docs/operations/perf_smoke_baseline.json",
    "runner_file":"scripts/audit/run_perf_smoke.sh",
    "errors": json.loads('''$errors_json''')
  }
}
p.write_text(json.dumps(out, indent=2)+"\n", encoding="utf-8")
print(f"TSK-CLEAN-002 verifier status: {out['status']}")
print(f"Evidence: {p}")
raise SystemExit(0 if out["status"]=="PASS" else 1)
PY

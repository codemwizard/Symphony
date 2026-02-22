#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"; shift 2 ;;
    *)
      echo "Unknown argument: $1" >&2; exit 2 ;;
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

if [[ ! -x "$ROOT_DIR/scripts/audit/run_phase0_ordered_checks.sh" ]]; then
  status="FAIL"
  errors+=("missing_runner:scripts/audit/run_phase0_ordered_checks.sh")
fi

if ! grep -Fq 'scripts/audit/run_phase0_ordered_checks.sh' "$ROOT_DIR/scripts/dev/pre_ci.sh"; then
  status="FAIL"
  errors+=("pre_ci_missing_ordered_checks_invocation")
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
  "check_id":"TSK-P0-101",
  "task_id":"TSK-P0-101",
  "timestamp_utc":"$EVIDENCE_TS",
  "git_sha":"$EVIDENCE_GIT_SHA",
  "schema_fingerprint":"$EVIDENCE_SCHEMA_FP",
  "status":"$status",
  "pass": $pass_value,
  "details":{
    "ordered_checks_runner": "scripts/audit/run_phase0_ordered_checks.sh",
    "pre_ci_wired": $pass_value,
    "errors": json.loads('''$errors_json''')
  }
}
p.write_text(json.dumps(out, indent=2)+"\n", encoding="utf-8")
print(f"TSK-P0-101 verifier status: {out['status']}")
print(f"Evidence: {p}")
raise SystemExit(0 if out["status"]=="PASS" else 1)
PY

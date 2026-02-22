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

# Guard against behavior regressions: require executable invocation lines, not just mentions.
require_invocation_line() {
  local regex="$1"
  local tag="$2"
  if ! grep -Eq "$regex" "$ROOT_DIR/scripts/dev/pre_ci.sh"; then
    status="FAIL"
    errors+=("missing_pre_ci_gate_invocation:$tag")
  fi
}

require_invocation_line '^ *scripts/audit/verify_task_plans_present\.sh *$' 'verify_task_plans_present'
require_invocation_line '^ *scripts/audit/verify_tsk_clean_001\.sh +--evidence +evidence/phase0/tsk_clean_001__task_metadata_truth_pass\.json *$' 'verify_tsk_clean_001'
require_invocation_line '^ *scripts/audit/verify_tsk_clean_002\.sh +--evidence +evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere\.json *$' 'verify_tsk_clean_002'
require_invocation_line '^ *scripts/audit/verify_phase0_parity\.sh *$' 'verify_phase0_parity'
require_invocation_line '^ *scripts/audit/verify_phase1_closeout\.sh *$' 'verify_phase1_closeout'

audit_lib_present=true
if [[ ! -d "$ROOT_DIR/scripts/audit/lib" ]]; then
  audit_lib_present=false
  status="FAIL"
  errors+=("missing_modular_library_dir:scripts/audit/lib")
fi

audit_lib_value=False
if [[ "$audit_lib_present" == "true" ]]; then
  audit_lib_value=True
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
  "check_id":"TSK-P1-059",
  "task_id":"TSK-P1-059",
  "timestamp_utc":"$EVIDENCE_TS",
  "git_sha":"$EVIDENCE_GIT_SHA",
  "schema_fingerprint":"$EVIDENCE_SCHEMA_FP",
  "status":"$status",
  "pass": $pass_value,
  "details":{
    "pre_ci_guardrails_checked": 5,
    "audit_lib_present": $audit_lib_value,
    "errors": json.loads('''$errors_json''')
  }
}
p.write_text(json.dumps(out, indent=2)+"\n", encoding="utf-8")
print(f"TSK-P1-059 verifier status: {out['status']}")
print(f"Evidence: {p}")
raise SystemExit(0 if out["status"]=="PASS" else 1)
PY

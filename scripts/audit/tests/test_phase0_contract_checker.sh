#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

SCRIPT="scripts/audit/verify_phase0_contract_evidence_status.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "Required script missing or not executable: $SCRIPT" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

assert_status() {
  local file="$1"
  local expected="$2"
  python3 - <<'PY' "$file" "$expected"
import json,sys
p=sys.argv[1]
exp=sys.argv[2]
data=json.load(open(p))
act=data.get("status")
if act!=exp:
    raise SystemExit(f"Expected status {exp}, got {act} in {p}")
PY
}

assert_error_contains() {
  local file="$1"
  local needle="$2"
  python3 - <<'PY' "$file" "$needle"
import json,sys
p=sys.argv[1]
needle=sys.argv[2]
data=json.load(open(p))
errs=data.get("errors") or []
if not any(needle in str(e) for e in errs):
    raise SystemExit(f"Expected error containing '{needle}' in {p}")
PY
}

run_case() {
  local name="$1"
  local contract_content="$2"
  local make_cp="$3"
  local expect_exit="$4"
  local expect_status="$5"
  local expect_error="$6"

  local case_dir="$tmp_dir/$name"
  mkdir -p "$case_dir/evidence/phase0"
  local contract_path="$case_dir/phase0_contract.yml"
  local cp_path="$case_dir/CONTROL_PLANES.yml"
  local evidence_file="$case_dir/evidence/phase0/phase0_contract_evidence_status.json"

  printf "%b" "$contract_content" > "$contract_path"

  if [[ "$make_cp" == "yes" ]]; then
    cat <<'CPY' > "$cp_path"
control_planes:
  INTEGRITY:
    required_gates:
      - gate_id: INT-G01
        evidence: evidence/phase0/test_gate.json
CPY
    # Evidence file for gate
    cat <<'EJ' > "$case_dir/evidence/phase0/test_gate.json"
{
  "check_id": "INT-G01",
  "timestamp_utc": "1970-01-01T00:00:00Z",
  "git_sha": "deadbeef",
  "status": "PASS"
}
EJ
  fi

  set +e
  CONTRACT_PATH="$contract_path" \
  CONTROL_PLANES_PATH="$cp_path" \
  EVIDENCE_DIR="$case_dir/evidence/phase0" \
  EVIDENCE_FILE="$evidence_file" \
  EVIDENCE_ROOT="$case_dir/evidence/phase0" \
  CI_ONLY=1 \
  "$SCRIPT"
  rc=$?
  set -e

  if [[ "$expect_exit" == "0" && "$rc" -ne 0 ]]; then
    echo "Case '$name' failed: expected exit 0, got $rc" >&2
    exit 1
  fi
  if [[ "$expect_exit" != "0" && "$rc" -eq 0 ]]; then
    echo "Case '$name' failed: expected non-zero exit, got 0" >&2
    exit 1
  fi

  assert_status "$evidence_file" "$expect_status"
  if [[ -n "$expect_error" ]]; then
    assert_error_contains "$evidence_file" "$expect_error"
  fi

  echo "[ok] $name"
}

# 1) No gate_ids, no control planes -> SKIPPED, exit 0
run_case "no_gateids_no_cp" \
"- task_id: TSK-P0-TEST\n  status: planned\n  verification_mode: both\n  gate_ids: []\n" \
"no" \
"0" \
"SKIPPED" \
"control_planes_missing_no_gate_ids"

# 2) gate_ids present, no control planes -> FAIL, exit non-zero
run_case "gateids_no_cp" \
"- task_id: TSK-P0-TEST\n  status: planned\n  verification_mode: both\n  gate_ids: [INT-G01]\n" \
"no" \
"1" \
"FAIL" \
"control_planes_missing"

# 3) invalid YAML -> FAIL, exit non-zero
run_case "invalid_yaml" \
"::::" \
"no" \
"1" \
"FAIL" \
"contract_not_list"

# 4) gate_ids + control planes + PASS evidence -> PASS, exit 0
run_case "gateids_with_cp" \
"- task_id: TSK-P0-TEST\n  status: completed\n  verification_mode: both\n  gate_ids: [INT-G01]\n" \
"yes" \
"0" \
"PASS" \
""

echo "All contract checker tests passed."

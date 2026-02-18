#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

SCRIPT="scripts/audit/verify_phase1_contract.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "Required script missing: $SCRIPT" >&2
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

make_schema() {
  local path="$1"
  cat > "$path" <<'JSON'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["check_id", "timestamp_utc", "git_sha", "status"],
  "properties": {
    "check_id": {"type": "string"},
    "timestamp_utc": {"type": "string"},
    "git_sha": {"type": "string"},
    "status": {"type": "string", "enum": ["PASS", "FAIL", "SKIPPED"]}
  },
  "additionalProperties": true
}
JSON
}

make_approval_schema() {
  local path="$1"
  cat > "$path" <<'JSON'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["schema_version", "generated_at_utc", "git_commit", "change_scope", "ai", "human_approval"],
  "properties": {
    "schema_version": { "type": "string" },
    "generated_at_utc": { "type": "string" },
    "git_commit": { "type": "string" },
    "change_scope": { "type": "object" },
    "ai": { "type": "object" },
    "human_approval": { "type": "object" }
  },
  "additionalProperties": true
}
JSON
}

make_cp() {
  local path="$1"
  cat > "$path" <<'YAML'
control_planes:
  integrity:
    required_gates:
      - gate_id: INT-G28
        script: scripts/audit/verify_phase1_contract.sh
        evidence: evidence/phase1/phase1_contract_status.json
  security:
    required_gates:
      - gate_id: SEC-G17
        script: scripts/audit/lint_pii_leakage_payloads.sh
        evidence: evidence/phase0/pii_leakage_payloads.json
YAML
}

make_min_phase0_evidence() {
  local path="$1"
  cat > "$path" <<'JSON'
{
  "check_id": "SEC-G17",
  "timestamp_utc": "1970-01-01T00:00:00Z",
  "git_sha": "deadbeef",
  "status": "PASS"
}
JSON
}

make_min_phase1_evidence() {
  local path="$1"
  cat > "$path" <<'JSON'
{
  "check_id": "INT-G28",
  "timestamp_utc": "1970-01-01T00:00:00Z",
  "git_sha": "deadbeef",
  "status": "PASS"
}
JSON
}

run_case() {
  local name="$1"
  local contract_content="$2"
  local run_phase1="$3"
  local include_phase1_evidence="$4"
  local expect_exit="$5"
  local expect_status="$6"
  local expect_error="$7"

  local case_dir="$tmp_dir/$name"
  mkdir -p "$case_dir/evidence/phase0" "$case_dir/evidence/phase1"
  local contract_path="$case_dir/phase1_contract.yml"
  local cp_path="$case_dir/CONTROL_PLANES.yml"
  local schema_path="$case_dir/evidence_schema.json"
  local evidence_out="$case_dir/evidence/phase1/phase1_contract_status.json"
  local approval_schema_path="$case_dir/approval_metadata.schema.json"

  printf "%b" "$contract_content" > "$contract_path"
  make_cp "$cp_path"
  make_schema "$schema_path"
  make_approval_schema "$approval_schema_path"
  make_min_phase0_evidence "$case_dir/evidence/phase0/pii_leakage_payloads.json"
  if [[ "$include_phase1_evidence" == "yes" ]]; then
    make_min_phase1_evidence "$case_dir/evidence/phase1/phase1_contract_status_seed.json"
  fi

  set +e
  ROOT_DIR="$case_dir" \
  CONTRACT_FILE="$contract_path" \
  CP_FILE="$cp_path" \
  SCHEMA_FILE="$schema_path" \
  APPROVAL_SCHEMA_FILE="$approval_schema_path" \
  EVIDENCE_DIR="$case_dir/evidence/phase1" \
  EVIDENCE_FILE="$evidence_out" \
  RUN_PHASE1_GATES="$run_phase1" \
  bash "$SCRIPT"
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

  assert_status "$evidence_out" "$expect_status"
  if [[ -n "$expect_error" ]]; then
    assert_error_contains "$evidence_out" "$expect_error"
  fi

  echo "[ok] $name"
}

# 1) Phase-1 gates off: required row with missing phase1 evidence is skipped and passes.
run_case "phase1_off_skips_required" \
"- invariant_id: INV-111\n  status: phase0_prerequisite\n  required: true\n  gate_id: SEC-G17\n  verifier: scripts/audit/lint_pii_leakage_payloads.sh\n  evidence_path: evidence/phase0/pii_leakage_payloads.json\n- invariant_id: INV-114\n  status: implemented\n  required: true\n  gate_id: INT-G28\n  verifier: scripts/audit/verify_phase1_contract.sh\n  evidence_path: evidence/phase1/phase1_contract_status_seed.json\n" \
"0" \
"no" \
"0" \
"PASS" \
""

# 2) Phase-1 gates on: required row missing evidence must fail closed.
run_case "phase1_on_missing_required_evidence" \
"- invariant_id: INV-114\n  status: implemented\n  required: true\n  gate_id: INT-G28\n  verifier: scripts/audit/verify_phase1_contract.sh\n  evidence_path: evidence/phase1/phase1_contract_status_seed.json\n" \
"1" \
"no" \
"1" \
"FAIL" \
"missing_evidence"

# 3) Required row cannot remain planned.
run_case "required_cannot_be_planned" \
"- invariant_id: INV-114\n  status: planned\n  required: true\n  gate_id: INT-G28\n  verifier: scripts/audit/verify_phase1_contract.sh\n  evidence_path: evidence/phase1/phase1_contract_status_seed.json\n" \
"0" \
"yes" \
"1" \
"FAIL" \
"required_cannot_be_planned"

# 4) Non-prereq rows must use evidence/phase1 path.
run_case "phase1_row_wrong_path_prefix" \
"- invariant_id: INV-114\n  status: implemented\n  required: false\n  gate_id: INT-G28\n  verifier: scripts/audit/verify_phase1_contract.sh\n  evidence_path: evidence/phase0/pii_leakage_payloads.json\n" \
"0" \
"yes" \
"1" \
"FAIL" \
"phase1_evidence_path_required"

echo "All phase1 contract checker tests passed."

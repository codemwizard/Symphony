#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/audit/verify_phase1_contract.sh"

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
if data.get("status") != exp:
    raise SystemExit(f"Expected {exp}, got {data.get('status')} in {p}")
PY
}

assert_error_contains() {
  local file="$1"
  local needle="$2"
  python3 - <<'PY' "$file" "$needle"
import json,sys
data=json.load(open(sys.argv[1]))
needle=sys.argv[2]
errs=data.get("errors") or []
if not any(needle in str(e) for e in errs):
    raise SystemExit(f"Expected error containing '{needle}'")
PY
}

write_common_files() {
  local case_dir="$1"
  mkdir -p "$case_dir/docs/PHASE1" "$case_dir/docs/control_planes" "$case_dir/docs/operations" "$case_dir/docs/architecture" "$case_dir/evidence/phase1" "$case_dir/evidence/phase0"
  cat > "$case_dir/docs/PHASE1/phase1_contract.yml" <<'YAML'
- invariant_id: "INV-077"
  status: "implemented"
  required: true
  gate_id: "INT-G28"
  verifier: "scripts/audit/verify_evidence_harness_integrity.sh"
  evidence_path: "evidence/phase1/approval_metadata.json"
YAML
  cat > "$case_dir/docs/control_planes/CONTROL_PLANES.yml" <<'YAML'
control_planes:
  integrity:
    required_gates:
      - gate_id: "INT-G28"
        script: "scripts/audit/verify_phase1_contract.sh"
YAML
  cat > "$case_dir/docs/operations/REGULATED_SURFACE_PATHS.yml" <<'YAML'
version: "1.0"
rules:
  patterns:
    - "scripts/audit/**"
    - "schema/migrations/**"
YAML
  cp "$ROOT/docs/architecture/evidence_schema.json" "$case_dir/docs/architecture/evidence_schema.json"
  cp "$ROOT/docs/operations/approval_metadata.schema.json" "$case_dir/docs/operations/approval_metadata.schema.json"
}

init_git() {
  local case_dir="$1"
  git -C "$case_dir" init -q
  git -C "$case_dir" config user.email "ci@example.com"
  git -C "$case_dir" config user.name "CI"
  echo "base" > "$case_dir/README.md"
  git -C "$case_dir" add .
  git -C "$case_dir" commit -q -m "base"
}

run_case() {
  local name="$1"
  local change_path="$2"
  local approval_mode="$3" # none|invalid|valid
  local contract_mode="$4" # range|zip_audit
  local expected_exit="$5"
  local expected_status="$6"
  local expected_error="$7"

  local case_dir="$tmp_dir/$name"
  mkdir -p "$case_dir"
  write_common_files "$case_dir"
  init_git "$case_dir"

  mkdir -p "$case_dir/$(dirname "$change_path")"
  echo "change" > "$case_dir/$change_path"
  git -C "$case_dir" add "$change_path"

  if [[ "$approval_mode" == "invalid" ]]; then
    cat > "$case_dir/evidence/phase1/approval_metadata.json" <<'JSON'
{"schema_version":"1.0"}
JSON
  elif [[ "$approval_mode" == "valid" ]]; then
    cat > "$case_dir/evidence/phase1/approval_metadata.json" <<'JSON'
{
  "schema_version": "1.0",
  "generated_at_utc": "2026-02-17T00:00:00Z",
  "git_commit": "deadbeef",
  "change_scope": {
    "regulated_surfaces_touched": true,
    "paths_changed": ["scripts/audit/example.sh"]
  },
  "ai": {
    "ai_prompt_hash": "abc123abc123abc1",
    "model_id": "gpt-5.2-codex",
    "client": "codex_cli"
  },
  "human_approval": {
    "approver_id": "phase1-lead",
    "approval_artifact_ref": "approvals/2026-02-11/PR-0001.md",
    "change_reason": "regulated surface change"
  }
}
JSON
  fi

  local evidence_out="$case_dir/evidence/phase1/phase1_contract_status.json"
  set +e
  ROOT_DIR="$case_dir" RUN_PHASE1_GATES=1 PHASE1_CONTRACT_MODE="$contract_mode" EVIDENCE_FILE="$evidence_out" bash "$SCRIPT" >/tmp/approval_req_case.log 2>&1
  rc=$?
  set -e

  if [[ "$expected_exit" == "0" && "$rc" -ne 0 ]]; then
    echo "Case $name failed unexpectedly"
    cat /tmp/approval_req_case.log
    exit 1
  fi
  if [[ "$expected_exit" != "0" && "$rc" -eq 0 ]]; then
    echo "Case $name unexpectedly passed"
    cat /tmp/approval_req_case.log
    exit 1
  fi
  assert_status "$evidence_out" "$expected_status"
  if [[ -n "$expected_error" ]]; then
    assert_error_contains "$evidence_out" "$expected_error"
  fi
}

run_case "non_regulated_no_approval" "docs/readme.md" "none" "range" 0 "PASS" ""
run_case "regulated_missing_approval" "scripts/audit/example.sh" "none" "range" 1 "FAIL" "missing_evidence"
run_case "regulated_invalid_approval" "scripts/audit/example.sh" "invalid" "range" 1 "FAIL" "schema_validation_failed"
run_case "regulated_valid_approval" "scripts/audit/example.sh" "valid" "range" 0 "PASS" ""
run_case "zip_mode_regulated_no_approval" "scripts/audit/example.sh" "none" "zip_audit" 0 "PASS" ""

echo "Approval metadata requirement tests passed."

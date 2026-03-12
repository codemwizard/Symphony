#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/audit/verify_task_pack_readiness.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

make_zip_case() {
  local zip_name="$1"
  local meta_body="$2"
  local stem="$tmp_dir/${zip_name%.zip}"
  mkdir -p "$stem/tasks/TEST-001" "$stem/docs/plans/phase1/TEST-001"
  cat > "$stem/tasks/TEST-001/meta.yml" <<YAML
schema_version: 1
phase: '1'
task_id: TEST-001
title: Readiness fixture
owner_role: QA_VERIFIER
blast_radius: SERVICE_API
implementation_plan: docs/plans/phase1/TEST-001/PLAN.md
implementation_log: docs/plans/phase1/TEST-001/EXEC_LOG.md
work:
  - Exercise pack readiness parsing
acceptance_criteria:
  - First criterion
  - Second criterion
  - Third criterion
${meta_body}
YAML
  cat > "$stem/docs/plans/phase1/TEST-001/PLAN.md" <<'MD'
# PLAN
MD
  cat > "$stem/docs/plans/phase1/TEST-001/EXEC_LOG.md" <<'MD'
# EXEC_LOG
MD
  (cd "$tmp_dir" && zip -qr "$zip_name" "${zip_name%.zip}")
}

assert_pass() {
  local zip_path="$1"
  bash "$SCRIPT" --zip "$zip_path" >/dev/null
}

assert_fail_contains() {
  local zip_path="$1"
  local needle="$2"
  local out
  set +e
  out="$(bash "$SCRIPT" --zip "$zip_path" 2>&1)"
  local rc=$?
  set -e
  if [[ "$rc" -eq 0 ]]; then
    echo "Expected failure for $zip_path" >&2
    exit 1
  fi
  if [[ "$out" != *"$needle"* ]]; then
    echo "Expected output to contain '$needle' but got:" >&2
    echo "$out" >&2
    exit 1
  fi
}

make_zip_case "dict_verification.zip" "$(cat <<'YAML'
verification:
  - name: one
    cmd: bash scripts/audit/example_one.sh
  - name: two
    cmd: python3 scripts/audit/example_two.py
  - name: three
    cmd: scripts/audit/example_three.sh
YAML
)"

make_zip_case "mixed_verification.zip" "$(cat <<'YAML'
verification:
  - bash scripts/audit/example_one.sh
  - name: two
    cmd: python3 scripts/audit/example_two.py
  - scripts/audit/example_three.sh
YAML
)"

make_zip_case "bad_dict_verification.zip" "$(cat <<'YAML'
verification:
  - name: one
    cmd: bash scripts/audit/example_one.sh
  - name: two
  - scripts/audit/example_three.sh
YAML
)"

assert_pass "$tmp_dir/dict_verification.zip"
assert_pass "$tmp_dir/mixed_verification.zip"
assert_fail_contains "$tmp_dir/bad_dict_verification.zip" "verification_too_shallow"

echo "verify_task_pack_readiness verification-format tests passed."

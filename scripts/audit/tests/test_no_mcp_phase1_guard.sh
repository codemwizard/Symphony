#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/audit/verify_no_mcp_phase1.sh"
FIX_ROOT="$ROOT/scripts/audit/tests/fixtures/no_mcp"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run_case() {
  local name="$1"
  local expect_rc="$2"
  local scan_root="$FIX_ROOT/$name"
  local ev="$tmp/${name}.json"
  set +e
  SCAN_ROOT="$scan_root" EVIDENCE_FILE="$ev" bash "$SCRIPT" >/tmp/no_mcp_case.log 2>&1
  rc=$?
  set -e
  if [[ "$expect_rc" == "0" && "$rc" -ne 0 ]]; then
    echo "Case '$name' expected pass but failed"
    cat /tmp/no_mcp_case.log
    exit 1
  fi
  if [[ "$expect_rc" != "0" && "$rc" -eq 0 ]]; then
    echo "Case '$name' expected fail but passed"
    cat /tmp/no_mcp_case.log
    exit 1
  fi
}

run_case "allowlisted_phase2_ref" 0
run_case "forbidden_phase1_ref" 1
run_case "forbidden_mcp_json_file" 1

echo "No-MCP guard fixture tests passed."

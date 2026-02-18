#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/audit/verify_invariant_semantic_integrity.sh"

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

assert_violation_contains() {
  local file="$1"
  local code="$2"
  python3 - <<'PY' "$file" "$code"
import json,sys
payload=json.load(open(sys.argv[1]))
code=sys.argv[2]
if not any(v.get("code") == code for v in (payload.get("violations") or [])):
    raise SystemExit(f"Expected violation code {code}")
PY
}

write_common() {
  local case_dir="$1"
  mkdir -p "$case_dir/docs/invariants" "$case_dir/docs/PHASE1" "$case_dir/docs/control_planes" "$case_dir/docs/operations" "$case_dir/evidence/phase1"

  cat > "$case_dir/docs/control_planes/CONTROL_PLANES.yml" <<'YAML'
control_planes:
  integrity:
    required_gates:
      - gate_id: "INT-G28"
        script: "scripts/audit/verify_phase1_contract.sh"
YAML

  cat > "$case_dir/docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml" <<'YAML'
version: "1.0"
registry:
  scripts/audit/verify_remediation_trace.sh:
    emits:
      - evidence/phase0/remediation_trace.json
  scripts/audit/verify_agent_conformance.sh:
    emits:
      - evidence/phase1/agent_conformance_architect.json
YAML

  cat > "$case_dir/docs/operations/SEMANTIC_INTEGRITY_ALLOWLIST.yml" <<'YAML'
version: "1.0"
allow: []
YAML
}

run_case() {
  local name="$1"
  local expected_exit="$2"
  local expected_status="$3"
  local expected_code="$4"

  local case_dir="$tmp_dir/$name"
  mkdir -p "$case_dir"
  write_common "$case_dir"

  local ev="$case_dir/evidence/phase1/invariant_semantic_integrity.json"
  set +e
  ROOT_DIR="$case_dir" MANIFEST_FILE="$case_dir/docs/invariants/INVARIANTS_MANIFEST.yml" CONTRACT_FILE="$case_dir/docs/PHASE1/phase1_contract.yml" CONTROL_PLANES_FILE="$case_dir/docs/control_planes/CONTROL_PLANES.yml" REGISTRY_FILE="$case_dir/docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml" ALLOWLIST_FILE="$case_dir/docs/operations/SEMANTIC_INTEGRITY_ALLOWLIST.yml" EVIDENCE_FILE="$ev" bash "$SCRIPT" >/tmp/sem_integrity_case.log 2>&1
  rc=$?
  set -e

  if [[ "$expected_exit" == "0" && "$rc" -ne 0 ]]; then
    echo "Case $name failed unexpectedly"
    cat /tmp/sem_integrity_case.log
    exit 1
  fi
  if [[ "$expected_exit" != "0" && "$rc" -eq 0 ]]; then
    echo "Case $name unexpectedly passed"
    cat /tmp/sem_integrity_case.log
    exit 1
  fi

  assert_status "$ev" "$expected_status"
  if [[ -n "$expected_code" ]]; then
    assert_violation_contains "$ev" "$expected_code"
  fi
}

# Case 1: verifier mismatch (INV-105 collision pattern)
case1="$tmp_dir/mismatch"
mkdir -p "$case1"
write_common "$case1"
cat > "$case1/docs/invariants/INVARIANTS_MANIFEST.yml" <<'YAML'
- id: INV-105
  aliases: ["I-REMED-TRACE-01"]
  enforcement: "scripts/audit/verify_remediation_trace.sh"
YAML
cat > "$case1/docs/PHASE1/phase1_contract.yml" <<'YAML'
- invariant_id: "INV-105"
  status: "implemented"
  required: true
  gate_id: "INT-G28"
  verifier: "scripts/audit/verify_agent_conformance.sh"
  evidence_path: "evidence/phase1/agent_conformance_architect.json"
YAML
run_case "mismatch" "1" "FAIL" "SEM_I01_VERIFIER_MISMATCH"

# Case 2: evidence mismatch
case2="$tmp_dir/evidence_mismatch"
mkdir -p "$case2"
write_common "$case2"
cat > "$case2/docs/invariants/INVARIANTS_MANIFEST.yml" <<'YAML'
- id: INV-119
  aliases: ["I-AGENT-CONF-01"]
  enforcement: "scripts/audit/verify_agent_conformance.sh"
YAML
cat > "$case2/docs/PHASE1/phase1_contract.yml" <<'YAML'
- invariant_id: "INV-119"
  status: "implemented"
  required: true
  gate_id: "INT-G28"
  verifier: "scripts/audit/verify_agent_conformance.sh"
  evidence_path: "evidence/phase1/agent_conformance_policy_guardian.json"
YAML
run_case "evidence_mismatch" "1" "FAIL" "SEM_I01_EVIDENCE_NOT_EMITTED_BY_VERIFIER"

# Case 3: happy path
case3="$tmp_dir/happy"
mkdir -p "$case3"
write_common "$case3"
cat > "$case3/docs/invariants/INVARIANTS_MANIFEST.yml" <<'YAML'
- id: INV-105
  aliases: ["I-REMED-TRACE-01"]
  enforcement: "scripts/audit/verify_remediation_trace.sh"
- id: INV-119
  aliases: ["I-AGENT-CONF-01"]
  enforcement: "scripts/audit/verify_agent_conformance.sh"
YAML
cat > "$case3/docs/PHASE1/phase1_contract.yml" <<'YAML'
- invariant_id: "INV-105"
  status: "phase0_prerequisite"
  required: true
  gate_id: "INT-G28"
  verifier: "scripts/audit/verify_remediation_trace.sh"
  evidence_path: "evidence/phase0/remediation_trace.json"
- invariant_id: "INV-119"
  status: "implemented"
  required: true
  gate_id: "INT-G28"
  verifier: "scripts/audit/verify_agent_conformance.sh"
  evidence_path: "evidence/phase1/agent_conformance_architect.json"
YAML
run_case "happy" "0" "PASS" ""

echo "Invariant semantic integrity tests passed."

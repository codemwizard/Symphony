#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-SUPPORT-OBS-001"
DOC_PATH="docs/architecture/PHASE3_INTERNAL_CONSTITUTIONAL_OBSERVABILITY_CONTRACT.md"
VERIFIER_PATH="scripts/agent/verify_tsk_p3_support_obs_001.sh"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-SUPPORT-OBS-001/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-SUPPORT-OBS-001/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-SUPPORT-OBS-001/EXEC_LOG.md"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
CHECKS_FILE="$TMPDIR/checks.tsv"
COMMANDS_FILE="$TMPDIR/commands.log"
TRACE_FILE="$TMPDIR/trace.log"
: > "$CHECKS_FILE"
: > "$COMMANDS_FILE"
: > "$TRACE_FILE"

PASS=true
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

record_check() {
  local id="$1"
  local status="$2"
  local detail="$3"
  printf '%s\t%s\t%s\n' "$id" "$status" "$detail" >> "$CHECKS_FILE"
  if [[ "$status" != "PASS" ]]; then
    PASS=false
  fi
}

record_command() {
  printf '%s\n' "$1" >> "$COMMANDS_FILE"
}

record_trace() {
  printf '%s\n' "$1" >> "$TRACE_FILE"
}

contains_all() {
  local path="$1"
  shift
  local ok=true
  for needle in "$@"; do
    if ! grep -Fq "$needle" "$path"; then
      ok=false
      break
    fi
  done
  [[ "$ok" == true ]]
}

record_trace "start verifier for $TASK_ID"
record_command "inspect shared observability contract and runtime registration"

if [[ -f "$ROOT/$DOC_PATH" ]]; then
  record_check "doc_exists" "PASS" "$DOC_PATH exists"
else
  record_check "doc_exists" "FAIL" "$DOC_PATH missing"
fi

if contains_all "$ROOT/$DOC_PATH" \
  "P3-SURF-003" \
  "P3-SURF-004" \
  "P3-SURF-005" \
  "P3-SURF-007" \
  "P3-SURF-009" \
  "internal-only" \
  "machine-readable" \
  "replay-safe" \
  "no dashboards" \
  "no regulator portal semantics"; then
  record_check "contract_scope_complete" "PASS" "observability contract covers all owning surfaces and internal-only prohibitions"
else
  record_check "contract_scope_complete" "FAIL" "observability contract missing required owning-surface or prohibition language"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-SUPPORT-OBS-001 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-SUPPORT-OBS-001' "$ROOT/$REGISTRY_PATH" || true)"
META_STATUS="$(awk -F': ' '/^status:/ {print $2; exit}' "$ROOT/$META_PATH" || true)"

[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] \
  && record_check "runtime_index_registered" "PASS" "runtime task index contains TSK-P3-SUPPORT-OBS-001" \
  || record_check "runtime_index_registered" "FAIL" "runtime task index missing TSK-P3-SUPPORT-OBS-001"
[[ "$REGISTRY_MATCHES" -ge 1 ]] \
  && record_check "phase3_registry_registered" "PASS" "phase3 registry contains TSK-P3-SUPPORT-OBS-001" \
  || record_check "phase3_registry_registered" "FAIL" "phase3 registry missing TSK-P3-SUPPORT-OBS-001"
[[ "$META_STATUS" =~ ^(ready|completed)$ ]] \
  && record_check "meta_proof_state" "PASS" "task meta status is $META_STATUS (proof-compatible)" \
  || record_check "meta_proof_state" "FAIL" "task meta status is $META_STATUS"

if [[ "$PASS" == "true" ]]; then
  STATUS="PASS"
  PASS_FLAG="true"
else
  STATUS="FAIL"
  PASS_FLAG="false"
fi

export ROOT TASK_ID GIT_SHA TIMESTAMP_UTC STATUS PASS_FLAG CHECKS_FILE COMMANDS_FILE TRACE_FILE
export DOC_PATH VERIFIER_PATH RUNTIME_INDEX_PATH REGISTRY_PATH META_PATH PLAN_PATH EXEC_LOG_PATH

python3 - <<'PY'
import hashlib
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT"])
paths = [
    os.environ["DOC_PATH"],
    os.environ["VERIFIER_PATH"],
    os.environ["RUNTIME_INDEX_PATH"],
    os.environ["REGISTRY_PATH"],
    os.environ["META_PATH"],
    os.environ["PLAN_PATH"],
    os.environ["EXEC_LOG_PATH"],
]

def sha256_for(rel_path: str) -> str:
    data = (root / rel_path).read_bytes()
    return hashlib.sha256(data).hexdigest()

checks = {}
for line in Path(os.environ["CHECKS_FILE"]).read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    key, status, detail = line.split("\t", 2)
    checks[key] = {"status": status, "detail": detail}

command_outputs = [{"command": line, "status": "recorded"} for line in Path(os.environ["COMMANDS_FILE"]).read_text(encoding="utf-8").splitlines() if line.strip()]
execution_trace = [line for line in Path(os.environ["TRACE_FILE"]).read_text(encoding="utf-8").splitlines() if line.strip()]

payload = {
    "task_id": os.environ["TASK_ID"],
    "git_sha": os.environ["GIT_SHA"],
    "timestamp_utc": os.environ["TIMESTAMP_UTC"],
    "status": os.environ["STATUS"],
    "pass": os.environ["PASS_FLAG"].lower() == "true",
    "checks": checks,
    "observed_paths": paths,
    "observed_hashes": {path: sha256_for(path) for path in paths},
    "command_outputs": command_outputs,
    "execution_trace": execution_trace,
}
print(json.dumps(payload, indent=2))
PY

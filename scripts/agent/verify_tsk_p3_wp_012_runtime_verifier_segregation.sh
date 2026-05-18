#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-WP-012"
DOC_PATH="docs/architecture/PHASE3_RUNTIME_VERIFIER_SEGREGATION_CONTRACT.md"
VERIFIER_PATH="scripts/agent/verify_tsk_p3_wp_012_runtime_verifier_segregation.sh"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-WP-012/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-WP-012/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-WP-012/EXEC_LOG.md"

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

record_check() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$CHECKS_FILE"; [[ "$2" == "PASS" ]] || PASS=false; }
record_command() { printf '%s\n' "$1" >> "$COMMANDS_FILE"; }
record_trace() { printf '%s\n' "$1" >> "$TRACE_FILE"; }

contains_all() {
  local path="$1"; shift
  local needle
  for needle in "$@"; do
    grep -Fq "$needle" "$path" || return 1
  done
}

record_trace "start verifier for $TASK_ID"
record_command "inspect runtime/verifier segregation contract and registrations"

[[ -f "$ROOT/$DOC_PATH" ]] \
  && record_check "doc_exists" "PASS" "$DOC_PATH exists" \
  || record_check "doc_exists" "FAIL" "$DOC_PATH missing"

if contains_all "$ROOT/$DOC_PATH" \
  "No runtime-authored verifier proof." \
  "No shared trust context between runtime and verifier." \
  "No verifier mutation of runtime lineage truth." \
  "replay-addressable artifact exchange" \
  "TSK-P3-WP-005" \
  "TSK-P3-WP-006" \
  "TSK-P3-WP-008"; then
  record_check "boundary_rules_complete" "PASS" "segregation contract declares anti-trust-collapse rules and substrate anchors"
else
  record_check "boundary_rules_complete" "FAIL" "segregation contract missing required prohibitions or anchors"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-WP-012 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-WP-012' "$ROOT/$REGISTRY_PATH" || true)"
META_STATUS="$(awk -F': ' '/^status:/ {print $2; exit}' "$ROOT/$META_PATH" || true)"
[[ "$RUNTIME_INDEX_MATCHES" -ge 1 ]] && record_check "runtime_index_registered" "PASS" "runtime index contains $TASK_ID" || record_check "runtime_index_registered" "FAIL" "runtime index missing $TASK_ID"
[[ "$REGISTRY_MATCHES" -ge 1 ]] && record_check "phase3_registry_registered" "PASS" "registry contains $TASK_ID" || record_check "phase3_registry_registered" "FAIL" "registry missing $TASK_ID"
[[ "$META_STATUS" =~ ^(ready|completed)$ ]] && record_check "meta_proof_state" "PASS" "meta status is $META_STATUS" || record_check "meta_proof_state" "FAIL" "meta status is $META_STATUS"

STATUS="FAIL"; PASS_FLAG="false"
if [[ "$PASS" == "true" ]]; then STATUS="PASS"; PASS_FLAG="true"; fi

export ROOT TASK_ID GIT_SHA TIMESTAMP_UTC STATUS PASS_FLAG CHECKS_FILE COMMANDS_FILE TRACE_FILE
export DOC_PATH VERIFIER_PATH RUNTIME_INDEX_PATH REGISTRY_PATH META_PATH PLAN_PATH EXEC_LOG_PATH
python3 - <<'PY'
import hashlib, json, os
from pathlib import Path
root = Path(os.environ["ROOT"])
paths = [os.environ[x] for x in ["DOC_PATH","VERIFIER_PATH","RUNTIME_INDEX_PATH","REGISTRY_PATH","META_PATH","PLAN_PATH","EXEC_LOG_PATH"]]
checks={}
for line in Path(os.environ["CHECKS_FILE"]).read_text().splitlines():
    if line.strip():
        key,status,detail=line.split("\t",2)
        checks[key]={"status":status,"detail":detail}
payload={
  "task_id": os.environ["TASK_ID"],
  "git_sha": os.environ["GIT_SHA"],
  "timestamp_utc": os.environ["TIMESTAMP_UTC"],
  "status": os.environ["STATUS"],
  "pass": os.environ["PASS_FLAG"].lower()=="true",
  "checks": checks,
  "observed_paths": paths,
  "observed_hashes": {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in paths},
  "command_outputs": [{"command": l, "status": "recorded"} for l in Path(os.environ["COMMANDS_FILE"]).read_text().splitlines() if l.strip()],
  "execution_trace": [l for l in Path(os.environ["TRACE_FILE"]).read_text().splitlines() if l.strip()],
}
print(json.dumps(payload, indent=2))
PY

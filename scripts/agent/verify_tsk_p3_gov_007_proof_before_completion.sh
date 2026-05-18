#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-GOV-007"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
CHECKS_FILE="$TMPDIR/checks.tsv"
: > "$CHECKS_FILE"
PASS=true

record_check() {
  local id="$1" status="$2" detail="$3"
  printf '%s\t%s\t%s\n' "$id" "$status" "$detail" >> "$CHECKS_FILE"
  if [[ "$status" != "PASS" ]]; then
    PASS=false
  fi
}

REPRESENTATIVE_SCRIPTS=(
  "scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh"
  "scripts/db/verify_p3_conflict_of_interest_enforcement.sh"
  "scripts/db/verify_p3_spatial_legality_dnsh_gates.sh"
  "scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh"
  "scripts/agent/verify_tsk_p3_support_obs_001.sh"
  "scripts/agent/verify_tsk_p3_support_perf_001.sh"
)

EXACT_COMPLETED_GATES=0
PROOF_COMPATIBLE_GATES=0
for path in "${REPRESENTATIVE_SCRIPTS[@]}"; do
  if rg -n 'meta_completed|== "completed"' "$ROOT/$path" >/dev/null; then
    EXACT_COMPLETED_GATES=$((EXACT_COMPLETED_GATES + 1))
  fi
  if rg -n '\^\(ready\|completed\)\$|proof-compatible' "$ROOT/$path" >/dev/null; then
    PROOF_COMPATIBLE_GATES=$((PROOF_COMPATIBLE_GATES + 1))
  fi
done

[[ "$EXACT_COMPLETED_GATES" == "0" ]] \
  && record_check "completed_dependency_removed" "PASS" "representative verifiers no longer require completed status before proof" \
  || record_check "completed_dependency_removed" "FAIL" "representative verifiers still contain $EXACT_COMPLETED_GATES completed-status-only gate(s)"

[[ "$PROOF_COMPATIBLE_GATES" == "${#REPRESENTATIVE_SCRIPTS[@]}" ]] \
  && record_check "proof_compatible_gates_present" "PASS" "representative verifiers accept ready/completed proof-compatible states" \
  || record_check "proof_compatible_gates_present" "FAIL" "expected ${#REPRESENTATIVE_SCRIPTS[@]} proof-compatible gates, found $PROOF_COMPATIBLE_GATES"

if rg -n 'proof-passed' "$ROOT/docs/operations/TASK_CREATION_PROCESS.md" "$ROOT/docs/operations/AGENT_PROMPT_ROUTER.md" "$ROOT/docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md" >/dev/null; then
  record_check "lifecycle_docs_updated" "PASS" "canonical lifecycle docs distinguish proof-passed from completed"
else
  record_check "lifecycle_docs_updated" "FAIL" "canonical lifecycle docs missing proof-passed distinction"
fi

if rg -n 'task-packed state, not completed proof|only then may task status move to `completed`' "$ROOT/scripts/agent/generate_task_pack.py" >/dev/null; then
  record_check "generator_wording_updated" "PASS" "task generator now emits proof-before-completion wording"
else
  record_check "generator_wording_updated" "FAIL" "task generator missing proof-before-completion wording"
fi

if [[ "$PASS" == "true" ]]; then STATUS="PASS"; else STATUS="FAIL"; fi
export ROOT TASK_ID TIMESTAMP_UTC GIT_SHA STATUS CHECKS_FILE
python3 - <<'PY'
import hashlib, json, os
from pathlib import Path

root = Path(os.environ["ROOT"])
checks = {}
for line in Path(os.environ["CHECKS_FILE"]).read_text(encoding="utf-8").splitlines():
    key, status, detail = line.split("\t", 2)
    checks[key] = {"status": status, "detail": detail}
paths = [
    "scripts/agent/generate_task_pack.py",
    "docs/operations/TASK_CREATION_PROCESS.md",
    "docs/operations/AGENT_PROMPT_ROUTER.md",
    "docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md",
    "scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh",
    "scripts/db/verify_p3_conflict_of_interest_enforcement.sh",
    "scripts/db/verify_p3_spatial_legality_dnsh_gates.sh",
    "scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh",
    "scripts/agent/verify_tsk_p3_support_obs_001.sh",
    "scripts/agent/verify_tsk_p3_support_perf_001.sh",
    "scripts/agent/verify_tsk_p3_gov_007_proof_before_completion.sh",
]
payload = {
    "task_id": os.environ["TASK_ID"],
    "git_sha": os.environ["GIT_SHA"],
    "timestamp_utc": os.environ["TIMESTAMP_UTC"],
    "status": os.environ["STATUS"],
    "checks": checks,
    "observed_paths": paths,
    "observed_hashes": {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in paths},
}
print(json.dumps(payload, indent=2))
PY

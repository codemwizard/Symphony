#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-GOV-005"
DOC_PATH="docs/architecture/PHASE3_AI_GOVERNANCE_AND_MODEL_PROVENANCE_CONTRACT.md"
VERIFIER_PATH="scripts/audit/verify_tsk_p3_gov_005_ai_governance.sh"
RUNTIME_INDEX_PATH="docs/tasks/PHASE3_RUNTIME_TASKS.md"
REGISTRY_PATH="docs/PHASE3/phase3_task_registry.yml"
META_PATH="tasks/TSK-P3-GOV-005/meta.yml"
PLAN_PATH="docs/plans/phase3/TSK-P3-GOV-005/PLAN.md"
EXEC_LOG_PATH="docs/plans/phase3/TSK-P3-GOV-005/EXEC_LOG.md"

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

record_trace "start verifier for $TASK_ID"
record_command "inspect AI governance contract and registrations"

[[ -f "$ROOT/$DOC_PATH" ]] && record_check "doc_exists" "PASS" "$DOC_PATH exists" || record_check "doc_exists" "FAIL" "$DOC_PATH missing"

if grep -Fq "AI outputs are advisory-only." "$ROOT/$DOC_PATH" \
  && grep -Fq "AI outputs are never constitutional truth." "$ROOT/$DOC_PATH" \
  && grep -Fq "Anti-truth-delegation is mandatory." "$ROOT/$DOC_PATH"; then
  record_check "advisory_only_rules" "PASS" "advisory-only and anti-truth-delegation rules declared"
else
  record_check "advisory_only_rules" "FAIL" "advisory-only or anti-truth-delegation rules missing"
fi

schema_ok=true
for field in model_id model_name model_version model_class training_data_provenance inference_determinism_class confidence_output_type confidence_to_uncertainty_mapping_id admissibility_ceiling governing_policy_version_id inference_id input_artifact_refs output_artifact_ref prompt_or_query_fingerprint confidence_payload mapped_uncertainty_class operator_or_mapping_rule_ref; do
  grep -Fq "\`$field\`" "$ROOT/$DOC_PATH" || schema_ok=false
done
[[ "$schema_ok" == "true" ]] && record_check "registry_and_log_schema" "PASS" "model registry and inference log schema fields declared" || record_check "registry_and_log_schema" "FAIL" "model registry or inference log schema incomplete"

if grep -Fq "scalar probability" "$ROOT/$DOC_PATH" \
  && grep -Fq "U-CONFIDENCE-INTERVAL" "$ROOT/$DOC_PATH" \
  && grep -Fq "U-UNKNOWN-UNCERTAINTY" "$ROOT/$DOC_PATH" \
  && grep -Fq "Phase 4, Phase 8A, and Phase 8B remain AI-free." "$ROOT/$DOC_PATH"; then
  record_check "mapping_and_phase_routing" "PASS" "confidence mapping and phase routing declared"
else
  record_check "mapping_and_phase_routing" "FAIL" "confidence mapping or phase routing missing"
fi

RUNTIME_INDEX_MATCHES="$(grep -c '^| TSK-P3-GOV-005 |' "$ROOT/$RUNTIME_INDEX_PATH" || true)"
REGISTRY_MATCHES="$(grep -c 'task_id: TSK-P3-GOV-005' "$ROOT/$REGISTRY_PATH" || true)"
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

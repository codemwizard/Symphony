#!/usr/bin/env bash
set -euo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
T="$(basename "$0" .sh | sed 's/verify_tsk_hard_//')"
M="$R/schema/migrations/0067_hard_wave6_operational_resilience_and_privacy.sql"
O="$R/evidence/phase1/hardening/tsk_hard_${T}.json"
S="$R/evidence/schemas/hardening/tsk_hard_${T}.schema.json"

case "$T" in
  080)
    rg -q "artifact_signing_batches" "$M"
    rg -q "artifact_signing_batch_items" "$M"
    rg -q "ARTIFACT_CLASS_TAXONOMY" "$R/docs/architecture/ARTIFACT_CLASS_TAXONOMY.md"
    ;;
  081)
    rg -q "hsm_fail_closed_events" "$M"
    rg -q "assert_hsm_fail_closed" "$M"
    rg -q "P8401" "$M"
    ;;
  082)
    rg -q "signing_throughput_runs" "$M"
    rg -q "p95_latency_ms" "$M"
    ;;
  090)
    rg -q "global_rate_limit_policies" "$M"
    rg -q "assert_rate_limit_blocked" "$M"
    rg -q "P8402" "$M"
    ;;
  091)
    rg -q "regulatory_retraction_approvals" "$M"
    rg -q "assert_secondary_retraction_approval" "$M"
    rg -q "P8403" "$M"
    ;;
  092)
    rg -q "redaction_audit_events" "$M"
    rg -q "redaction_scope" "$M"
    ;;
  093)
    rg -q "boz_operational_scenario_runs" "$M"
    rg -q "scenario_name" "$M"
    ;;
  095)
    rg -q "regulatory_report_submission_attempts" "$M"
    rg -q "attempted_at" "$M"
    ;;
  040)
    rg -q "pii_tokenization_registry" "$M"
    rg -q "token_value" "$M"
    ;;
  041)
    rg -q "pii_erasure_journal" "$M"
    rg -q "status IN \('REQUESTED','APPROVED','COMPLETED','FAILED'\)" "$M"
    ;;
  042)
    rg -q "pii_erased_subject_placeholders" "$M"
    rg -q "placeholder_ref" "$M"
    ;;
  098)
    rg -q "penalty_defense_packs" "$M"
    rg -q "assert_pii_absent_from_penalty_pack" "$M"
    rg -q "P8404" "$M"
    ;;
  100)
    rg -q "audit_tamper_evident_chains" "$M"
    rg -q "previous_hash" "$M"
    ;;
  *)
    echo "unsupported task id: $T" >&2
    exit 2
    ;;
esac

mkdir -p "$(dirname "$O")"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-${T}","task_id":"TSK-HARD-${T}","status":"PASS","pass":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON

python3 - <<PY
import json
s=json.load(open('$S'))
d=json.load(open('$O'))
for k in s['required']:
    assert k in d, k
PY

echo "TSK-HARD-${T} verification passed. Evidence: $O"

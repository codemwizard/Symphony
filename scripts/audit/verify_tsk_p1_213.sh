#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_213_demo_017_verifier_realignment.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-213 demo-017 verifier realignment..."

RUNBOOK="$ROOT/docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md"
OLD_VERIFIER="$ROOT/scripts/audit/verify_tsk_p1_demo_017.sh"

# 1. Check for absence of compatibility aliases in runbook
if grep -q "<!--" "$RUNBOOK"; then
  errors+=("runbook_contains_html_comments")
fi
if grep -q "Provisioning Steps" "$RUNBOOK"; then
  errors+=("runbook_contains_stale_alias_provisioning_steps")
fi
if grep -q "Required Configuration Fields" "$RUNBOOK"; then
  errors+=("runbook_contains_stale_alias_required_configuration_fields")
fi

# 2. Check if the old verifier uses the new correct patterns
if ! grep -q "Provisioning Procedure" "$OLD_VERIFIER"; then
  errors+=("verifier_missing_new_pattern_provisioning_procedure")
fi
if ! grep -q "Required Inputs" "$OLD_VERIFIER"; then
  errors+=("verifier_missing_new_pattern_required_inputs")
fi
if grep -q "Provisioning Steps" "$OLD_VERIFIER"; then
  errors+=("verifier_still_uses_stale_pattern_provisioning_steps")
fi

# 3. Ensure the old verifier passes with the current runbook
if ! bash "$OLD_VERIFIER" >/dev/null 2>&1; then
  errors+=("verify_tsk_p1_demo_017_fails_against_current_runbook")
fi

# 4. Check if we break the verifier by removing a required string, it fails.
if ${TEST_FAIL_CLOSED:-true}; then
  TMP_RUNBOOK="/tmp/fake_runbook.md"
  cp "$RUNBOOK" "$TMP_RUNBOOK"
  # Corrupt the runbook by replacing exactly one of the known headers
  sed -i 's/Provisioning Procedure/Provisioning XYZ/' "$TMP_RUNBOOK"
  
  # Inject the fake runbook path into the verifier script temporarily
  TMP_VERIFIER="/tmp/fake_verifier.sh"
  cp "$OLD_VERIFIER" "$TMP_VERIFIER"
  sed -i "s|docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md|$TMP_RUNBOOK|g" "$TMP_VERIFIER"
  
  if bash "$TMP_VERIFIER" >/dev/null 2>&1; then
    errors+=("verify_tsk_p1_demo_017_fails_open_when_section_missing")
  fi
  
  rm -f "$TMP_RUNBOOK" "$TMP_VERIFIER"
fi

if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { [ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ; }
}

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$TS_UTC" "$GIT_SHA" "$SCHEMA_FP" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-213",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-213",
    "run_id": run_id,
    "checks": {
        "runbook_clean": "runbook_contains_html_comments" not in errors and "runbook_contains_stale_alias_provisioning_steps" not in errors,
        "verifier_updated": "verifier_missing_new_pattern_provisioning_procedure" not in errors and "verifier_still_uses_stale_pattern_provisioning_steps" not in errors,
        "verifier_passes": "verify_tsk_p1_demo_017_fails_against_current_runbook" not in errors,
        "verifier_fail_closed": "verify_tsk_p1_demo_017_fails_open_when_section_missing" not in errors
    },
    "errors": errors
}
os.makedirs(os.path.dirname(evidence_path), exist_ok=True)
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: TSK-P1-213 demo-017 verifier realignment verified."
echo "Evidence: $EVIDENCE"

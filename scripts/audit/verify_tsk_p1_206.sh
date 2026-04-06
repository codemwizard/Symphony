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
AUDIT_DOC="$ROOT/docs/tasks/2026-03-14_security_optimization_traceability_audit.md"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_206_audit_truth_rebaseline.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"

errors=()

if [[ ! -f "$AUDIT_DOC" ]]; then
  errors+=("audit_doc_missing")
fi

echo "==> Verifying security optimization traceability audit rebaseline..."

# 1. Check for stale claims of current pre_ci or conformance failures
if [[ -f "$AUDIT_DOC" ]]; then
  if grep -q "failed (\`ModuleNotFoundError: yaml\`" "$AUDIT_DOC"; then
    errors+=("stale_conformance_failure_log")
  fi

  if grep -q "failed during toolchain bootstrap (network/proxy" "$AUDIT_DOC"; then
    errors+=("stale_proxy_failure_log")
  fi

  if grep -q "failed at \`dotnet CLI not found" "$AUDIT_DOC"; then
    errors+=("stale_dotnet_failure_log")
  fi

  # 2. Rewrite supervisor_api finding so we don't present stale local environment failures as current repo truth
  if ! grep -q "localhost-only bind" "$AUDIT_DOC"; then
    errors+=("missing_localhost_bind_posture")
  fi

  # 3. Check for prioritized backlog language
  if grep -q "legacy-shell remediation" "$AUDIT_DOC"; then
    errors+=("legacy_shell_remediation_still_present")
  fi
fi

# Produce evidence JSON
if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys
evidence_path, run_id, status, errors_csv = sys.argv[1:5]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "task_id": "TSK-P1-206",
    "run_id": run_id,
    "status": status,
    "audit_document_updated": "audit_doc_missing" not in errors,
    "stale_claims_removed": not any(e.startswith("stale_") for e in errors),
    "errors": errors
}
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: Audit correctly separates current truth from stale local-environment noise."
echo "Evidence: $EVIDENCE"

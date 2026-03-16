#!/usr/bin/env bash
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_221_hardened_docs_and_gates.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$(date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-221: Hardened Docs and Gates..."

# Files to check
PRE_CI_DEMO="$ROOT/scripts/dev/pre_ci_demo.sh"
DEMO_GUIDE="$ROOT/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md"
PROV_RUNBOOK="$ROOT/docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md"
PROGRAM_CS="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Program.cs"

# ─── 1. Check pre_ci_demo.sh for OpenBao / DB hardening ───
if grep -q "SYMPHONY_UI_TENANT_ID" "$PRE_CI_DEMO" 2>/dev/null; then
  errors+=("pre_ci_demo_still_uses_ui_tenant_id")
fi
if grep -q "INGRESS_STORAGE_MODE" "$PRE_CI_DEMO" 2>/dev/null; then
  errors+=("pre_ci_demo_still_uses_legacy_storage_mode")
fi
if ! grep -q "SYMPHONY_SECRETS_PROVIDER" "$PRE_CI_DEMO" 2>/dev/null; then
  errors+=("pre_ci_demo_missing_secrets_provider")
fi

# ─── 2. Check Demo Guide for provisional workarounds ───
if grep -q "INGRESS_STORAGE_MODE" "$DEMO_GUIDE" 2>/dev/null; then
  errors+=("demo_guide_still_uses_legacy_storage_mode")
fi
if ! grep -q "bash scripts/dev/bootstrap.sh" "$DEMO_GUIDE" 2>/dev/null; then
  errors+=("demo_guide_missing_canonical_bootstrap")
fi
if ! grep -q "SYMPHONY_SECRETS_PROVIDER=vault" "$DEMO_GUIDE" 2>/dev/null; then
  errors+=("demo_guide_missing_secrets_provider")
fi

# ─── 3. Check Provisioning Runbook for API use ───
if grep -q "POST /v1/admin/tenants" "$PROV_RUNBOOK" 2>/dev/null; then
  errors+=("prov_runbook_still_documents_v1_admin_tenants")
fi
if ! grep -q "POST /api/admin/onboarding/tenants" "$PROV_RUNBOOK" 2>/dev/null; then
  errors+=("prov_runbook_missing_onboarding_tenant_api")
fi
if ! grep -q "POST /api/admin/onboarding/programmes" "$PROV_RUNBOOK" 2>/dev/null; then
  errors+=("prov_runbook_missing_onboarding_programmes_api")
fi

# ─── 4. Check Program.cs for hardened readiness checks ───
if ! grep -q "secretProvider.IsHealthyAsync" "$PROGRAM_CS" 2>/dev/null; then
  errors+=("program_cs_missing_secret_provider_health_check")
fi
if ! grep -q "dataSource.OpenConnectionAsync" "$PROGRAM_CS" 2>/dev/null; then
  errors+=("program_cs_missing_db_connectivity_check")
fi
if ! grep -q "openbao_available = openBaoAvailable" "$PROGRAM_CS" 2>/dev/null; then
  errors+=("program_cs_missing_health_openbao_status")
fi
if ! grep -q 'Results.StatusCode(503)' "$PROGRAM_CS" 2>/dev/null; then
  errors+=("program_cs_readyz_missing_503_fail_closed")
fi

# ─── Emit evidence ───
if [[ ${#errors[@]} -eq 0 ]]; then status="PASS"; else status="FAIL"; fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
}

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$(evidence_now_utc)" "$(git_sha)" "$(schema_fingerprint)" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-221",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-221",
    "run_id": run_id,
    "checks": {
        "pre_ci_demo_hardened": "pre_ci_demo_still_uses_ui_tenant_id" not in errors and "pre_ci_demo_missing_secrets_provider" not in errors,
        "demo_guide_hardened": "demo_guide_still_uses_legacy_storage_mode" not in errors and "demo_guide_missing_canonical_bootstrap" not in errors,
        "prov_runbook_hardened": "prov_runbook_still_documents_v1_admin_tenants" not in errors and "prov_runbook_missing_onboarding_tenant_api" not in errors,
        "healthz_readyz_hardened": "program_cs_missing_secret_provider_health_check" not in errors and "program_cs_missing_db_connectivity_check" not in errors and "program_cs_missing_health_openbao_status" not in errors
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

echo "PASS: TSK-P1-221 Hardened deployment docs and gates verified."
echo "Evidence: $EVIDENCE"

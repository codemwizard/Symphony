#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> Fast security checks (cheap, deterministic)"

run() { echo ""; echo "-> $*"; "$@"; }

echo ""
echo "==> Shell syntax checks (scripts/security/*.sh)"
for f in scripts/security/*.sh; do
  [[ -f "$f" ]] || continue
  run bash -n "$f"
done

echo ""
echo "==> Required security scripts present"
REQ=(
  "scripts/security/lint_sql_injection.sh"
  "scripts/security/lint_privilege_grants.sh"
  "scripts/security/lint_core_boundary.sh"
  "scripts/security/scan_secrets.sh"
  "scripts/security/dotnet_dependency_audit.sh"
  "scripts/security/lint_secure_config.sh"
  "scripts/security/lint_insecure_patterns.sh"
)
for f in "${REQ[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing required file: $f"
    exit 1
  fi
done

echo ""
echo "==> Run security lints"
run scripts/security/lint_sql_injection.sh
run scripts/security/lint_privilege_grants.sh
run scripts/security/lint_core_boundary.sh
run scripts/security/scan_secrets.sh
run scripts/security/dotnet_dependency_audit.sh
run scripts/security/lint_secure_config.sh
run scripts/security/lint_insecure_patterns.sh
if [[ -x scripts/security/lint_ddl_lock_risk.sh || -f scripts/security/lint_ddl_lock_risk.sh ]]; then
  run scripts/security/lint_ddl_lock_risk.sh
fi
if [[ -x scripts/security/lint_security_definer_dynamic_sql.sh || -f scripts/security/lint_security_definer_dynamic_sql.sh ]]; then
  run scripts/security/lint_security_definer_dynamic_sql.sh
fi
if [[ -x scripts/security/verify_ddl_allowlist_governance.sh || -f scripts/security/verify_ddl_allowlist_governance.sh ]]; then
  run scripts/security/verify_ddl_allowlist_governance.sh
fi

echo ""
echo "==> SAST baseline (Semgrep; pinned in CI)"
if [[ -x scripts/security/run_semgrep_sast.sh || -f scripts/security/run_semgrep_sast.sh ]]; then
  run scripts/security/run_semgrep_sast.sh
  if [[ -x scripts/audit/verify_semgrep_sast_evidence.sh || -f scripts/audit/verify_semgrep_sast_evidence.sh ]]; then
    run scripts/audit/verify_semgrep_sast_evidence.sh
  else
    echo "ERROR: scripts/audit/verify_semgrep_sast_evidence.sh not found"
    exit 1
  fi
else
  echo "ERROR: scripts/security/run_semgrep_sast.sh not found"
  exit 1
fi

echo ""
echo "==> Policy stubs (presence + manifest reference)"
if [[ -x scripts/audit/verify_key_management_policy.sh || -f scripts/audit/verify_key_management_policy.sh ]]; then
  run scripts/audit/verify_key_management_policy.sh
else
  echo "ERROR: scripts/audit/verify_key_management_policy.sh not found"
  exit 1
fi
if [[ -x scripts/audit/verify_audit_logging_retention_policy.sh || -f scripts/audit/verify_audit_logging_retention_policy.sh ]]; then
  run scripts/audit/verify_audit_logging_retention_policy.sh
else
  echo "ERROR: scripts/audit/verify_audit_logging_retention_policy.sh not found"
  exit 1
fi

echo ""
echo "==> ISO 20022 and Zero Trust docs (presence + manifest reference)"
if [[ -x scripts/audit/verify_iso20022_readiness_docs.sh || -f scripts/audit/verify_iso20022_readiness_docs.sh ]]; then
  run scripts/audit/verify_iso20022_readiness_docs.sh
else
  echo "ERROR: scripts/audit/verify_iso20022_readiness_docs.sh not found"
  exit 1
fi
if [[ -x scripts/audit/verify_iso20022_contract_registry.sh || -f scripts/audit/verify_iso20022_contract_registry.sh ]]; then
  run scripts/audit/verify_iso20022_contract_registry.sh
else
  echo "ERROR: scripts/audit/verify_iso20022_contract_registry.sh not found"
  exit 1
fi
if [[ -x scripts/audit/verify_zero_trust_posture_docs.sh || -f scripts/audit/verify_zero_trust_posture_docs.sh ]]; then
  run scripts/audit/verify_zero_trust_posture_docs.sh
else
  echo "ERROR: scripts/audit/verify_zero_trust_posture_docs.sh not found"
  exit 1
fi

echo ""
echo "==> Regulated payload guardrails (Phase-0)"
if [[ -x scripts/audit/lint_pii_leakage_payloads.sh || -f scripts/audit/lint_pii_leakage_payloads.sh ]]; then
  run scripts/audit/lint_pii_leakage_payloads.sh
else
  echo "ERROR: scripts/audit/lint_pii_leakage_payloads.sh not found"
  exit 1
fi

echo ""
echo "==> Unit/self-tests (security plane)"
if [[ -x scripts/audit/tests/test_lint_pii_leakage_payloads.sh ]]; then
  run scripts/audit/tests/test_lint_pii_leakage_payloads.sh
else
  echo "   (no shell self-tests found; skipping)"
fi

echo ""
echo "✅ Fast security checks passed"

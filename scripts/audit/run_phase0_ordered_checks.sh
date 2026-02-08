#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "==> Phase-0 ordered checks (canonical order)"

run() { echo ""; echo "-> $*"; "$@"; }

# Order: YAML lint → control-plane drift → plane checks → evidence schema validate → contract check
run scripts/audit/lint_yaml_conventions.sh
run scripts/audit/verify_control_planes_drift.sh
run scripts/audit/verify_repo_structure.sh
run scripts/audit/generate_evidence.sh
run scripts/audit/enforce_change_rule.sh
run scripts/audit/verify_batching_rules.sh
run scripts/audit/verify_routing_fallback.sh
run scripts/audit/validate_routing_fallback.sh

run scripts/audit/run_security_fast_checks.sh

# OpenBao smoke must run before evidence status checks (contract requires openbao_smoke.json)
if [[ -x scripts/security/openbao_bootstrap.sh && -x scripts/security/openbao_smoke_test.sh ]]; then
  run scripts/security/openbao_bootstrap.sh
  run scripts/security/openbao_smoke_test.sh
else
  echo "ERROR: OpenBao scripts missing"
  exit 1
fi

# Contract evidence status is evaluated after evidence aggregation (cross-job) in CI.
# Skip inside ordered checks to avoid false negatives when evidence isn't yet merged.
# Toolchain parity is bootstrapped by scripts/dev/pre_ci.sh; do not skip locally.
export SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1
run scripts/audit/run_invariants_fast_checks.sh
unset SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS

run scripts/audit/validate_evidence_schema.sh
run bash scripts/audit/verify_phase0_contract.sh
run bash scripts/audit/verify_ci_order.sh

# Contract evidence status is evaluated after evidence aggregation (cross-job) in CI.
# Running it in the mechanical job will produce false negatives for DB/security evidence.
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  echo ""
  echo "-> (skipping) scripts/audit/verify_phase0_contract_evidence_status.sh (CI evidence is merged in contract_evidence_gate)"
else
  run bash scripts/audit/verify_phase0_contract_evidence_status.sh
fi

echo "✅ Phase-0 ordered checks PASSED."

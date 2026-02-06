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
run scripts/audit/verify_batching_rules.sh
run scripts/audit/verify_routing_fallback.sh
run scripts/audit/validate_routing_fallback.sh

run scripts/audit/run_security_fast_checks.sh

# Contract evidence status is evaluated after evidence aggregation (cross-job) in CI.
# Skip inside ordered checks to avoid false negatives when evidence isn't yet merged.
if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
  export SYMPHONY_SKIP_TOOLCHAIN_CHECK=1
fi
SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1 run scripts/audit/run_invariants_fast_checks.sh

run scripts/audit/validate_evidence_schema.sh
run bash scripts/audit/verify_phase0_contract.sh
run bash scripts/audit/verify_ci_order.sh

echo "✅ Phase-0 ordered checks PASSED."

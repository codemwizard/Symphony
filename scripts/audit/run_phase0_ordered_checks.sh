#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "==> Phase-0 ordered checks (canonical order)"

run() { echo ""; echo "-> $*"; "$@"; }

# Order: YAML lint → control-plane drift → plane checks → evidence schema validate → contract check
run scripts/audit/verify_diff_semantics_parity.sh
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
  if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is required for OpenBao smoke tests and is not available" >&2
    exit 1
  fi
  run scripts/security/openbao_bootstrap.sh
  run scripts/security/openbao_smoke_test.sh
else
  echo "ERROR: OpenBao scripts missing"
  exit 1
fi

# Contract evidence status is a cross-job/local-final gate. Skip it during the
# fast invariants pass; it will be executed after all evidence is produced.
run env SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1 scripts/audit/run_invariants_fast_checks.sh

run scripts/audit/validate_evidence_schema.sh
run bash scripts/audit/verify_phase0_contract.sh

if [[ "${RUN_PHASE1_GATES:-0}" == "1" ]]; then
  echo "==> Phase-1 contract gate deferred to post-DB verification in pre_ci.sh"
else
  echo "==> Phase-1 contract gate skipped (RUN_PHASE1_GATES=0)"
fi

run bash scripts/audit/verify_ci_order.sh
run bash scripts/audit/verify_ci_artifact_upload_phase0_evidence.sh

echo "✅ Phase-0 ordered checks PASSED."

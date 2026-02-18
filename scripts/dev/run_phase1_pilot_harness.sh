#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

scripts/services/test_ingress_api_contract.sh
scripts/services/test_executor_worker_runtime.sh
scripts/services/test_evidence_pack_api_contract.sh
scripts/services/test_exception_case_pack_generator.sh
if [[ -x scripts/audit/verify_pilot_harness_readiness.sh ]]; then
  scripts/audit/verify_pilot_harness_readiness.sh
fi

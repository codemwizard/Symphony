#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVICE_EVIDENCE_DIR="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/evidence/phase1"
ROOT_EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"

"$ROOT_DIR/scripts/audit/verify_tsk_p1_019.sh"

mkdir -p "$ROOT_EVIDENCE_DIR"
for evidence_file in \
  ingress_api_contract_tests.json \
  ingress_ack_attestation_semantics.json \
  evidence_pack_api_contract.json \
  evidence_pack_api_access_control.json \
  exception_case_pack_generation.json \
  exception_case_pack_completeness.json
do
  if [[ -f "$SERVICE_EVIDENCE_DIR/$evidence_file" ]]; then
    cp "$SERVICE_EVIDENCE_DIR/$evidence_file" "$ROOT_EVIDENCE_DIR/$evidence_file"
  fi
done

"$ROOT_DIR/scripts/audit/verify_product_kpi_readiness.sh"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-020 --evidence "$ROOT_DIR/evidence/phase1/product_kpi_readiness_report.json"

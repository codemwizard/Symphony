#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
REGULATOR_OUT="$EVIDENCE_DIR/regulator_demo_pack.json"
TIER1_OUT="$EVIDENCE_DIR/tier1_pilot_demo_pack.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP REGULATOR_OUT TIER1_OUT

python3 <<'PY'
import json
import os
import sys
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
regulator_out = Path(os.environ["REGULATOR_OUT"])
tier1_out = Path(os.environ["TIER1_OUT"])

def load(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None

def has_result(evidence: dict, result_name: str):
    for row in evidence.get("results", []) or []:
        name = row.get("name") or row.get("Name")
        status = (row.get("status") or row.get("Status") or "").upper()
        if name == result_name and status == "PASS":
            return True
    return False

sources = {
    "boz_role_read_only": root / "evidence/phase0/boz_observability_role.json",
    "pii_leakage_lint": root / "evidence/phase0/pii_leakage_payloads.json",
    "anchor_structural_hooks": root / "evidence/phase0/anchor_sync_hooks.json",
    "anchor_operational": root / "evidence/phase1/anchor_sync_operational_invariant.json",
    "anchor_resume": root / "evidence/phase1/anchor_sync_resume_semantics.json",
    "instruction_finality": root / "evidence/phase1/instruction_finality_runtime.json",
    "pii_purge_survivability": root / "evidence/phase1/pii_decoupling_runtime.json",
    "rail_sequence_continuity": root / "evidence/phase1/rail_sequence_runtime.json",
    "ingress_contract": root / "evidence/phase1/ingress_api_contract_tests.json",
    "executor_runtime": root / "evidence/phase1/executor_worker_runtime.json",
    "evidence_pack_api": root / "evidence/phase1/evidence_pack_api_contract.json",
    "exception_case_pack": root / "evidence/phase1/exception_case_pack_generation.json",
    "pilot_harness": root / "evidence/phase1/pilot_harness_replay.json",
    "kpi_readiness": root / "evidence/phase1/product_kpi_readiness_report.json",
    "authz_boundary": root / "evidence/phase1/authz_tenant_boundary.json",
    "boz_runtime_boundary": root / "evidence/phase1/boz_access_boundary_runtime.json",
}

loaded = {}
failures = []

for name, path in sources.items():
    if not path.exists():
        failures.append(f"missing_source:{name}:{path}")
        continue
    payload = load(path)
    if payload is None:
        failures.append(f"invalid_json:{name}:{path}")
        continue
    if (payload.get("status") or "").upper() != "PASS":
        failures.append(f"source_not_pass:{name}:{payload.get('status')}")
    loaded[name] = payload

if "boz_role_read_only" in loaded:
    if loaded["boz_role_read_only"].get("dml_privileges_present"):
        failures.append("boz_role_has_dml_privileges")
if "boz_runtime_boundary" in loaded:
    if loaded["boz_runtime_boundary"].get("boz_read_only_boundary_enforced") is not True:
        failures.append("boz_runtime_boundary_not_enforced")
if "evidence_pack_api" in loaded and not has_result(loaded["evidence_pack_api"], "contract_success_same_tenant"):
    failures.append("evidence_pack_contract_missing_same_tenant_success")
if "exception_case_pack" in loaded and not has_result(loaded["exception_case_pack"], "case_pack_complete_success"):
    failures.append("exception_case_pack_missing_complete_success")
if "ingress_contract" in loaded and not has_result(loaded["ingress_contract"], "ack_after_durable_attestation"):
    failures.append("ingress_missing_ack_after_durable_attestation")

status = "PASS" if not failures else "FAIL"

source_rel = {k: str(v.relative_to(root)) for k, v in sources.items()}

regulator_claims = [
    {"claim": "BoZ regulator seat is read-only with write denial", "source": source_rel["boz_role_read_only"]},
    {"claim": "BoZ runtime access boundary is enforced", "source": source_rel["boz_runtime_boundary"]},
    {"claim": "Payment finality mutation denial is deterministic", "source": source_rel["instruction_finality"]},
    {"claim": "PII purge survivability preserves evidence validity", "source": source_rel["pii_purge_survivability"]},
    {"claim": "Rail sequence continuity is enforced on successful dispatch", "source": source_rel["rail_sequence_continuity"]},
    {"claim": "Anchor-sync operational completion and resume semantics are enforced", "source": source_rel["anchor_operational"]},
    {"claim": "Anchor resume-after-expiry is deterministic", "source": source_rel["anchor_resume"]},
    {"claim": "ZDPA PII leakage lint remains fail-closed", "source": source_rel["pii_leakage_lint"]},
]

tier1_claims = [
    {"claim": "Ingress API only acknowledges after durable attestation", "source": source_rel["ingress_contract"]},
    {"claim": "Executor worker dispatch path is deterministic and fail-closed", "source": source_rel["executor_runtime"]},
    {"claim": "Evidence Pack API retrieves same-tenant packs deterministically", "source": source_rel["evidence_pack_api"]},
    {"claim": "Exception case-pack generation is deterministic and complete", "source": source_rel["exception_case_pack"]},
    {"claim": "Pilot harness replay is deterministic", "source": source_rel["pilot_harness"]},
    {"claim": "Tenant/participant authorization boundaries are enforced", "source": source_rel["authz_boundary"]},
    {"claim": "Product KPI evidence gate meets thresholds", "source": source_rel["kpi_readiness"]},
]

common = {
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "source_evidence": source_rel,
    "failures": failures,
}

regulator_payload = {
    "check_id": "PHASE1-REGULATOR-DEMO-PACK",
    "schema_version": "phase1-demo-pack-v1",
    **common,
    "audience": "Bank of Zambia",
    "claims": regulator_claims,
}

tier1_payload = {
    "check_id": "PHASE1-TIER1-PILOT-DEMO-PACK",
    "schema_version": "phase1-demo-pack-v1",
    **common,
    "audience": "Tier-1 FI Pilot",
    "claims": tier1_claims,
}

regulator_out.write_text(json.dumps(regulator_payload, indent=2) + "\n", encoding="utf-8")
tier1_out.write_text(json.dumps(tier1_payload, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Phase-1 demo-proof pack verification failed", file=sys.stderr)
    for item in failures:
        print(f" - {item}", file=sys.stderr)
    sys.exit(1)

print(f"Phase-1 regulator demo pack verification passed. Evidence: {regulator_out}")
print(f"Phase-1 tier-1 demo pack verification passed. Evidence: {tier1_out}")
PY

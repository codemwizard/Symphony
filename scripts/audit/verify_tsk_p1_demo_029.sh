#!/usr/bin/env bash
set -euo pipefail
DOC="docs/operations/GREENTECH4CE_DEMO_PROVISIONING_SAMPLE_PACK.md"
JSON_SAMPLE="docs/operations/GREENTECH4CE_DEMO_PROVISIONING_SAMPLE_PACK.sample.json"
EVIDENCE="evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json"
python3 - <<'PY' "$DOC" "$JSON_SAMPLE" "$EVIDENCE"
import json
import sys
from pathlib import Path

doc_path = Path(sys.argv[1])
json_path = Path(sys.argv[2])
evidence_path = Path(sys.argv[3])

missing = []
if not doc_path.exists():
    missing.append(str(doc_path))
if not json_path.exists():
    missing.append(str(json_path))
if missing:
    evidence_path.parent.mkdir(parents=True, exist_ok=True)
    evidence_path.write_text(json.dumps({
        "task_id": "TSK-P1-DEMO-029",
        "status": "FAIL",
        "pass": False,
        "missing_files": missing,
    }, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(1)

doc = doc_path.read_text(encoding="utf-8")
sample = json.loads(json_path.read_text(encoding="utf-8"))

required_doc_strings = [
    "PGM-ZAMBIA-GRN-001",
    "v1.0.0",
    "SUP-ECOTECH-001",
    "SUP-SOLARFIX-001",
    "SUP-BLOCKED-001",
    "demo-report-target-greentech4ce-zm",
    "demo-evidence-target-greentech4ce-zm",
    "POST /v1/admin/tenants",
    "POST /v1/admin/suppliers/upsert",
    "POST /v1/admin/program-supplier-allowlist/upsert",
    "GET /v1/programs/{programId}/suppliers/{supplierId}/policy",
    "ALLOW",
    "DENY",
    "This sample pack does not by itself grant full-demo signoff.",
    "OpenBao / INF-006 signoff posture passes",
    "operator-confirmed",
]
missing_doc = [item for item in required_doc_strings if item not in doc]

expected = {
    "tenant_id": "11111111-1111-1111-1111-111111111111",
    "tenant_display_name": "GreenTech4CE Zambia Demo Tenant",
    "jurisdiction_code": "ZM",
    "plan": "pilot-demo",
    "program_id": "PGM-ZAMBIA-GRN-001",
    "policy_version": "v1.0.0",
    "reporting_target_id": "demo-report-target-greentech4ce-zm",
    "evidence_routing_target_id": "demo-evidence-target-greentech4ce-zm",
}
json_failures = []
if sample.get("tenant", {}).get("tenant_id") != expected["tenant_id"]:
    json_failures.append("tenant_id")
if sample.get("tenant", {}).get("tenant_display_name") != expected["tenant_display_name"]:
    json_failures.append("tenant_display_name")
if sample.get("tenant", {}).get("jurisdiction_code") != expected["jurisdiction_code"]:
    json_failures.append("jurisdiction_code")
if sample.get("tenant", {}).get("plan") != expected["plan"]:
    json_failures.append("plan")
if sample.get("programme", {}).get("program_id") != expected["program_id"]:
    json_failures.append("program_id")
if sample.get("programme", {}).get("policy_version") != expected["policy_version"]:
    json_failures.append("policy_version")
if sample.get("routing", {}).get("reporting_target_id") != expected["reporting_target_id"]:
    json_failures.append("reporting_target_id")
if sample.get("routing", {}).get("evidence_routing_target_id") != expected["evidence_routing_target_id"]:
    json_failures.append("evidence_routing_target_id")

suppliers = {item.get("supplier_id"): item for item in sample.get("suppliers", [])}
required_suppliers = {
    "SUP-ECOTECH-001": "ALLOW",
    "SUP-SOLARFIX-001": "ALLOW",
    "SUP-BLOCKED-001": "DENY",
}
for supplier_id, decision in required_suppliers.items():
    item = suppliers.get(supplier_id)
    if not item:
        json_failures.append(f"missing_supplier:{supplier_id}")
        continue
    if item.get("expected_policy_decision") != decision:
        json_failures.append(f"bad_decision:{supplier_id}")

cross_mismatch = []
for token in [
    expected["tenant_id"],
    expected["tenant_display_name"],
    expected["program_id"],
    expected["policy_version"],
    expected["reporting_target_id"],
    expected["evidence_routing_target_id"],
]:
    if token not in doc:
        cross_mismatch.append(token)

payload = {
    "task_id": "TSK-P1-DEMO-029",
    "status": "PASS" if not (missing_doc or json_failures or cross_mismatch) else "FAIL",
    "pass": not (missing_doc or json_failures or cross_mismatch),
    "document": str(doc_path),
    "sample_json": str(json_path),
    "missing_doc_strings": missing_doc,
    "json_failures": json_failures,
    "cross_mismatch": cross_mismatch,
    "verified_endpoints": sample.get("repo_backed_endpoints", []),
}

evidence_path.parent.mkdir(parents=True, exist_ok=True)
evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
if payload["status"] != "PASS":
    raise SystemExit(1)
PY

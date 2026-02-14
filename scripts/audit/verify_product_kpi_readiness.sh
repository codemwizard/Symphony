#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
REPORT_FILE="$EVIDENCE_DIR/product_kpi_readiness_report.json"
MAX_AGE_MINUTES="${KPI_MAX_AGE_MINUTES:-180}"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR REPORT_FILE MAX_AGE_MINUTES EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
report_file = Path(os.environ["REPORT_FILE"])
max_age_minutes = int(os.environ["MAX_AGE_MINUTES"])

required_sources = {
    "ingress_contract": root / "evidence/phase1/ingress_api_contract_tests.json",
    "executor_runtime": root / "evidence/phase1/executor_worker_runtime.json",
    "evidence_pack_contract": root / "evidence/phase1/evidence_pack_api_contract.json",
    "exception_case_pack": root / "evidence/phase1/exception_case_pack_generation.json",
    "pilot_harness": root / "evidence/phase1/pilot_harness_replay.json",
    "pilot_onboarding": root / "evidence/phase1/pilot_onboarding_readiness.json",
}

failures = []
loaded = {}
now = datetime.now(timezone.utc)

def parse_ts(value: str):
    try:
        if value.endswith("Z"):
            value = value.replace("Z", "+00:00")
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None

for name, path in required_sources.items():
    if not path.exists():
        failures.append(f"missing_source:{name}:{path}")
        continue
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        failures.append(f"invalid_json:{name}:{path}")
        continue

    status = str(data.get("status", "")).upper()
    if status != "PASS":
        failures.append(f"source_not_pass:{name}:{status}")

    ts_raw = str(data.get("timestamp_utc", ""))
    ts_parsed = parse_ts(ts_raw)
    if ts_parsed is None:
        failures.append(f"invalid_timestamp:{name}:{ts_raw}")
    else:
        age_min = (now - ts_parsed).total_seconds() / 60
        if age_min > max_age_minutes:
            failures.append(f"stale_source:{name}:age_minutes={age_min:.1f}")

    loaded[name] = data

# KPI metric derivation from deterministic evidence sources.
ack_determinism_pct = 0.0
duplicate_suppression_pct = 0.0
evidence_casepack_coverage_pct = 0.0
investigation_readiness_pct = 0.0
retry_fail_closed_pct = 0.0

if "ingress_contract" in loaded:
    ingress = loaded["ingress_contract"]
    passed = float(ingress.get("tests_passed", 0) or 0)
    failed = float(ingress.get("tests_failed", 0) or 0)
    total = passed + failed
    if total > 0:
        ack_determinism_pct = round((passed / total) * 100.0, 2)

# Duplicate suppression proxy: deterministic pilot harness + ingress contract pass.
if all(name in loaded for name in ("pilot_harness", "ingress_contract")):
    duplicate_suppression_pct = 100.0 if (
        loaded["pilot_harness"].get("status") == "PASS"
        and loaded["ingress_contract"].get("status") == "PASS"
    ) else 0.0

if all(name in loaded for name in ("evidence_pack_contract", "exception_case_pack")):
    ok = int(loaded["evidence_pack_contract"].get("status") == "PASS") + int(loaded["exception_case_pack"].get("status") == "PASS")
    evidence_casepack_coverage_pct = round((ok / 2.0) * 100.0, 2)

if all(name in loaded for name in ("pilot_harness", "pilot_onboarding")):
    investigation_readiness_pct = 100.0 if (
        loaded["pilot_harness"].get("status") == "PASS"
        and loaded["pilot_onboarding"].get("status") == "PASS"
    ) else 0.0

if "executor_runtime" in loaded:
    ex = loaded["executor_runtime"]
    rows = ex.get("results", [])
    targeted = [r for r in rows if (r.get("name") or r.get("Name") or "").lower().find("fail_closed") >= 0 or (r.get("name") or r.get("Name") or "").lower().find("lease_fencing") >= 0]
    if targeted:
        pass_count = sum(1 for r in targeted if (r.get("status") or r.get("Status")) == "PASS")
        retry_fail_closed_pct = round((pass_count / len(targeted)) * 100.0, 2)

kpis = {
    "ack_determinism_pct": ack_determinism_pct,
    "duplicate_suppression_effectiveness_pct": duplicate_suppression_pct,
    "evidence_casepack_generation_coverage_pct": evidence_casepack_coverage_pct,
    "investigation_readiness_pct": investigation_readiness_pct,
    "retry_fail_closed_enforcement_pct": retry_fail_closed_pct,
}

thresholds = {
    "ack_determinism_pct": 100.0,
    "duplicate_suppression_effectiveness_pct": 100.0,
    "evidence_casepack_generation_coverage_pct": 100.0,
    "investigation_readiness_pct": 100.0,
    "retry_fail_closed_enforcement_pct": 100.0,
}

kpi_failures = [
    f"kpi_below_threshold:{name}:{value}<{thresholds[name]}"
    for name, value in kpis.items()
    if value < thresholds[name]
]
failures.extend(kpi_failures)

status = "PASS" if not failures else "FAIL"

report = {
    "check_id": "PHASE1-PRODUCT-KPI-READINESS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "max_source_age_minutes": max_age_minutes,
    "source_evidence": {k: str(v.relative_to(root)) for k, v in required_sources.items()},
    "kpis": kpis,
    "thresholds": thresholds,
    "ready_for_product_review": status == "PASS",
    "failures": failures,
}

report_file.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Product KPI readiness verification failed", file=sys.stderr)
    for item in failures:
        print(f" - {item}", file=sys.stderr)
    sys.exit(1)

print(f"Product KPI readiness verification passed. Evidence: {report_file}")
PY

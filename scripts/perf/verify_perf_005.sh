#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH="${EVIDENCE_PATH:-$ROOT_DIR/evidence/phase1/perf_005__regulatory_timing_compliance_gate.json}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "unknown_arg:$1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

PROFILE_EVIDENCE="$ROOT_DIR/evidence/phase1/perf_smoke_profile.json"
if [[ ! -f "$PROFILE_EVIDENCE" ]]; then
  echo "missing_perf_smoke_profile:$PROFILE_EVIDENCE" >&2
  exit 1
fi

ROOT_DIR="$ROOT_DIR" PROFILE_EVIDENCE="$PROFILE_EVIDENCE" EVIDENCE_PATH="$EVIDENCE_PATH" EVIDENCE_TS="$EVIDENCE_TS" EVIDENCE_GIT_SHA="$EVIDENCE_GIT_SHA" EVIDENCE_SCHEMA_FP="$EVIDENCE_SCHEMA_FP" python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
profile_path = Path(os.environ["PROFILE_EVIDENCE"])
out_path = Path(os.environ["EVIDENCE_PATH"])

profile = json.loads(profile_path.read_text(encoding="utf-8"))
summary = profile.get("summary") or {}
p95 = summary.get("p95_ms")
if not isinstance(p95, (int, float)) or p95 <= 0:
    raise SystemExit("invalid_p95_from_perf_smoke")

# Phase-1 compliance uses simulated finality inputs derived from the deterministic perf smoke profile.
rail_policies = {
    "ZM-NFS": {"settlement_window_ms": 2500, "source": "simulated"},
    "ZM-MMO": {"settlement_window_ms": 6000, "source": "simulated"},
}

rail_measurements = {
    "ZM-NFS": int(p95),
    "ZM-MMO": int(p95 + 500),
}

results = []
compliant = 0
for rail, policy in rail_policies.items():
    observed_ms = rail_measurements[rail]
    within = observed_ms <= int(policy["settlement_window_ms"])
    compliant += int(within)
    results.append({
        "rail": rail,
        "settlement_window_ms": int(policy["settlement_window_ms"]),
        "observed_finality_ms": observed_ms,
        "compliant": within,
        "measurement_truth": "simulated_from_perf_smoke_profile",
        "finality_source": "simulated",
    })

compliance_pct = round((compliant / len(results)) * 100.0, 2)
status = "PASS" if compliant == len(results) else "FAIL"

out = {
    "check_id": "PERF-005",
    "task_id": "PERF-005",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "pass": status == "PASS",
    "details": {
      "policy_version": 1,
      "workload_profile": profile.get("profile", {}).get("runner", "unknown"),
      "measurement_truth": "simulated_finality_inputs",
      "source_evidence": "evidence/phase1/perf_smoke_profile.json",
      "rails": results,
      "compliance_pct": compliance_pct,
      "compliant_rails": compliant,
      "total_rails": len(results)
    }
}
out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if status != "PASS":
    raise SystemExit(1)
print(f"PERF-005 compliance evidence: {out_path}")
PY

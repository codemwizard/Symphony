#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase1/perf_002_regression_detection_warmup.json"
SMOKE_FILE="$ROOT_DIR/evidence/phase1/perf_smoke_profile.json"
BASELINE_FILE="${PERF_BASELINE_FILE:-$ROOT_DIR/docs/operations/perf_smoke_baseline.json}"

"$ROOT_DIR/scripts/audit/run_perf_smoke.sh"

python3 - <<PY
import json
from pathlib import Path

evidence_path = Path(r"$EVIDENCE_FILE")
smoke_path = Path(r"$SMOKE_FILE")
baseline_path = Path(r"$BASELINE_FILE")

if not evidence_path.exists():
    raise SystemExit("missing_evidence:perf_002_regression_detection_warmup.json")
if not smoke_path.exists():
    raise SystemExit("missing_evidence:perf_smoke_profile.json")
if not baseline_path.exists():
    raise SystemExit("missing_baseline:docs/operations/perf_smoke_baseline.json")

evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
smoke = json.loads(smoke_path.read_text(encoding="utf-8"))
baseline = json.loads(baseline_path.read_text(encoding="utf-8"))

if evidence.get("task_id") != "PERF-002":
    raise SystemExit("task_id_mismatch")
if evidence.get("status") != "PASS" or evidence.get("pass") is not True:
    raise SystemExit("evidence_not_pass")

details = evidence.get("details", {})
warmup = details.get("warmup", {})
if warmup.get("enabled") is not True:
    raise SystemExit("warmup_not_enabled")
warmup_requests = int(warmup.get("warmup_requests", 0))
total_requests = int(warmup.get("total_requests", 0))
if warmup_requests < 50:
    raise SystemExit("warmup_requests_below_minimum")
if total_requests <= 0:
    raise SystemExit("invalid_total_requests")
if warmup_requests < max(50, int(total_requests * 0.10)):
    raise SystemExit("warmup_ratio_not_met")
if warmup.get("discarded_results") is not True:
    raise SystemExit("warmup_results_not_discarded")

classification = details.get("regression_classification")
if classification not in {"PASS", "SOFT_REGRESSION"}:
    raise SystemExit(f"invalid_regression_classification:{classification}")
if details.get("regression_enforced") is not True:
    raise SystemExit("regression_not_enforced")

if details.get("thresholds_source") != "docs/operations/perf_smoke_baseline.json":
    raise SystemExit("threshold_source_mismatch")

soft = details.get("soft_regression_threshold_pct")
hard = details.get("hard_regression_threshold_pct")
if soft != baseline.get("soft_regression_threshold_pct"):
    raise SystemExit("soft_threshold_not_from_baseline")
if hard != baseline.get("hard_regression_threshold_pct"):
    raise SystemExit("hard_threshold_not_from_baseline")

smoke_class = smoke.get("regression_classification")
if smoke_class != classification:
    raise SystemExit("classification_mismatch_with_smoke")

print("PERF-002 regression detection + warmup verification passed")
PY

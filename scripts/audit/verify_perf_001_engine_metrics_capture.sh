#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase1/perf_001_engine_metrics_capture.json"

"$ROOT_DIR/scripts/perf/capture_engine_metrics.sh"

python3 - <<PY
import json
from pathlib import Path

p = Path("$EVIDENCE_FILE")
if not p.exists():
    raise SystemExit("missing_evidence:perf_001_engine_metrics_capture.json")

d = json.loads(p.read_text(encoding="utf-8"))
if d.get("task_id") != "PERF-001":
    raise SystemExit("task_id_mismatch")
if d.get("status") != "PASS" or d.get("pass") is not True:
    raise SystemExit("evidence_not_pass")

details = d.get("details", {})
metrics = details.get("engine_metrics", {})
required = ["cpu_user_ms", "cpu_sys_ms", "gc_collections", "db_query_count", "db_query_p95_ms"]
missing = [k for k in required if k not in metrics]
if missing:
    raise SystemExit(f"missing_engine_metrics:{missing}")
if metrics.get("db_query_count", 0) <= 0:
    raise SystemExit("db_query_count_not_positive")
if details.get("trace_debug_logging_enabled") is not False:
    raise SystemExit("trace_debug_logging_enabled")
if details.get("non_invasive_capture") is not True:
    raise SystemExit("non_invasive_capture_not_true")
print("PERF-001 engine metrics capture verification passed")
PY

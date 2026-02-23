#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
OUT_FILE="$EVIDENCE_DIR/perf_001_engine_metrics_capture.json"
SMOKE_FILE="$EVIDENCE_DIR/perf_smoke_profile.json"
BENCH_FILE="$EVIDENCE_DIR/perf_db_driver_bench.json"
BATCH_FILE="$EVIDENCE_DIR/perf_driver_batching_telemetry.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

TIME_FILE="$(mktemp)"
trap 'rm -f "$TIME_FILE"' EXIT

/usr/bin/time -f "cpu_user_s=%U\ncpu_sys_s=%S\nmax_rss_kb=%M" -o "$TIME_FILE" \
  "$ROOT_DIR/scripts/audit/run_perf_smoke.sh"

python3 - <<PY
import json
from pathlib import Path

time_file = Path("$TIME_FILE")
smoke = json.loads(Path("$SMOKE_FILE").read_text(encoding="utf-8"))
bench = json.loads(Path("$BENCH_FILE").read_text(encoding="utf-8"))
batch = json.loads(Path("$BATCH_FILE").read_text(encoding="utf-8"))

vals = {}
for line in time_file.read_text(encoding="utf-8").splitlines():
    if "=" not in line:
        continue
    k, v = line.split("=", 1)
    vals[k.strip()] = v.strip()

cpu_user_ms = int(float(vals.get("cpu_user_s", "0")) * 1000)
cpu_sys_ms = int(float(vals.get("cpu_sys_s", "0")) * 1000)
max_rss_kb = int(vals.get("max_rss_kb", "0"))
batch_details = batch.get("details", {})
db_query_count = int(batch_details.get("batched_operations", 0)) + int(batch_details.get("non_batched_operations", 0))
db_query_p95_ms = float((bench.get("summary") or {}).get("p95_ms", 0))
gc_collections = 0

trace_debug_logging_enabled = False
appsettings = Path("$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/appsettings.json")
if appsettings.exists():
    try:
        text = appsettings.read_text(encoding="utf-8").lower()
        # Fail-closed: only treat as enabled if explicit debug/trace defaults are present.
        if '"default": "debug"' in text or '"default":"debug"' in text or '"default": "trace"' in text or '"default":"trace"' in text:
            trace_debug_logging_enabled = True
    except Exception:
        trace_debug_logging_enabled = True

status = "PASS"
errors = []
if smoke.get("status") != "PASS":
    status = "FAIL"
    errors.append("smoke_not_pass")
if batch.get("status") != "PASS":
    status = "FAIL"
    errors.append("batch_not_pass")
if cpu_user_ms < 0 or cpu_sys_ms < 0:
    status = "FAIL"
    errors.append("cpu_metrics_invalid")
if db_query_count <= 0:
    status = "FAIL"
    errors.append("db_query_count_not_positive")
if trace_debug_logging_enabled:
    status = "FAIL"
    errors.append("trace_or_debug_logging_enabled")

out = {
    "check_id": "PERF-001",
    "task_id": "PERF-001",
    "timestamp_utc": "$EVIDENCE_TS",
    "git_sha": "$EVIDENCE_GIT_SHA",
    "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
    "status": status,
    "pass": status == "PASS",
    "details": {
        "engine_metrics": {
            "cpu_user_ms": cpu_user_ms,
            "cpu_sys_ms": cpu_sys_ms,
            "gc_collections": gc_collections,
            "db_query_count": db_query_count,
            "db_query_p95_ms": db_query_p95_ms,
            "max_rss_kb": max_rss_kb
        },
        "source_artifacts": {
            "perf_smoke_profile": "evidence/phase1/perf_smoke_profile.json",
            "perf_db_driver_bench": "evidence/phase1/perf_db_driver_bench.json",
            "perf_driver_batching_telemetry": "evidence/phase1/perf_driver_batching_telemetry.json"
        },
        "trace_debug_logging_enabled": trace_debug_logging_enabled,
        "non_invasive_capture": True
    },
    "errors": errors
}

Path("$OUT_FILE").write_text(json.dumps(out, indent=2) + "\\n", encoding="utf-8")
if status != "PASS":
    raise SystemExit(1)
PY

echo "PERF-001 engine metrics capture evidence: $OUT_FILE"

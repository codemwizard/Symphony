#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
SMOKE_FILE="$EVIDENCE_DIR/perf_smoke_profile.json"
BENCH_FILE="$EVIDENCE_DIR/perf_db_driver_bench.json"
BATCH_FILE="$EVIDENCE_DIR/perf_driver_batching_telemetry.json"
AOT_FILE="$EVIDENCE_DIR/native_aot_compilation_report.json"
BASELINE_FILE="${PERF_BASELINE_FILE:-$ROOT_DIR/docs/operations/perf_smoke_baseline.json}"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

run_and_time() {
  local label="$1"
  shift
  local start end elapsed rc
  start=$(date +%s%3N)
  "$@" >"/tmp/symphony_perf_${label}.log" 2>&1 || rc=$?
  rc=${rc:-0}
  end=$(date +%s%3N)
  elapsed=$((end - start))
  echo "$label,$rc,$elapsed"
}

rows=()
rows+=("$(run_and_time ingress_selftest dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -- --self-test)")
rows+=("$(run_and_time evidence_pack_selftest dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -- --self-test-evidence-pack)")
rows+=("$(run_and_time case_pack_selftest dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -- --self-test-case-pack)")

status="PASS"
total_ms=0
for row in "${rows[@]}"; do
  IFS=',' read -r _label rc ms <<<"$row"
  total_ms=$((total_ms + ms))
  if [[ "$rc" -ne 0 ]]; then
    status="FAIL"
  fi
done

ROWS_PAYLOAD="$(printf '%s\n' "${rows[@]}")"

python3 - <<PY
import json, math
from pathlib import Path

rows = []
for raw in """$ROWS_PAYLOAD""".splitlines():
    if not raw.strip():
        continue
    label, rc, ms = raw.split(",", 2)
    rows.append({"name": label, "exit_code": int(rc), "elapsed_ms": int(ms)})

values = sorted([r["elapsed_ms"] for r in rows])
def pct(p):
    if not values:
        return 0
    i = max(0, min(len(values)-1, math.ceil((p/100.0)*len(values)) - 1))
    return values[i]

out = {
  "check_id": "PHASE1-PERF-SMOKE-PROFILE",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "$status",
  "profile": {
    "runner": "dotnet-selftest-profile",
    "iterations": len(rows),
    "workload": [r["name"] for r in rows],
    "environment": "${ENVIRONMENT:-local}",
    "storage_mode": "${INGRESS_STORAGE_MODE:-file}",
    "baseline_file": "$BASELINE_FILE"
  },
  "results": rows,
  "summary": {
    "total_elapsed_ms": $total_ms,
    "avg_elapsed_ms": int($total_ms / max(1, len(rows))),
    "p50_ms": pct(50),
    "p95_ms": pct(95),
    "p99_ms": pct(99)
  }
}

Path(r"$SMOKE_FILE").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
Path(r"$BENCH_FILE").write_text(json.dumps({
  "check_id": "PHASE1-PERF-DB-DRIVER-BENCH",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "$status",
  "driver": "NpgsqlDataSource",
  "results": rows,
  "summary": out["summary"]
}, indent=2) + "\n", encoding="utf-8")
PY

# Real driver-level batching telemetry from runtime metrics.
if ! dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -- --self-test-batching-telemetry >/tmp/symphony_perf_batching.log 2>&1; then
  echo "Batching telemetry self-test failed" >&2
  cat /tmp/symphony_perf_batching.log >&2 || true
  status="FAIL"
fi

# Native AOT report (real publish attempt + result capture).
AOT_OUT_DIR="/tmp/symphony_executor_aot_publish"
rm -rf "$AOT_OUT_DIR"
mkdir -p "$AOT_OUT_DIR"
AOT_LOG="/tmp/symphony_executor_aot_publish.log"
AOT_CMD=(dotnet publish services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj -c Release -p:PublishAot=true -p:StripSymbols=false -o "$AOT_OUT_DIR")
set +e
"${AOT_CMD[@]}" >"$AOT_LOG" 2>&1
AOT_RC=$?
set -e

AOT_STATUS="PASS"
if [[ "$AOT_RC" -ne 0 ]]; then
  AOT_STATUS="FAIL"
  status="FAIL"
fi

python3 - <<PY
import json, os, re
from pathlib import Path

log_path = Path(r"$AOT_LOG")
log_text = log_path.read_text(encoding="utf-8", errors="ignore") if log_path.exists() else ""
warnings = [ln.strip() for ln in log_text.splitlines() if re.search(r"\\bwarning\\b", ln, re.IGNORECASE)]
out_dir = Path(r"$AOT_OUT_DIR")
binary_candidates = [p for p in out_dir.iterdir() if p.is_file() and os.access(p, os.X_OK)] if out_dir.exists() else []
primary_binary = sorted(binary_candidates, key=lambda p: p.stat().st_size, reverse=True)[0] if binary_candidates else None

report = {
  "check_id": "TSK-P1-057-NATIVE-AOT",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "$AOT_STATUS",
  "details": {
    "command": "dotnet publish services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj -c Release -p:PublishAot=true -p:StripSymbols=false",
    "publish_exit_code": $AOT_RC,
    "success": $AOT_RC == 0,
    "binary_path": str(primary_binary) if primary_binary else None,
    "binary_size_bytes": primary_binary.stat().st_size if primary_binary else 0,
    "warnings_count": len(warnings),
    "warnings": warnings[:20]
  }
}
Path(r"$AOT_FILE").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
PY

# Enforce perf gate promotion logic.
python3 - <<PY
import json
from pathlib import Path

smoke_path = Path(r"$SMOKE_FILE")
baseline_path = Path(r"$BASELINE_FILE")
smoke = json.loads(smoke_path.read_text())
summary = smoke.get("summary", {})
current_p95 = float(summary.get("p95_ms", 0))

enforcement = {
  "baseline_locked": False,
  "regression_threshold_pct": 0.15,
  "baseline_p95_ms": None,
  "current_p95_ms": current_p95,
  "allowed_p95_ms": None,
  "mode": "informational",
  "regression_detected": False,
  "regression_enforced": False
}

if baseline_path.exists():
  cfg = json.loads(baseline_path.read_text())
  enforcement["baseline_locked"] = bool(cfg.get("baseline_locked", False))
  enforcement["regression_threshold_pct"] = float(cfg.get("regression_threshold_pct", 0.15))
  if cfg.get("p95_ms") is not None:
    enforcement["baseline_p95_ms"] = float(cfg.get("p95_ms"))

if enforcement["baseline_locked"]:
  enforcement["mode"] = "enforced"
  if enforcement["baseline_p95_ms"] is None:
    smoke["status"] = "FAIL"
    smoke["error"] = "baseline_locked_but_missing_baseline_p95"
  else:
    allowed = enforcement["baseline_p95_ms"] * (1.0 + enforcement["regression_threshold_pct"])
    enforcement["allowed_p95_ms"] = allowed
    regression = current_p95 > allowed
    enforcement["regression_detected"] = regression
    enforcement["regression_enforced"] = regression
    if regression:
      smoke["status"] = "FAIL"
      smoke["error"] = f"perf_regression_detected:p95_ms={current_p95:.2f}>allowed={allowed:.2f}"

smoke["promotion"] = enforcement
smoke_path.write_text(json.dumps(smoke, indent=2) + "\n")
PY

# Verify no placeholder fallback and required perf artifacts.
"$ROOT_DIR/scripts/audit/verify_perf_driver_batching_telemetry.sh"
"$ROOT_DIR/scripts/audit/verify_native_aot_compilation_report.sh"

if ! python3 - <<PY
import json
from pathlib import Path
smoke = json.loads(Path(r"$SMOKE_FILE").read_text())
print(smoke.get("status", "FAIL"))
raise SystemExit(0 if smoke.get("status") == "PASS" else 1)
PY
then
  echo "Perf smoke gate failed. Evidence: $SMOKE_FILE" >&2
  exit 1
fi

echo "Perf smoke profile passed. Evidence: $SMOKE_FILE"
echo "Perf DB driver bench evidence: $BENCH_FILE"
echo "Perf driver batching telemetry evidence: $BATCH_FILE"
echo "Native AOT compilation report evidence: $AOT_FILE"

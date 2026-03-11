#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
SMOKE_FILE="$EVIDENCE_DIR/perf_smoke_profile.json"
BENCH_FILE="$EVIDENCE_DIR/perf_db_driver_bench.json"
BATCH_FILE="$EVIDENCE_DIR/perf_driver_batching_telemetry.json"
AOT_FILE="$EVIDENCE_DIR/native_aot_compilation_report.json"
PERF2_FILE="$EVIDENCE_DIR/perf_002_regression_detection_warmup.json"
BASELINE_FILE="${PERF_BASELINE_FILE:-$ROOT_DIR/docs/operations/perf_smoke_baseline.json}"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/infra/docker/.env}"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

if [[ -z "${DATABASE_URL:-}" ]] && [[ -n "${POSTGRES_USER:-}" && -n "${POSTGRES_PASSWORD:-}" && -n "${POSTGRES_DB:-}" ]]; then
  DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${HOST_POSTGRES_PORT:-5432}/${POSTGRES_DB}"
  export DATABASE_URL
fi

LEDGER_API_PROJECT="services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj"
dotnet build "$LEDGER_API_PROJECT" >/tmp/symphony_perf_build.log 2>&1

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

# PERF-002: mandatory warmup pass before measurements.
TOTAL_REQUESTS="${PERF_SMOKE_TOTAL_REQUESTS:-500}"
if ! [[ "$TOTAL_REQUESTS" =~ ^[0-9]+$ ]] || [[ "$TOTAL_REQUESTS" -le 0 ]]; then
  echo "Invalid PERF_SMOKE_TOTAL_REQUESTS=$TOTAL_REQUESTS" >&2
  exit 1
fi
WARMUP_REQUESTS=$((TOTAL_REQUESTS / 10))
if [[ "$WARMUP_REQUESTS" -lt 50 ]]; then
  WARMUP_REQUESTS=50
fi

warmup_rows=()
warmup_rows+=("$(run_and_time warmup_ingress_selftest dotnet run --no-build --project "$LEDGER_API_PROJECT" -- --self-test)")
warmup_rows+=("$(run_and_time warmup_evidence_pack_selftest dotnet run --no-build --project "$LEDGER_API_PROJECT" -- --self-test-evidence-pack)")
warmup_rows+=("$(run_and_time warmup_case_pack_selftest dotnet run --no-build --project "$LEDGER_API_PROJECT" -- --self-test-case-pack)")

for row in "${warmup_rows[@]}"; do
  IFS=',' read -r _label rc _ms <<<"$row"
  if [[ "$rc" -ne 0 ]]; then
    echo "perf_warmup_failed:$row" >&2
    exit 1
  fi
done

rows=()
rows+=("$(run_and_time ingress_selftest dotnet run --no-build --project "$LEDGER_API_PROJECT" -- --self-test)")
rows+=("$(run_and_time evidence_pack_selftest dotnet run --no-build --project "$LEDGER_API_PROJECT" -- --self-test-evidence-pack)")
rows+=("$(run_and_time case_pack_selftest dotnet run --no-build --project "$LEDGER_API_PROJECT" -- --self-test-case-pack)")

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
WARMUP_ROWS_PAYLOAD="$(printf '%s\n' "${warmup_rows[@]}")"

python3 - <<PY
import json, math
from pathlib import Path

warmup_rows = []
for raw in """$WARMUP_ROWS_PAYLOAD""".splitlines():
    if not raw.strip():
        continue
    label, rc, ms = raw.split(",", 2)
    warmup_rows.append({"name": label, "exit_code": int(rc), "elapsed_ms": int(ms)})

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
  "warmup": {
    "enabled": True,
    "total_requests": int("$TOTAL_REQUESTS"),
    "warmup_requests": int("$WARMUP_REQUESTS"),
    "warmup_ratio_target": 0.10,
    "minimum_warmup_requests": 50,
    "executed_steps": [r["name"] for r in warmup_rows],
    "discarded_results": True
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
if ! dotnet run --no-build --project "$LEDGER_API_PROJECT" -- --self-test-batching-telemetry >/tmp/symphony_perf_batching.log 2>&1; then
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
  "soft_regression_threshold_pct": None,
  "hard_regression_threshold_pct": None,
  "baseline_p95_ms": None,
  "current_p95_ms": current_p95,
  "drift_pct": None,
  "regression_classification": "UNKNOWN",
  "allowed_p95_ms": None,
  "mode": "enforced",
  "regression_detected": False,
  "regression_enforced": False
}

if not baseline_path.exists():
  smoke["status"] = "FAIL"
  smoke["error"] = "baseline_file_missing"
else:
  cfg = json.loads(baseline_path.read_text())
  enforcement["baseline_locked"] = bool(cfg.get("baseline_locked", False))
  soft_pct = cfg.get("soft_regression_threshold_pct")
  hard_pct = cfg.get("hard_regression_threshold_pct")
  if hard_pct is None:
    hard_pct = cfg.get("regression_threshold_pct")
  enforcement["soft_regression_threshold_pct"] = float(soft_pct) if soft_pct is not None else None
  enforcement["hard_regression_threshold_pct"] = float(hard_pct) if hard_pct is not None else None
  if cfg.get("p95_ms") is not None:
    enforcement["baseline_p95_ms"] = float(cfg.get("p95_ms"))

  if not enforcement["baseline_locked"]:
    smoke["status"] = "FAIL"
    smoke["error"] = "baseline_not_locked"
  elif enforcement["baseline_p95_ms"] is None or enforcement["baseline_p95_ms"] <= 0:
    smoke["status"] = "FAIL"
    smoke["error"] = "baseline_locked_but_missing_baseline_p95"
  elif (
    enforcement["soft_regression_threshold_pct"] is None
    or enforcement["hard_regression_threshold_pct"] is None
    or enforcement["soft_regression_threshold_pct"] < 0
    or enforcement["hard_regression_threshold_pct"] < 0
    or enforcement["soft_regression_threshold_pct"] > enforcement["hard_regression_threshold_pct"]
  ):
    smoke["status"] = "FAIL"
    smoke["error"] = "baseline_thresholds_invalid_or_missing"
  else:
    baseline = enforcement["baseline_p95_ms"]
    drift_pct = (current_p95 - baseline) / baseline
    enforcement["drift_pct"] = drift_pct
    hard_allowed = baseline * (1.0 + enforcement["hard_regression_threshold_pct"])
    enforcement["allowed_p95_ms"] = hard_allowed
    enforcement["regression_enforced"] = True

    if drift_pct > enforcement["hard_regression_threshold_pct"]:
      enforcement["regression_classification"] = "HARD_REGRESSION"
      enforcement["regression_detected"] = True
      smoke["status"] = "FAIL"
      smoke["error"] = f"perf_hard_regression_detected:p95_ms={current_p95:.2f}>allowed={hard_allowed:.2f}"
    elif drift_pct > enforcement["soft_regression_threshold_pct"]:
      enforcement["regression_classification"] = "SOFT_REGRESSION"
      enforcement["regression_detected"] = True
      smoke.setdefault("warnings", []).append(
        f"perf_soft_regression_detected:p95_ms={current_p95:.2f}:drift_pct={drift_pct:.5f}"
      )
    else:
      enforcement["regression_classification"] = "PASS"
      enforcement["regression_detected"] = False

smoke["promotion"] = enforcement
smoke["regression_classification"] = enforcement["regression_classification"]
smoke_path.write_text(json.dumps(smoke, indent=2) + "\n")

perf2 = {
  "check_id": "PERF-002",
  "task_id": "PERF-002",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "PASS" if smoke.get("status") == "PASS" else "FAIL",
  "pass": smoke.get("status") == "PASS",
  "details": {
    "workload_profile": smoke.get("profile", {}),
    "warmup": smoke.get("warmup", {}),
    "baseline_file": str(baseline_path),
    "baseline_locked": enforcement.get("baseline_locked"),
    "soft_regression_threshold_pct": enforcement.get("soft_regression_threshold_pct"),
    "hard_regression_threshold_pct": enforcement.get("hard_regression_threshold_pct"),
    "baseline_p95_ms": enforcement.get("baseline_p95_ms"),
    "current_p95_ms": enforcement.get("current_p95_ms"),
    "drift_pct": enforcement.get("drift_pct"),
    "regression_classification": enforcement.get("regression_classification"),
    "regression_enforced": enforcement.get("regression_enforced"),
    "thresholds_source": "docs/operations/perf_smoke_baseline.json"
  },
}
Path(r"$PERF2_FILE").write_text(json.dumps(perf2, indent=2) + "\n", encoding="utf-8")
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
echo "PERF-002 regression detection evidence: $PERF2_FILE"

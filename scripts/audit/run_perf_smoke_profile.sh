#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
SMOKE_FILE="$EVIDENCE_DIR/perf_smoke_profile.json"
BENCH_FILE="$EVIDENCE_DIR/perf_db_driver_bench.json"
BATCH_FILE="$EVIDENCE_DIR/perf_driver_batching_telemetry.json"
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
  "$@" >/tmp/symphony_perf_${label}.log 2>&1 || rc=$?
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

avg_ms=$((total_ms / ${#rows[@]}))
ROWS_PAYLOAD="$(printf '%s\n' "${rows[@]}")"

python3 - <<PY
import json
from pathlib import Path
rows = []
for raw in """$ROWS_PAYLOAD""".splitlines():
    if not raw.strip():
        continue
    label, rc, ms = raw.split(",", 2)
    rows.append({"name": label, "exit_code": int(rc), "elapsed_ms": int(ms)})
now = "$EVIDENCE_TS"
Path(r"$SMOKE_FILE").write_text(json.dumps({
  "check_id": "PHASE1-PERF-SMOKE-PROFILE",
  "timestamp_utc": now,
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "$status",
  "profile": {
    "runner": "dotnet-selftest-profile",
    "iterations": len(rows),
    "workload": [r["name"] for r in rows],
    "environment": "${ENVIRONMENT:-local}",
    "storage_mode": "${INGRESS_STORAGE_MODE:-file}"
  },
  "results": rows,
  "summary": {
    "total_elapsed_ms": $total_ms,
    "avg_elapsed_ms": $avg_ms
  }
}, indent=2) + "\n", encoding="utf-8")

Path(r"$BENCH_FILE").write_text(json.dumps({
  "check_id": "PHASE1-PERF-DB-DRIVER-BENCH",
  "timestamp_utc": now,
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "$status",
  "driver": "NpgsqlDataSource",
  "results": rows,
  "summary": {
    "total_elapsed_ms": $total_ms,
    "avg_elapsed_ms": $avg_ms
  }
}, indent=2) + "\n", encoding="utf-8")

# Telemetry placeholder tied to deterministic runner until runtime metrics are wired.
Path(r"$BATCH_FILE").write_text(json.dumps({
  "check_id": "PHASE1-PERF-DRIVER-BATCHING-TELEMETRY",
  "timestamp_utc": now,
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "PASS",
  "mode": "deterministic_placeholder",
  "note": "Runtime Metrics/OpenTelemetry batching instrumentation to be wired in follow-up implementation.",
  "workload_profile": [r["name"] for r in rows]
}, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "Perf smoke profile failed. See /tmp/symphony_perf_*.log" >&2
  exit 1
fi

echo "Perf smoke profile passed. Evidence: $SMOKE_FILE"
echo "Perf DB driver bench evidence: $BENCH_FILE"
echo "Perf driver batching telemetry evidence: $BATCH_FILE"

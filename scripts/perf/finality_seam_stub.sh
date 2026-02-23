#!/usr/bin/env bash
set -euo pipefail

RAIL=""
BASE_LATENCY_MS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rail)
      RAIL="$2"
      shift 2
      ;;
    --base-latency-ms)
      BASE_LATENCY_MS="$2"
      shift 2
      ;;
    *)
      echo "unknown_arg:$1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$RAIL" || -z "$BASE_LATENCY_MS" ]]; then
  echo "usage: $0 --rail <rail> --base-latency-ms <ms>" >&2
  exit 1
fi

python3 - <<PY
import json
rail = "$RAIL"
base_ms = int(float("$BASE_LATENCY_MS"))
overrides = {
    "ZM-NFS": 0,
    "ZM-MMO": 500,
}
finality_ms = base_ms + int(overrides.get(rail, 250))
out = {
    "rail": rail,
    "observed_finality_ms": finality_ms,
    "measurement_truth": "simulated_finality_stub",
    "finality_source": "simulated_stub",
    "live_rail_wiring_status": "pending_phase2",
}
print(json.dumps(out))
PY

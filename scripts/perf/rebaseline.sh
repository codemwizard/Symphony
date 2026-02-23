#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_EVIDENCE="${SOURCE_EVIDENCE:-$ROOT_DIR/evidence/phase1/perf_smoke_profile.json}"
BASELINE_IN="${BASELINE_IN:-$ROOT_DIR/docs/operations/perf_smoke_baseline.json}"
CANDIDATE_OUT="${CANDIDATE_OUT:-$ROOT_DIR/docs/operations/perf_smoke_baseline.candidate.json}"

if [[ ! -f "$SOURCE_EVIDENCE" ]]; then
  echo "missing_source_evidence:$SOURCE_EVIDENCE" >&2
  exit 1
fi
if [[ ! -f "$BASELINE_IN" ]]; then
  echo "missing_baseline_file:$BASELINE_IN" >&2
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path

source = Path(r"$SOURCE_EVIDENCE")
baseline = Path(r"$BASELINE_IN")
out = Path(r"$CANDIDATE_OUT")

smoke = json.loads(source.read_text(encoding="utf-8"))
base = json.loads(baseline.read_text(encoding="utf-8"))

p95 = (smoke.get("summary") or {}).get("p95_ms")
if not isinstance(p95, (int, float)) or p95 <= 0:
    raise SystemExit("invalid_source_p95")

candidate = dict(base)
candidate["p95_ms"] = int(float(p95))
candidate["baseline_locked"] = True
candidate["generated_from"] = "evidence/phase1/perf_smoke_profile.json"
candidate["generated_by"] = "scripts/perf/rebaseline.sh"

out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(candidate, indent=2) + "\n", encoding="utf-8")
print(out)
PY

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$CANDIDATE_OUT" | awk '{print $1}'
else
  shasum -a 256 "$CANDIDATE_OUT" | awk '{print $1}'
fi

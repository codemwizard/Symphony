#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PHASE0_DIR="${PHASE0_DIR:-$ROOT_DIR/evidence/phase0}"
PHASE1_DIR="${PHASE1_DIR:-$ROOT_DIR/evidence/phase1}"
OUT_FILE="${OUT_FILE:-$ROOT_DIR/evidence/phase0/evidence_schema_validation.json}"
STRICT_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase0-dir)
      PHASE0_DIR="$2"
      shift 2
      ;;
    --phase1-dir)
      PHASE1_DIR="$2"
      shift 2
      ;;
    --evidence|--out)
      OUT_FILE="$2"
      shift 2
      ;;
    --strict)
      STRICT_MODE=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

source "$ROOT_DIR/scripts/lib/evidence.sh"
ensure_evidence_write_allowed "$OUT_FILE"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
REL_PHASE0_DIR="${PHASE0_DIR#$ROOT_DIR/}"
REL_PHASE1_DIR="${PHASE1_DIR#$ROOT_DIR/}"
REL_OUT_FILE="${OUT_FILE#$ROOT_DIR/}"

PHASE0_DIR="$PHASE0_DIR" PHASE1_DIR="$PHASE1_DIR" OUT_FILE="$OUT_FILE" STRICT_MODE="$STRICT_MODE" EVIDENCE_TS="$EVIDENCE_TS" EVIDENCE_GIT_SHA="$EVIDENCE_GIT_SHA" REL_PHASE0_DIR="$REL_PHASE0_DIR" REL_PHASE1_DIR="$REL_PHASE1_DIR" REL_OUT_FILE="$REL_OUT_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

required = {"git_sha", "check_id", "status"}
allowed = {
    "git_sha",
    "produced_at_utc",
    "timestamp_utc",
    "check_id",
    "task_id",
    "status",
    "pass",
    "inputs",
    "outputs",
    "measurement_truth",
    "details",
    "errors",
    "notes",
    "schema_version",
    "schema_fingerprint",
}

strict = os.environ.get("STRICT_MODE") == "1"
phase_dirs = [Path(os.environ["PHASE0_DIR"]), Path(os.environ["PHASE1_DIR"])]
files = []
for d in phase_dirs:
    if d.exists():
        files.extend(sorted(d.glob("*.json")))

count_valid = 0
invalid_files = []

for f in files:
    rel = str(f)
    if f.name == "approval_metadata.json" or f.name == "pwrm0001_monitoring_report.json" or f.name == "pwrm_monitoring_report.json":
        # Approval metadata and Pwrm reports have their own schema/contract verifier and are not a gate-evidence payloads.
        count_valid += 1
        continue
    try:
        payload = json.loads(f.read_text(encoding="utf-8"))
    except Exception as exc:
        invalid_files.append({"file": rel, "error": f"invalid_json:{exc}"})
        continue

    if not isinstance(payload, dict):
        invalid_files.append({"file": rel, "error": "top_level_not_object"})
        continue

    missing = sorted(k for k in required if k not in payload)
    if missing:
        invalid_files.append({"file": rel, "error": f"missing_required:{','.join(missing)}"})
        continue

    if "timestamp_utc" not in payload and "produced_at_utc" not in payload:
        invalid_files.append({"file": rel, "error": "missing_required:timestamp_utc_or_produced_at_utc"})
        continue

    if strict:
        extra = sorted(k for k in payload if k not in allowed)
        if extra:
            invalid_files.append({"file": rel, "error": f"unknown_extra_fields:{','.join(extra)}"})
            continue

    count_valid += 1

status = "PASS" if not invalid_files else "FAIL"
out_payload = {
    "check_id": "EVIDENCE-JSON-VALIDATION",
    "task_id": "TSK-P0-103",
    "timestamp_utc": os.environ["EVIDENCE_TS"],
    "git_sha": os.environ["EVIDENCE_GIT_SHA"],
    "status": status,
    "pass": status == "PASS",
    "count_valid": count_valid,
    "count_invalid": len(invalid_files),
    "invalid_files": invalid_files,
    "schema_version": "1.0",
    "inputs": {
        "phase0_dir": os.environ["REL_PHASE0_DIR"],
        "phase1_dir": os.environ["REL_PHASE1_DIR"],
        "strict": strict
    },
    "outputs": {
        "report_path": os.environ["REL_OUT_FILE"]
    }
}

out = Path(os.environ["OUT_FILE"])
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(out_payload, indent=2) + "\n", encoding="utf-8")
print(status)
if status != "PASS":
    raise SystemExit(1)
PY

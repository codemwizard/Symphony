#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FRAMEWORK="$ROOT_DIR/docs/programs/symphony-hardening/INQUIRY_POLICY_FRAMEWORK.md"
MATRIX="$ROOT_DIR/docs/programs/symphony-hardening/RAIL_SCENARIO_MATRIX.md"
TRACE="$ROOT_DIR/docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md"
EVIDENCE="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_010.json"

[[ -s "$FRAMEWORK" ]] || { echo "missing_framework" >&2; exit 1; }
[[ -s "$MATRIX" ]] || { echo "missing_matrix" >&2; exit 1; }
[[ -s "$TRACE" ]] || { echo "missing_traceability_matrix" >&2; exit 1; }

ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
framework = (root / "docs/programs/symphony-hardening/INQUIRY_POLICY_FRAMEWORK.md").read_text(encoding="utf-8")
matrix = (root / "docs/programs/symphony-hardening/RAIL_SCENARIO_MATRIX.md").read_text(encoding="utf-8")
trace = (root / "docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md").read_text(encoding="utf-8")

required_policy_fields = [
    "rail_id",
    "cadence_seconds",
    "retry_window_seconds",
    "max_attempts",
    "timeout_threshold_seconds",
    "orphan_threshold_seconds",
    "circuit_breaker_threshold_rate",
    "circuit_breaker_window_seconds",
]

policy_blocks = re.findall(r"### Policy: .*?(?=\n### Policy: |\Z)", framework, flags=re.S)
if not policy_blocks:
    raise SystemExit("no_policy_entries")

for i, block in enumerate(policy_blocks, 1):
    for field in required_policy_fields:
        if f"- {field}:" not in block:
            raise SystemExit(f"missing_policy_field:{field}:entry_{i}")

required_scenarios = {
    "SILENT_RAIL",
    "CONFLICTING_FINALITY",
    "LATE_CALLBACK",
    "MALFORMED_RESPONSE",
    "PARTIAL_RESPONSE",
    "TIMEOUT_EXCEEDED",
}

lines = [ln.strip() for ln in matrix.splitlines() if ln.strip().startswith("|")]
if len(lines) < 3:
    raise SystemExit("scenario_table_missing_rows")

header = [c.strip() for c in lines[0].strip("|").split("|")]
required_cols = [
    "scenario_type",
    "description",
    "expected_system_response",
    "evidence_artifact_type",
    "implementing_task_id",
]
if [c.lower() for c in header] != required_cols:
    raise SystemExit(f"invalid_matrix_header:{header}")

rows = []
for ln in lines[2:]:
    cols = [c.strip() for c in ln.strip("|").split("|")]
    if len(cols) != len(required_cols):
        raise SystemExit(f"invalid_row_column_count:{ln}")
    row = dict(zip(required_cols, cols))
    rows.append(row)

if len(rows) < 6:
    raise SystemExit(f"fewer_than_6_scenarios:{len(rows)}")

scenario_types = {r["scenario_type"] for r in rows}
missing = sorted(required_scenarios - scenario_types)
if missing:
    raise SystemExit("missing_required_scenarios:" + ",".join(missing))

trace_task_ids = set(re.findall(r"\|\s*(TSK-[A-Z0-9-]+)\s*\|", trace))
for r in rows:
    for key in required_cols:
        if not r[key] or r[key].strip() in {"TBD", "TODO", "-"}:
            raise SystemExit(f"placeholder_or_empty:{key}:{r['scenario_type']}")
    tid = r["implementing_task_id"]
    if tid not in trace_task_ids:
        raise SystemExit(f"unknown_implementing_task_id:{tid}")

out = {
    "check_id": "TSK-HARD-010",
    "task_id": "TSK-HARD-010",
    "status": "PASS",
    "pass": True,
    "policy_entries": len(policy_blocks),
    "scenario_rows": len(rows),
    "required_scenarios_present": True,
    "implementing_task_ids_valid": True,
}

out_path = root / "evidence/phase1/hardening/tsk_hard_010.json"
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print("TSK-HARD-010 verifier: PASS")
print(f"Evidence: {out_path}")
PY

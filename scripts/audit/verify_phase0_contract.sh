#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT_PATH="${CONTRACT_PATH:-$ROOT_DIR/docs/PHASE0/phase0_contract.yml}"
TASKS_DIR="${TASKS_DIR:-$ROOT_DIR/tasks}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT_DIR/evidence/phase0}"
EVIDENCE_OUT="${EVIDENCE_OUT:-$EVIDENCE_DIR/phase0_contract.json}"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

export CONTRACT_PATH TASKS_DIR EVIDENCE_OUT
python3 - <<'PY'
import json
import os
import re
import subprocess
from pathlib import Path

contract_path = Path(os.environ["CONTRACT_PATH"])
tasks_dir = Path(os.environ["TASKS_DIR"])
evidence_out = Path(os.environ["EVIDENCE_OUT"])

allowed_status = {"roadmap", "planned", "in_progress", "completed"}
allowed_modes = {"local", "ci", "both", "none"}
allowed_scopes = {"repo", "ci_artifact"}

errors = []

details = {
    "missing_tasks": [],
    "unknown_tasks": [],
    "duplicate_task_ids": [],
    "invalid_rows": [],
    "bad_paths": [],
}

# git_sha provided by environment

try:
    import yaml  # type: ignore
except Exception as e:
    errors.append(f"pyyaml_missing: {e}")
    data = []
else:
    if not contract_path.exists():
        errors.append(f"contract_not_found: {contract_path}")
        data = []
    else:
        try:
            data = yaml.safe_load(contract_path.read_text(encoding="utf-8")) or []
        except Exception as e:
            errors.append(f"contract_parse_error: {e}")
            data = []

if not isinstance(data, list):
    errors.append("contract_not_list")
    data = []

seen = set()
for idx, row in enumerate(data):
    if not isinstance(row, dict):
        errors.append(f"row_{idx}_not_object")
        continue
    task_id = row.get("task_id")
    status = row.get("status")
    mode = row.get("verification_mode")
    evidence_required = row.get("evidence_required")
    evidence_paths = row.get("evidence_paths")
    gate_ids = row.get("gate_ids")
    scope = row.get("evidence_scope")

    missing_fields = [k for k in ("task_id","status","verification_mode","evidence_required","evidence_paths","evidence_scope","notes","gate_ids") if k not in row]
    if missing_fields:
        details["invalid_rows"].append({"task_id": task_id, "missing_fields": missing_fields})

    if not isinstance(task_id, str) or not task_id:
        errors.append(f"row_{idx}_invalid_task_id")
    else:
        if task_id in seen:
            details["duplicate_task_ids"].append(task_id)
        seen.add(task_id)

    if status not in allowed_status:
        details["invalid_rows"].append({"task_id": task_id, "status": status})

    if mode not in allowed_modes:
        details["invalid_rows"].append({"task_id": task_id, "verification_mode": mode})

    if scope not in allowed_scopes:
        details["invalid_rows"].append({"task_id": task_id, "evidence_scope": scope})

    if not isinstance(evidence_required, bool):
        details["invalid_rows"].append({"task_id": task_id, "evidence_required": evidence_required})

    if not isinstance(evidence_paths, list):
        details["invalid_rows"].append({"task_id": task_id, "evidence_paths": "not_list"})
        evidence_paths = []

    if not isinstance(gate_ids, list):
        details["invalid_rows"].append({"task_id": task_id, "gate_ids": "not_list"})
        gate_ids = []

    if evidence_required and not evidence_paths:
        if not gate_ids:
            details["invalid_rows"].append({"task_id": task_id, "evidence_paths": "required_but_empty"})

    for p in evidence_paths:
        if not isinstance(p, str) or not p:
            details["bad_paths"].append({"task_id": task_id, "path": p, "error": "empty_or_not_string"})
            continue
        if p.startswith("/"):
            details["bad_paths"].append({"task_id": task_id, "path": p, "error": "absolute_path"})
        # glob constraints: allow only narrow globs under evidence/phase0
        if "*" in p:
            if not p.startswith("evidence/phase0/"):
                details["bad_paths"].append({"task_id": task_id, "path": p, "error": "glob_outside_evidence"})
            else:
                name = Path(p).name
                if "*" not in name:
                    details["bad_paths"].append({"task_id": task_id, "path": p, "error": "glob_in_dir"})

# Ensure every task has a contract row
meta_tasks = sorted(p.parent.name for p in tasks_dir.glob("TSK-P0-*/meta.yml"))
meta_set = set(meta_tasks)
contract_set = set(seen)

missing = sorted(meta_set - contract_set)
unknown = sorted(contract_set - meta_set)
if missing:
    details["missing_tasks"].extend(missing)
if unknown:
    details["unknown_tasks"].extend(unknown)

if details["missing_tasks"] or details["unknown_tasks"] or details["duplicate_task_ids"] or details["invalid_rows"] or details["bad_paths"]:
    errors.append("contract_validation_failed")

result = {
    "check_id": "PHASE0-CONTRACT",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "details": details,
}

evidence_out.parent.mkdir(parents=True, exist_ok=True)
evidence_out.write_text(json.dumps(result, indent=2))

if errors:
    for err in errors:
        print(f"ERROR: {err}")
    raise SystemExit(1)

print("Phase-0 contract validation passed.")
PY

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAP_PATH="$ROOT_DIR/docs/contracts/sqlstate_map.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_OUT="$EVIDENCE_DIR/sqlstate_map_drift.json"

mkdir -p "$EVIDENCE_DIR"

ROOT_DIR="$ROOT_DIR" MAP_PATH="$MAP_PATH" EVIDENCE_OUT="$EVIDENCE_OUT" python3 - <<'PY'
import json
import os
import re
import subprocess
from pathlib import Path
from datetime import datetime, timezone

root = Path(os.environ["ROOT_DIR"])
map_path = Path(os.environ["MAP_PATH"])
evidence_out = Path(os.environ["EVIDENCE_OUT"])

errors = []

details = {
    "missing_codes": [],
    "invalid_entries": [],
    "scanned_files": 0,
    "found_codes": [],
    "unused_codes": [],
}

def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"

# Load map (JSON-compatible YAML)
if not map_path.exists():
    errors.append(f"map_not_found: {map_path}")
    data = {}
else:
    try:
        data = json.loads(map_path.read_text(encoding="utf-8"))
    except Exception as e:
        errors.append(f"map_parse_error: {e}")
        data = {}

codes = data.get("codes") if isinstance(data, dict) else None
if not isinstance(codes, dict):
    errors.append("map_codes_not_object")
    codes = {}

code_pattern = re.compile(r"^P\d{4}$")
allowed_class = {"A","B","C"}

for code, entry in codes.items():
    if not code_pattern.match(code):
        details["invalid_entries"].append({"code": code, "error": "invalid_code_format"})
        continue
    if not isinstance(entry, dict):
        details["invalid_entries"].append({"code": code, "error": "entry_not_object"})
        continue
    cls = entry.get("class")
    subsystem = entry.get("subsystem")
    meaning = entry.get("meaning")
    retryable = entry.get("retryable")
    if cls not in allowed_class:
        details["invalid_entries"].append({"code": code, "error": "invalid_class"})
    if not isinstance(subsystem, str) or not subsystem:
        details["invalid_entries"].append({"code": code, "error": "missing_subsystem"})
    if not isinstance(meaning, str) or not meaning:
        details["invalid_entries"].append({"code": code, "error": "missing_meaning"})
    if not isinstance(retryable, bool):
        details["invalid_entries"].append({"code": code, "error": "missing_retryable"})
    canonical = entry.get("canonical")
    if canonical:
        if not isinstance(canonical, str) or not code_pattern.match(canonical):
            details["invalid_entries"].append({"code": code, "error": "invalid_canonical"})
        elif canonical not in codes:
            details["invalid_entries"].append({"code": code, "error": "canonical_not_in_map"})

# Scan for codes
include_dirs = [
    root / "schema" / "migrations",
    root / "scripts",
    root / "docs",
]

exclude_paths = {
    root / "schema" / "baseline.sql",
}

found = set()

for base in include_dirs:
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if path.is_dir():
            if path.name in {".git", "bin", "obj"}:
                continue
            continue
        if path in exclude_paths:
            continue
        if path.name == "INVARIANTS_QUICK.md":
            continue
        # Only scan text-like files
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue
        details["scanned_files"] += 1
        for m in re.findall(r"P\d{4}", text):
            found.add(m)

missing = sorted(found - set(codes.keys()))
if missing:
    details["missing_codes"].extend(missing)

# Unused codes (optional visibility)
unused = sorted(set(codes.keys()) - found)
if unused:
    details["unused_codes"].extend(unused)

details["found_codes"] = sorted(found)

if details["missing_codes"] or details["invalid_entries"] or errors:
    errors.append("sqlstate_map_drift")

result = {
    "task_id": "TSK-P0-038",
    "check": "sqlstate_map_drift",
    "result": "pass" if not errors else "fail",
    "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    "git_sha": git_sha(),
    "details": details,
}

evidence_out.write_text(json.dumps(result, indent=2))

if errors:
    for err in errors:
        print(f"ERROR: {err}")
    raise SystemExit(1)

print("SQLSTATE map drift check passed.")
PY

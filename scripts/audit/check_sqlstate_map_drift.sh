#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MAP_PATH="$ROOT_DIR/docs/contracts/sqlstate_map.yml"
SCHEMA_PATH="$ROOT_DIR/docs/contracts/sqlstate_map.schema.json"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_OUT="${EVIDENCE_OUT:-$EVIDENCE_DIR/sqlstate_map_drift.json}"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

ROOT_DIR="$ROOT_DIR" MAP_PATH="$MAP_PATH" SCHEMA_PATH="$SCHEMA_PATH" EVIDENCE_OUT="$EVIDENCE_OUT" python3 - <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
map_path = Path(os.environ["MAP_PATH"])
schema_path = Path(os.environ["SCHEMA_PATH"])
evidence_out = Path(os.environ["EVIDENCE_OUT"])

errors = []
details = {
    "missing_codes": [],
    "invalid_entries": [],
    "scanned_files": 0,
    "found_codes": [],
    "unused_codes": [],
    "scan_scope": [],
    "schema_validation": {"status": "SKIP", "errors": []},
}

def add_invalid(code, error):
    details["invalid_entries"].append({"code": code, "error": error})

def load_json_compatible_yaml(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))

# Load map (JSON-compatible YAML policy)
if not map_path.exists():
    errors.append(f"map_not_found: {map_path}")
    data = {}
else:
    try:
        data = load_json_compatible_yaml(map_path)
    except Exception as e:
        errors.append(f"map_parse_error: {e}")
        data = {}

# Optional schema validation using JSON Schema if dependency exists
if schema_path.exists() and isinstance(data, dict):
    try:
        import jsonschema  # type: ignore
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        jsonschema.Draft202012Validator(schema).validate(data)
        details["schema_validation"]["status"] = "PASS"
    except ModuleNotFoundError:
        details["schema_validation"]["status"] = "SKIP"
        details["schema_validation"]["errors"].append("jsonschema_not_installed")
    except Exception as e:
        details["schema_validation"]["status"] = "FAIL"
        details["schema_validation"]["errors"].append(str(e))
        errors.append("sqlstate_map_schema_invalid")

required_top = ["schema_version","registry_id","owner","code_pattern","entry_required_fields","source_scan_scope","ranges","codes"]
for k in required_top:
    if not isinstance(data, dict) or k not in data:
        add_invalid("__top_level__", f"missing_top_level_field:{k}")

codes = data.get("codes") if isinstance(data, dict) else None
if not isinstance(codes, dict):
    errors.append("map_codes_not_object")
    codes = {}

# Fail-closed: the map file must not define its own acceptance regex.
fixed_pattern = r"^P\d{4}$"
declared_pattern = data.get("code_pattern") if isinstance(data, dict) else None
if declared_pattern != fixed_pattern:
    add_invalid("__top_level__", f"code_pattern_must_equal:{fixed_pattern}")
code_pattern = re.compile(fixed_pattern)

allowed_class = {"A", "B", "C"}

for code, entry in codes.items():
    if not isinstance(code, str) or not code_pattern.match(code):
        add_invalid(str(code), "invalid_code_format")
        continue
    if not isinstance(entry, dict):
        add_invalid(code, "entry_not_object")
        continue
    cls = entry.get("class")
    subsystem = entry.get("subsystem")
    meaning = entry.get("meaning")
    retryable = entry.get("retryable")
    if cls not in allowed_class:
        add_invalid(code, "invalid_class")
    if not isinstance(subsystem, str) or not subsystem:
        add_invalid(code, "missing_subsystem")
    if not isinstance(meaning, str) or not meaning:
        add_invalid(code, "missing_meaning")
    if not isinstance(retryable, bool):
        add_invalid(code, "missing_retryable")
    canonical = entry.get("canonical")
    if canonical is not None:
        if not isinstance(canonical, str) or not code_pattern.match(canonical):
            add_invalid(code, "invalid_canonical")
        elif canonical not in codes:
            add_invalid(code, "canonical_not_in_map")

# Scan scope restricted to contractual/product code sources only
allowed_roots = [
    root / "schema",
    root / "scripts",
    root / "services",
    root / "docs" / "contracts",
]
exclude_names = {".git", "bin", "obj", "node_modules", "vendor", "__pycache__"}
exclude_paths = {
    root / "schema" / "baseline.sql",
}
allowed_suffixes = {
    ".sql", ".psql", ".sh", ".bash", ".py", ".js", ".ts", ".tsx", ".go", ".rs", ".java", ".kt",
    ".cs", ".yml", ".yaml", ".json", ".md"
}

found = set()
for base in allowed_roots:
    if not base.exists():
        continue
    details["scan_scope"].append(str(base.relative_to(root)))
    for path in base.rglob("*"):
        if path.is_dir():
            continue
        if any(part in exclude_names for part in path.parts):
            continue
        if path in exclude_paths:
            continue
        if path.suffix and path.suffix.lower() not in allowed_suffixes:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue
        details["scanned_files"] += 1
        for m in re.findall(r"\bP\d{4}\b", text):
            found.add(m)

details["found_codes"] = sorted(found)
missing = sorted(found - set(codes.keys()))
unused = sorted(set(codes.keys()) - found)
details["missing_codes"] = missing
details["unused_codes"] = unused

if details["missing_codes"] or details["invalid_entries"]:
    errors.append("sqlstate_map_drift")

result = {
    "check_id": "SQLSTATE-MAP-DRIFT",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "details": details,
}

evidence_out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")

if errors:
    for err in errors:
        print(f"ERROR: {err}")
    raise SystemExit(1)

print("SQLSTATE map drift check passed.")
PY

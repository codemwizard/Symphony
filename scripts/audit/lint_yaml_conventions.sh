#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/yaml_conventions_lint.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<'PY'
import json
import os
import re
from pathlib import Path

try:
    import yaml
except Exception as e:
    out = {
        "check_id": "YAML-CONVENTIONS",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "errors": [f"PyYAML not available: {e}"],
    }
    Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2))
    raise SystemExit(1)

ROOT = Path(os.environ.get("ROOT_DIR", Path.cwd()))
EVIDENCE_FILE = Path(os.environ.get("EVIDENCE_FILE", ROOT / "evidence/phase0/yaml_conventions_lint.json"))

snake_re = re.compile(r"^[a-z][a-z0-9_]*$")

canonical_keys = {
    "phase","task_id","title","owner_role","status",
    "depends_on","touches","invariants","work","acceptance_criteria",
    "verification","evidence","failure_modes","must_read","notes",
    "client","assigned_agent","model","implementation_plan","implementation_log"
}

list_fields = {
    "depends_on","touches","invariants","work","acceptance_criteria",
    "verification","evidence","failure_modes","must_read"
}

scalar_fields = {
    "phase","task_id","title","owner_role","status","notes","client","assigned_agent","model",
    "implementation_plan","implementation_log"
}

required_keys = {
    "phase","task_id","title","owner_role","status",
    "depends_on","touches","invariants","work","acceptance_criteria",
    "verification","evidence","failure_modes","must_read","notes",
    "client","assigned_agent","model"
}

legacy_markers = [
    "Depends On:",
    "Touches:",
    "Invariant(s):",
    "Work:",
    "Acceptance Criteria:",
    "Verification Commands:",
    "Evidence Artifact(s):",
    "Failure Modes:",
    "Owner Role:",
]

errors = []
checked = []

class DupLoader(yaml.SafeLoader):
    pass

def construct_mapping(loader, node, deep=False):
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise ValueError(f"duplicate key: {key}")
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping

DupLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping)

def parse_yaml(path: Path):
    text = path.read_text(encoding="utf-8", errors="ignore")
    if "\t" in text:
        errors.append(f"{path}: contains TAB characters")
    try:
        data = yaml.load(text, Loader=DupLoader)
    except Exception as e:
        errors.append(f"{path}: YAML parse error: {e}")
        return None, text
    return data, text

# ---- 1) Task meta strict lint ----
for meta in sorted(ROOT.glob("tasks/TSK-P0-*/meta.yml")):
    data, raw = parse_yaml(meta)
    checked.append(str(meta))
    if data is None:
        continue
    if not isinstance(data, dict):
        errors.append(f"{meta}: meta must be a mapping")
        continue

    # legacy markers in raw
    for m in legacy_markers:
        if m in raw:
            errors.append(f"{meta}: legacy key variant present: {m}")

    # key naming + allowed keys
    for k in data.keys():
        if not snake_re.match(str(k)):
            errors.append(f"{meta}: non_snake_case key: {k}")
        if k not in canonical_keys:
            errors.append(f"{meta}: unknown key: {k}")

    # required keys (always)
    for req in required_keys:
        if req not in data:
            errors.append(f"{meta}: missing required key: {req}")

    status = str(data.get("status", "")).lower()
    if status in ("in_progress", "completed"):
        for req in ("implementation_plan", "implementation_log"):
            if req not in data:
                errors.append(f"{meta}: missing required key: {req} for status {status}")

    # type checks
    for k in list_fields:
        if k in data and not isinstance(data[k], list):
            errors.append(f"{meta}: {k} must be a list")
    for k in scalar_fields:
        if k in data and not isinstance(data[k], str):
            errors.append(f"{meta}: {k} must be a string")

# ---- 2) Governance YAML parse (docs + .github) ----
for yml in sorted(ROOT.glob("docs/**/*.yml")) + sorted(ROOT.glob("docs/**/*.yaml")):
    data, _raw = parse_yaml(yml)
    checked.append(str(yml))
    # parse errors already captured

for yml in sorted(ROOT.glob(".github/**/*.yml")) + sorted(ROOT.glob(".github/**/*.yaml")):
    data, _raw = parse_yaml(yml)
    checked.append(str(yml))

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "YAML-CONVENTIONS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "checked_files": checked,
    "errors": errors,
}

EVIDENCE_FILE.parent.mkdir(parents=True, exist_ok=True)
EVIDENCE_FILE.write_text(json.dumps(out, indent=2))

if errors:
    for e in errors:
        print(f"ERROR: {e}")
    raise SystemExit(1)

print("YAML conventions lint passed.")
PY

echo "YAML conventions lint passed. Evidence: $EVIDENCE_FILE"

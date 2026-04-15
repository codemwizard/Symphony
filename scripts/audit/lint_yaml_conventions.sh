#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/yaml_conventions_lint.json"
YAML_LINT_SCOPE="${YAML_LINT_SCOPE:-changed}"
CHANGED_FILE_LIST=""

if [[ "$YAML_LINT_SCOPE" != "all" && "$YAML_LINT_SCOPE" != "changed" ]]; then
  echo "ERROR: YAML_LINT_SCOPE must be all|changed" >&2
  exit 2
fi

if [[ "$YAML_LINT_SCOPE" == "changed" ]]; then
  source "$ROOT_DIR/scripts/audit/lib/git_diff_range_only.sh"
  BASE_REF="${BASE_REF:-$(git_resolve_base_ref)}"
  HEAD_REF="${HEAD_REF:-HEAD}"
  if ! git_ensure_ref "$BASE_REF"; then
    echo "ERROR: base_ref_not_found:$BASE_REF" >&2
    exit 1
  fi
  CHANGED_FILE_LIST="$(mktemp)"
  git_changed_files_range "$BASE_REF" "$HEAD_REF" > "$CHANGED_FILE_LIST"
  trap 'rm -f "$CHANGED_FILE_LIST"' EXIT
fi

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP YAML_LINT_SCOPE CHANGED_FILE_LIST ROOT_DIR EVIDENCE_FILE

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
scope = os.environ.get("YAML_LINT_SCOPE", "all")
changed_file_list = os.environ.get("CHANGED_FILE_LIST", "")

snake_re = re.compile(r"^[a-z][a-z0-9_]*$")

canonical_keys = {
    "schema_version","phase","task_id","title","owner_role","status",
    "depends_on","touches","invariants","work","acceptance_criteria",
    "verification","evidence","failure_modes","must_read","notes",
    "client","assigned_agent","model","implementation_plan","implementation_log",
    "priority","risk_class","blast_radius","intent","anti_patterns","out_of_scope",
    "stop_conditions","proof_guarantees","proof_limitations","blocks",
    "negative_tests","positive_tests",
    "domain","pilot","second_pilot_test","pilot_scope_ref"
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
    "schema_version","phase","task_id","title","owner_role","status",
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

if scope == "changed":
    changed_paths = []
    if changed_file_list:
        changed_paths = [ln.strip() for ln in Path(changed_file_list).read_text(encoding="utf-8", errors="ignore").splitlines() if ln.strip()]
    task_meta_files = sorted(
        [
            ROOT / p
            for p in changed_paths
            if p.startswith("tasks/")
            and p.endswith("/meta.yml")
            and "/_template/" not in p
            and Path(p).parent.name != "_template"
        ],
        key=lambda p: p.as_posix(),
    )
    docs_yaml_files = sorted(
        [
            ROOT / p
            for p in changed_paths
            if (p.startswith("docs/") or p.startswith(".github/"))
            and (p.endswith(".yml") or p.endswith(".yaml"))
        ],
        key=lambda p: p.as_posix(),
    )
else:
    task_meta_files = sorted(
        [
            p
            for p in ROOT.glob("tasks/**/meta.yml")
            if "/_template/" not in p.as_posix() and p.parent.name != "_template"
        ],
        key=lambda p: p.as_posix(),
    )
    docs_yaml_files = sorted(ROOT.glob("docs/**/*.yml")) + sorted(ROOT.glob("docs/**/*.yaml"))
    docs_yaml_files += sorted(ROOT.glob(".github/**/*.yml")) + sorted(ROOT.glob(".github/**/*.yaml"))

# ---- 1) Task meta strict lint ----
for meta in task_meta_files:
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
    schema_version = data.get("schema_version")
    if not (isinstance(schema_version, int) or isinstance(schema_version, str)):
        errors.append(f"{meta}: schema_version must be int or string")
    else:
        if str(schema_version).strip() != "1":
            errors.append(f"{meta}: schema_version must be 1")

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
for yml in docs_yaml_files:
    data, _raw = parse_yaml(yml)
    checked.append(str(yml))

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "YAML-CONVENTIONS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "checked_file_count": len(checked),
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

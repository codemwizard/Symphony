#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MODE="inventory"
ALLOW_LEGACY=0
DENY_LEGACY=0
JSON_OUT=0
OUT_PATH=""
SCAN_ROOT="tasks"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --allow-legacy)
      ALLOW_LEGACY=1
      shift
      ;;
    --deny-legacy)
      DENY_LEGACY=1
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --out)
      OUT_PATH="${2:-}"
      shift 2
      ;;
    --root)
      SCAN_ROOT="${2:-tasks}"
      shift 2
      ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$MODE" != "inventory" && "$MODE" != "strict" ]]; then
  echo "ERROR: --mode must be inventory|strict" >&2
  exit 2
fi

SCAN_ROOT="$SCAN_ROOT" MODE="$MODE" ALLOW_LEGACY="$ALLOW_LEGACY" DENY_LEGACY="$DENY_LEGACY" JSON_OUT="$JSON_OUT" OUT_PATH="$OUT_PATH" python3 - <<'PY'
import json
import os
from pathlib import Path
import yaml  # type: ignore

scan_root = Path(os.environ["SCAN_ROOT"])
mode = os.environ["MODE"]
allow_legacy = os.environ["ALLOW_LEGACY"] == "1"
deny_legacy = os.environ["DENY_LEGACY"] == "1"
json_out = os.environ["JSON_OUT"] == "1"
out_path = os.environ.get("OUT_PATH", "")

required = [
    "schema_version",
    "phase",
    "task_id",
    "title",
    "owner_role",
    "status",
    "depends_on",
    "touches",
    "invariants",
    "work",
    "acceptance_criteria",
    "verification",
    "evidence",
    "failure_modes",
    "must_read",
    "implementation_plan",
    "implementation_log",
    "notes",
    "client",
    "assigned_agent",
    "model",
]

legacy_keys = {
    "id",
    "dependencies",
    "description",
    "affected_services",
    "affected_files",
    "verification_command",
    "implementation_plan_path",
    "implementation_log_path",
    "evidence_path",
    "evidence_paths",
    "owner",
    "role",
    "assignee_role",
}

if not scan_root.exists():
    raise SystemExit(f"ERROR: scan root missing: {scan_root}")

files = sorted(
    [
        p
        for p in scan_root.rglob("meta.yml")
        if "/_template/" not in p.as_posix() and p.parent.name != "_template"
    ],
    key=lambda p: p.as_posix(),
)

errors = []
nonconforming = []
v0 = 0
v1 = 0

for p in files:
    rel = p.as_posix()
    try:
        obj = yaml.safe_load(p.read_text(encoding="utf-8"))
    except Exception as ex:
        errors.append({"path": rel, "error": f"yaml_parse_error:{ex}"})
        continue

    if not isinstance(obj, dict):
        errors.append({"path": rel, "error": "meta_not_mapping"})
        continue

    issues = []
    schema_version = str(obj.get("schema_version") or "0")
    if schema_version == "1":
        v1 += 1
    else:
        v0 += 1
        issues.append(f"schema_version_not_v1:{schema_version}")

    missing = [k for k in required if k not in obj]
    if missing:
        issues.append(f"missing_required:{','.join(missing)}")

    present_legacy = sorted([k for k in legacy_keys if k in obj])
    if present_legacy:
        issues.append(f"legacy_keys_present:{','.join(present_legacy)}")

    if issues:
        nonconforming.append({"path": rel, "issues": issues})

report = {
    "check_id": "TASK-META-SCHEMA",
    "mode": mode,
    "allow_legacy": allow_legacy,
    "deny_legacy": deny_legacy,
    "status": "PASS",
    "summary": {
        "files_scanned": len(files),
        "v0_count": v0,
        "v1_count": v1,
        "nonconforming_count": len(nonconforming),
        "error_count": len(errors),
    },
    "nonconforming": nonconforming,
    "errors": errors,
}

strict_effective = (mode == "strict") or deny_legacy or (mode == "inventory" and not allow_legacy)
if errors or (strict_effective and nonconforming):
    report["status"] = "FAIL"

if out_path:
    out = Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")

if json_out:
    print(json.dumps(report, indent=2, sort_keys=True))
else:
    print(f"Task meta schema check: {report['status']}")
    print(f"Files scanned: {report['summary']['files_scanned']}")
    print(f"v0: {v0} v1: {v1}")
    if nonconforming:
        print("Non-conforming files:")
        for item in nonconforming:
            print(f" - {item['path']}: {';'.join(item['issues'])}")
    if errors:
        print("Errors:")
        for item in errors:
            print(f" - {item['path']}: {item['error']}")

if report["status"] == "FAIL":
    raise SystemExit(1)
PY

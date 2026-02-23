#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$EVIDENCE_PATH" ]]; then
  echo "Usage: $0 --evidence <path>" >&2
  exit 2
fi

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"

ROOT_DIR="$ROOT_DIR" EVIDENCE_PATH="$EVIDENCE_PATH" EVIDENCE_TS="$EVIDENCE_TS" EVIDENCE_GIT_SHA="$EVIDENCE_GIT_SHA" EVIDENCE_SCHEMA_FP="$EVIDENCE_SCHEMA_FP" \
python3 - <<'PY'
import json
import os
import re
from pathlib import Path

try:
    import yaml  # type: ignore
except Exception as exc:
    print(f"ERROR: missing_dependency:pyyaml:{exc}", flush=True)
    raise SystemExit(1)

root = Path(os.environ["ROOT_DIR"])
evidence = root / os.environ["EVIDENCE_PATH"]
phase0_contract_path = root / "docs/PHASE0/phase0_contract.yml"
control_planes_path = root / "docs/control_planes/CONTROL_PLANES.yml"

errors: list[str] = []
declared_invariants: set[str] = set()
derived_invariants: set[str] = set()
phase0_gate_ids: set[str] = set()
gate_links: list[dict[str, str]] = []
missing_gate_definitions: list[str] = []
orphaned_invariants: list[str] = []
orphaned_gate_references: list[str] = []
scanned_gate_scripts: list[str] = []

if not phase0_contract_path.exists():
    errors.append("missing_contract:docs/PHASE0/phase0_contract.yml")
if not control_planes_path.exists():
    errors.append("missing_control_planes:docs/control_planes/CONTROL_PLANES.yml")

contract_rows = []
if not errors:
    try:
        contract_rows = json.loads(phase0_contract_path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"phase0_contract_parse_error:{exc}")
        contract_rows = []

cp_data = {}
if not errors:
    try:
        cp_data = yaml.safe_load(control_planes_path.read_text(encoding="utf-8")) or {}
    except Exception as exc:
        errors.append(f"control_planes_parse_error:{exc}")
        cp_data = {}

gate_defs: dict[str, dict] = {}
if not errors:
    planes = (cp_data.get("control_planes") or {})
    for plane_name in ("security", "integrity", "governance"):
        req = ((planes.get(plane_name) or {}).get("required_gates") or [])
        for g in req:
            gid = str(g.get("gate_id", "")).strip()
            if gid:
                gate_defs[gid] = g

inv_re = re.compile(r"\bINV-\d{3}\b")
structured_inv_ref_re = re.compile(r'invariant_id["\']?\s*[:=]\s*["\'](INV-\d{3})["\']')

for row in contract_rows:
    if not isinstance(row, dict):
        continue
    gate_ids = row.get("gate_ids") or []
    if isinstance(gate_ids, list):
        for gid in gate_ids:
            gid_s = str(gid).strip()
            if gid_s:
                phase0_gate_ids.add(gid_s)

    inv = row.get("invariant_id")
    if isinstance(inv, str) and inv_re.fullmatch(inv):
        declared_invariants.add(inv)
    invs = row.get("invariant_ids")
    if isinstance(invs, list):
        for iid in invs:
            if isinstance(iid, str) and inv_re.fullmatch(iid):
                declared_invariants.add(iid)

for gid in sorted(phase0_gate_ids):
    gdef = gate_defs.get(gid)
    if not gdef:
        missing_gate_definitions.append(gid)
        continue
    inv = gdef.get("invariant_id")
    if isinstance(inv, str) and inv_re.fullmatch(inv):
        derived_invariants.add(inv)
        gate_links.append({"gate_id": gid, "invariant_id": inv, "source": "control_planes"})

    script = str(gdef.get("script", "")).strip()
    if script:
        scanned_gate_scripts.append(script)
        sp = root / script
        if sp.exists():
            txt = sp.read_text(encoding="utf-8", errors="ignore")
            for m in structured_inv_ref_re.findall(txt):
                gate_links.append({"gate_id": gid, "invariant_id": m, "source": f"script:{script}"})
        else:
            errors.append(f"missing_gate_script:{gid}:{script}")

all_declared = sorted(declared_invariants | derived_invariants)
all_referenced = sorted({ln["invariant_id"] for ln in gate_links})

if missing_gate_definitions:
    errors.append("missing_gate_definitions")

orphaned_invariants = sorted(set(all_declared) - set(all_referenced))
orphaned_gate_references = sorted(set(all_referenced) - set(all_declared))

if orphaned_invariants:
    errors.append("orphaned_invariants")
if orphaned_gate_references:
    errors.append("orphaned_gate_references")

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "TSK-P0-208",
    "task_id": "TSK-P0-208",
    "timestamp_utc": os.environ["EVIDENCE_TS"],
    "git_sha": os.environ["EVIDENCE_GIT_SHA"],
    "schema_fingerprint": os.environ["EVIDENCE_SCHEMA_FP"],
    "status": status,
    "pass": status == "PASS",
    "details": {
        "phase0_contract_path": str(phase0_contract_path.relative_to(root)),
        "control_planes_path": str(control_planes_path.relative_to(root)),
        "invariants_found": all_declared,
        "gate_invariant_links": gate_links,
        "orphaned_invariants": orphaned_invariants,
        "orphaned_gate_references": orphaned_gate_references,
        "missing_gate_definitions": missing_gate_definitions,
        "phase0_gate_ids_observed": sorted(phase0_gate_ids),
        "scanned_gate_scripts": sorted(set(scanned_gate_scripts)),
        "errors": errors,
    },
}

evidence.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(f"TSK-P0-208 verifier status: {status}")
print(f"Evidence: {evidence}")
raise SystemExit(0 if status == "PASS" else 1)
PY

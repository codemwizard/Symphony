#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="$ROOT_DIR/docs/security/SECURITY_MANIFEST.yml"
MAP_FILE="$ROOT_DIR/docs/architecture/COMPLIANCE_MAP.md"
CONTROL_PLANES_FILE="$ROOT_DIR/docs/control_planes/CONTROL_PLANES.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/compliance_manifest_verify.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
export MANIFEST_FILE MAP_FILE CONTROL_PLANES_FILE EVIDENCE_FILE

python3 - <<'PY'
import json
from pathlib import Path
import os

manifest_path = Path(os.environ["MANIFEST_FILE"])
map_path = Path(os.environ["MAP_FILE"])
cp_path = Path(os.environ["CONTROL_PLANES_FILE"])
evidence_path = Path(os.environ["EVIDENCE_FILE"])

errors = []
warnings = []

required_standards = {
    "PCI DSS v4.0": ["PCI DSS", "PCI-DSS", "PCI DSS v4.0"],
    "NIST 800-53": ["NIST 800-53", "NIST 800-53 (", "NIST 800-53/"],
    "NIST CSF": ["NIST CSF", "NIST CSF/"],
    "OWASP ASVS": ["OWASP ASVS", "OWASP ASVS 4.0", "OWASP ASVS 5.0"],
    "ISO 20022": ["ISO 20022"],
    "ISO 27001/27002": ["ISO 27001/27002", "ISO 27001", "ISO 27002"],
}

try:
    import yaml  # type: ignore
except Exception as e:
    out = {
        "check_id": "COMPLIANCE-MANIFEST-VERIFY",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "errors": ["pyyaml_missing", str(e)],
    }
    evidence_path.write_text(json.dumps(out, indent=2) + "\n")
    raise SystemExit(1)

if not manifest_path.exists():
    errors.append("security_manifest_missing")
    manifest = {}
else:
    manifest = yaml.safe_load(manifest_path.read_text(encoding="utf-8")) or {}

controls = manifest.get("controls", [])
if not isinstance(controls, list) or not controls:
    errors.append("controls_missing_or_empty")

control_ids = set()
standards_seen = set()
gate_ids_seen = set()

for ctrl in controls:
    cid = ctrl.get("id")
    title = ctrl.get("title")
    standards = ctrl.get("standards") or []
    enforced_by = ctrl.get("enforced_by") or []
    verified_by = ctrl.get("verified_by") or []
    gate_ids = ctrl.get("gate_ids") or []

    if not cid:
        errors.append("control_missing_id")
        continue
    if cid in control_ids:
        errors.append(f"duplicate_control_id:{cid}")
    control_ids.add(cid)

    if not title:
        errors.append(f"{cid}:missing_title")
    if not isinstance(standards, list) or not standards:
        errors.append(f"{cid}:missing_standards")
    if not isinstance(enforced_by, list) or not enforced_by:
        errors.append(f"{cid}:missing_enforced_by")
    if not isinstance(verified_by, list) or not verified_by:
        errors.append(f"{cid}:missing_verified_by")

    for s in standards:
        standards_seen.add(str(s))

    for gid in gate_ids:
        gate_ids_seen.add(str(gid))

if map_path.exists():
    map_text = map_path.read_text(encoding="utf-8")
else:
    errors.append("compliance_map_missing")
    map_text = ""

missing_standards = []
for label, variants in required_standards.items():
    if not any(v in " ".join(standards_seen) for v in variants):
        missing_standards.append(f"manifest_missing:{label}")
    if map_text and not any(v in map_text for v in variants):
        missing_standards.append(f"map_missing:{label}")

if missing_standards:
    errors.extend(sorted(set(missing_standards)))

gate_ids_declared = set()
if cp_path.exists():
    cp = yaml.safe_load(cp_path.read_text(encoding="utf-8")) or {}
    planes = cp.get("control_planes") or {}
    for plane in (planes or {}).values():
        for gate in plane.get("required_gates") or []:
            gid = gate.get("gate_id")
            if gid:
                gate_ids_declared.add(str(gid))
else:
    warnings.append("control_planes_missing")

for gid in gate_ids_seen:
    if gid not in gate_ids_declared:
        errors.append(f"gate_id_not_declared:{gid}")

status = "PASS" if not errors else "FAIL"

out = {
    "check_id": "COMPLIANCE-MANIFEST-VERIFY",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "errors": errors,
    "warnings": warnings,
    "controls_count": len(control_ids),
}

evidence_path.write_text(json.dumps(out, indent=2) + "\n")

if status != "PASS":
    print("❌ Compliance manifest verification failed")
    for e in errors:
        print(f" - {e}")
    raise SystemExit(1)

print(f"Compliance manifest verification OK. Evidence: {evidence_path}")
PY

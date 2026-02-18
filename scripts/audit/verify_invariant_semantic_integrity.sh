#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_FILE="${MANIFEST_FILE:-$ROOT_DIR/docs/invariants/INVARIANTS_MANIFEST.yml}"
CONTRACT_FILE="${CONTRACT_FILE:-$ROOT_DIR/docs/PHASE1/phase1_contract.yml}"
CONTROL_PLANES_FILE="${CONTROL_PLANES_FILE:-$ROOT_DIR/docs/control_planes/CONTROL_PLANES.yml}"
REGISTRY_FILE="${REGISTRY_FILE:-$ROOT_DIR/docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml}"
ALLOWLIST_FILE="${ALLOWLIST_FILE:-$ROOT_DIR/docs/operations/SEMANTIC_INTEGRITY_ALLOWLIST.yml}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT_DIR/evidence/phase1}"
EVIDENCE_FILE="${EVIDENCE_FILE:-$EVIDENCE_DIR/invariant_semantic_integrity.json}"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

ROOT_DIR="$ROOT_DIR" MANIFEST_FILE="$MANIFEST_FILE" CONTRACT_FILE="$CONTRACT_FILE" CONTROL_PLANES_FILE="$CONTROL_PLANES_FILE" REGISTRY_FILE="$REGISTRY_FILE" ALLOWLIST_FILE="$ALLOWLIST_FILE" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

try:
    import yaml  # type: ignore
except Exception as e:
    out = {
        "check_id": "SEM-I01",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "violations": [{"code": "SEM_I01_DEPENDENCY_MISSING", "reason": str(e)}],
    }
    Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(1)

manifest_file = Path(os.environ["MANIFEST_FILE"])
contract_file = Path(os.environ["CONTRACT_FILE"])
cp_file = Path(os.environ["CONTROL_PLANES_FILE"])
registry_file = Path(os.environ["REGISTRY_FILE"])
allowlist_file = Path(os.environ["ALLOWLIST_FILE"])

def load_yaml(path: Path, default):
    if not path.exists():
        return default
    return yaml.safe_load(path.read_text(encoding="utf-8")) or default

violations = []

manifest = load_yaml(manifest_file, [])
contract = load_yaml(contract_file, [])
control_planes = load_yaml(cp_file, {})
registry = load_yaml(registry_file, {})
allowlist = load_yaml(allowlist_file, {})

if not isinstance(manifest, list):
    manifest = []
    violations.append({"code": "SEM_I01_MANIFEST_INVALID", "reason": "manifest_not_list"})
if not isinstance(contract, list):
    contract = []
    violations.append({"code": "SEM_I01_CONTRACT_INVALID", "reason": "contract_not_list"})

manifest_map = {}
alias_seen = {}
for idx, row in enumerate(manifest):
    if not isinstance(row, dict):
        continue
    iid = str(row.get("id", "")).strip()
    if not iid:
        continue
    if iid in manifest_map:
        violations.append({
            "code": "SEM_I01_DUPLICATE_INVARIANT_ID",
            "invariant_id": iid,
            "manifest_row": idx + 1,
            "reason": "duplicate_id",
        })
    manifest_map[iid] = row
    for alias in row.get("aliases", []) or []:
        a = str(alias).strip()
        if not a:
            continue
        if a in alias_seen and alias_seen[a] != iid:
            violations.append({
                "code": "SEM_I01_DUPLICATE_ALIAS",
                "invariant_id": iid,
                "reason": f"alias_conflict:{a}:{alias_seen[a]}",
            })
        else:
            alias_seen[a] = iid

gate_ids = set()
for plane in (control_planes.get("control_planes") or {}).values():
    for gate in plane.get("required_gates") or []:
        gid = str((gate or {}).get("gate_id", "")).strip()
        if gid:
            gate_ids.add(gid)

reg = registry.get("registry") if isinstance(registry, dict) else {}
if not isinstance(reg, dict):
    reg = {}

allow_map = {}
for row in (allowlist.get("allow") or []):
    if not isinstance(row, dict):
        continue
    iid = str(row.get("invariant_id", "")).strip()
    allowed = {str(v).strip() for v in (row.get("allowed_verifiers") or []) if str(v).strip()}
    if iid and allowed:
        allow_map[iid] = allowed

for i, row in enumerate(contract, start=1):
    if not isinstance(row, dict):
        continue
    iid = str(row.get("invariant_id", "")).strip()
    verifier = str(row.get("verifier", "")).strip()
    gate_id = str(row.get("gate_id", "")).strip()
    evidence_path = str(row.get("evidence_path", "")).strip()

    if not iid:
        continue

    row_ref = f"contract_row:{i}"

    if iid not in manifest_map:
        violations.append({
            "code": "SEM_I01_INVARIANT_UNKNOWN",
            "invariant_id": iid,
            "contract_row_ref": row_ref,
            "reason": "invariant_not_found_in_manifest",
            "expected": "manifest entry exists",
            "actual": "missing",
        })
        continue

    expected_field = str(manifest_map[iid].get("enforcement", "")).strip()
    expected_verifiers = {v.strip() for v in expected_field.split(";") if v.strip()}
    allowed = allow_map.get(iid, set())
    all_allowed = set(allowed) | set(expected_verifiers)
    if verifier and expected_verifiers and verifier not in all_allowed:
        violations.append({
            "code": "SEM_I01_VERIFIER_MISMATCH",
            "invariant_id": iid,
            "contract_row_ref": row_ref,
            "reason": "verifier_does_not_match_manifest_enforcement",
            "expected": sorted(all_allowed),
            "actual": verifier,
        })

    if gate_id and gate_id not in gate_ids:
        violations.append({
            "code": "SEM_I01_UNKNOWN_GATE",
            "invariant_id": iid,
            "contract_row_ref": row_ref,
            "reason": "gate_missing_from_control_planes",
            "expected": "gate declared in CONTROL_PLANES.yml",
            "actual": gate_id,
        })

    if verifier and evidence_path:
        emits = []
        if verifier in reg and isinstance(reg[verifier], dict):
            emits = [str(p).strip() for p in (reg[verifier].get("emits") or []) if str(p).strip()]
        if not emits:
            violations.append({
                "code": "SEM_I01_VERIFIER_NOT_IN_REGISTRY",
                "invariant_id": iid,
                "contract_row_ref": row_ref,
                "reason": "verifier_missing_from_registry",
                "expected": "verifier registered in VERIFIER_EVIDENCE_REGISTRY.yml",
                "actual": verifier,
            })
        elif evidence_path not in emits:
            violations.append({
                "code": "SEM_I01_EVIDENCE_NOT_EMITTED_BY_VERIFIER",
                "invariant_id": iid,
                "contract_row_ref": row_ref,
                "reason": "contract_evidence_not_in_verifier_emit_list",
                "expected": emits,
                "actual": evidence_path,
            })

status = "PASS" if not violations else "FAIL"
out = {
    "check_id": "SEM-I01",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "manifest_file": str(manifest_file),
    "contract_file": str(contract_file),
    "control_planes_file": str(cp_file),
    "registry_file": str(registry_file),
    "allowlist_file": str(allowlist_file),
    "violations": violations,
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Invariant semantic integrity verification failed")
    for v in violations:
        print(f" - {v.get('code')}: {v.get('reason')}")
    raise SystemExit(1)

print(f"Invariant semantic integrity verification passed. Evidence: {os.environ['EVIDENCE_FILE']}")
PY

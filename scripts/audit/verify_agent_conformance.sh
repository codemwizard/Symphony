#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/agent_conformance.json"
ROLE_MAPPING_EVIDENCE_FILE="$EVIDENCE_DIR/agent_role_mapping.json"

export EVIDENCE_FILE
export ROLE_MAPPING_EVIDENCE_FILE

mkdir -p "$EVIDENCE_DIR"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

cd "$ROOT"

python3 <<'PY'
import json
import os
import re
import subprocess
import hashlib
import sys
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(os.getcwd())
EVIDENCE_FILE = Path(os.environ["EVIDENCE_FILE"])
FAILURES = []

CANONICAL_DOCS = [
    ROOT / "docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md",
    ROOT / "docs/operations/AGENT_ROLE_RECONCILIATION.md",
    ROOT / "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
]

AGENT_PROMPT_PATHS = [
    ROOT / "AGENTS.md",
]
AGENT_PROMPT_PATHS += sorted(Path(".codex/agents").glob("*.md"))
AGENT_PROMPT_PATHS += sorted(Path(".cursor/agents").glob("*.md"))

CANONICAL_ROLES = {
    "DB/Schema Agent",
    "Runtime/Orchestration Agent",
    "Security Guardian Agent",
    "Compliance / Invariant Mapper Agent",
    "Evidence & Audit Agent",
    "Human Approver",
    "QA Verifier",
    "Supervisor",
}

def fail(code, message, files=None):
    FAILURES.append({
        "code": code,
        "message": message,
        "files": files or []
    })

def read_file(path):
    return path.read_text(encoding="utf-8", errors="ignore")

def ensure_canonical_docs():
    for doc in CANONICAL_DOCS:
        if not doc.exists() or not doc.read_text(encoding="utf-8").strip():
            fail("CONFORMANCE_001_CANONICAL_MISSING", f"Missing or empty canonical doc: {doc}", [str(doc)])

def validate_agent_prompts():
    role_rows = []
    for path in AGENT_PROMPT_PATHS:
        if not path.exists():
            fail("CONFORMANCE_001_CANONICAL_MISSING", f"Agent prompt missing: {path}", [str(path)])
            continue
        content = read_file(path)
        if (
            "docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md" not in content
            or "docs/operations/AGENT_ROLE_RECONCILIATION.md" not in content
            or "docs/operations/AI_AGENT_OPERATION_MANUAL.md" not in content
        ):
            fail("CONFORMANCE_004_CANONICAL_REFERENCE_MISSING",
                 f"Missing canonical doc reference in {path}", [str(path)])
        if not re.search(r"^##\s+Stop Conditions", content, re.MULTILINE) and \
           not re.search(r"^##\s+Escalation", content, re.MULTILINE):
            fail("CONFORMANCE_005_STOP_CONDITIONS_INVALID", f"Stop Conditions / Escalation section missing in {path}", [str(path)])
        if re.search(r"^##\s+Role", content, re.MULTILINE) is None or "Role:" not in content:
            fail("CONFORMANCE_003_ROLE_INVALID", f"Missing Role line in {path}", [str(path)])
        role_match = re.search(r"^Role:\s*(.+)$", content, re.MULTILINE)
        if not role_match:
            fail("CONFORMANCE_003_ROLE_INVALID", f"Role declaration missing in {path}", [str(path)])
            role_rows.append({"path": str(path), "role": "", "valid": False})
        else:
            role_value = role_match.group(1).strip()
            if role_value not in CANONICAL_ROLES:
                fail("CONFORMANCE_003_ROLE_INVALID", f"Invalid role '{role_value}' in {path}", [str(path)])
                role_rows.append({"path": str(path), "role": role_value, "valid": False})
            else:
                role_rows.append({"path": str(path), "role": role_value, "valid": True})
        for heading in ["Scope", "Non-Negotiables", "Verification Commands", "Evidence Outputs", "Canonical References"]:
            if not re.search(rf"^##\s+{heading}", content, re.MULTILINE):
                fail("CONFORMANCE_002_PROMPT_HEADERS_MISSING", f"Missing header '{heading}' in {path}", [str(path)])
    return role_rows

def parse_regulated_surfaces():
    manual = read_file(ROOT / "docs/operations/AI_AGENT_OPERATION_MANUAL.md")
    marker = "## Definitions (Phase-1 Regulated Surfaces)"
    idx = manual.find(marker)
    if idx == -1:
        fail("CONFORMANCE_006_OPERATION_MANUAL_INVALID", "Missing regulated surfaces section")
        return []
    rest = manual[idx + len(marker):]
    lines = []
    capturing = False
    for line in rest.splitlines():
        line = line.strip()
        if not line:
            if capturing:
                break
            continue
        if line.startswith("-"):
            capturing = True
            lines.append(line[1:].strip())
        elif capturing:
            break
    if not lines:
        fail("CONFORMANCE_006_OPERATION_MANUAL_INVALID", "No regulated surfaces listed")
    return lines

def determine_changed_files():
    base_ref = os.environ.get("BASE_REF") or os.environ.get("GITHUB_BASE_REF")
    files = []
    mode = "FULL_SCAN"
    if base_ref:
        try:
            subprocess.run(["git", "rev-parse", "--verify", base_ref], check=True, stdout=subprocess.DEVNULL)
            diff = subprocess.check_output(["git", "diff", "--name-only", f"{base_ref}...HEAD"], text=True)
            files = [line.strip() for line in diff.splitlines() if line.strip()]
            mode = "DIFF_AWARE"
        except subprocess.CalledProcessError:
            files = []
    else:
        status = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"], text=True)
        files = [line[3:] for line in status.splitlines() if line]
    return mode, set(files)

def matches_regulated(path, surface_patterns):
    for pattern in surface_patterns:
        normalized = pattern.rstrip("/").replace("**", "")
        if normalized and path.startswith(normalized):
            return True
        if normalized == path:
            return True
    return False

def check_approval_metadata(regulated_changed):
    metadata_file = ROOT / "evidence/phase1/approval_metadata.json"
    if not regulated_changed and not metadata_file.exists():
        return False
    if not metadata_file.exists():
        fail("CONFORMANCE_007_APPROVAL_METADATA_MISSING", "Regulated surfaces changed but approval metadata missing")
        return False
    data = json.loads(metadata_file.read_text(encoding="utf-8"))
    for field in ["ai_prompt_hash", "model_id"]:
        if not data.get("ai", {}).get(field):
            fail("CONFORMANCE_008_APPROVAL_METADATA_INVALID", f"Approval metadata missing ai.{field}")
    human = data.get("human_approval", {})
    missing = [key for key in ["approver_id", "approval_artifact_ref", "change_reason"] if not human.get(key)]
    if missing:
        fail("CONFORMANCE_008_APPROVAL_METADATA_INVALID", f"Approval metadata missing fields: {missing}")
    approval_ref = ROOT / human.get("approval_artifact_ref", "")
    if not approval_ref.exists():
        fail("CONFORMANCE_009_APPROVAL_MARKDOWN_INVALID", f"Approval markdown {approval_ref} missing")
        return True
    content = read_file(approval_ref)
    if "## 8. Cross-References (Machine-Readable)" not in content:
        fail("CONFORMANCE_009_APPROVAL_MARKDOWN_INVALID", f"Approval markdown missing cross-reference header: {approval_ref}")
    match = re.search(r"Approval Sidecar JSON:\s*(\S+)", content)
    if not match:
        fail("CONFORMANCE_009_APPROVAL_MARKDOWN_INVALID", f"Approval markdown missing sidecar reference in {approval_ref}")
        return True
    sidecar_path = ROOT / match.group(1)
    if not sidecar_path.exists():
        fail("CONFORMANCE_010_APPROVAL_SIDECAR_INVALID", f"Sidecar not found: {sidecar_path}")
        return True
    sidecar = json.loads(sidecar_path.read_text(encoding="utf-8"))
    for field in ["ai", "approval"]:
        if field not in sidecar:
            fail("CONFORMANCE_010_APPROVAL_SIDECAR_INVALID", f"Sidecar missing field: {field}")
    # cross-check values
    if sidecar.get("ai", {}).get("ai_prompt_hash") != data.get("ai", {}).get("ai_prompt_hash"):
        fail("CONFORMANCE_011_APPROVAL_MISMATCH", "Prompt hash mismatch between metadata and sidecar")
    if sidecar.get("ai", {}).get("model_id") != data.get("ai", {}).get("model_id"):
        fail("CONFORMANCE_011_APPROVAL_MISMATCH", "Model id mismatch between metadata and sidecar")
    if sidecar.get("approval", {}).get("approver_id") != human.get("approver_id"):
        fail("CONFORMANCE_011_APPROVAL_MISMATCH", "Approver id mismatch between metadata and sidecar")
    for val in human.values():
        if isinstance(val, str) and ("@" in val or re.search(r"\\d{11,}", val)):
            fail("CONFORMANCE_012_PII_LEAK_DETECTED", f"Potential PII pattern in approval metadata: {val}")
    return True

def compute_hash(path):
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()

def main():
    ensure_canonical_docs()
    role_rows = validate_agent_prompts()
    surfaces = parse_regulated_surfaces()
    mode, changed_files = determine_changed_files()
    regulated_changed = any(matches_regulated(path, surfaces) for path in changed_files)
    approval_present = check_approval_metadata(regulated_changed)

    evidence = {
        "check_id": "AGENT-CONFORMANCE",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "schema_version": "1.0",
        "status": "PASS" if not FAILURES else "FAIL",
        "checked_at_utc": datetime.now(timezone.utc).isoformat(),
        "git_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
        "mode": mode,
        "canonical_docs": [
            {
                "path": str(doc),
                "exists": doc.exists(),
                "sha256": compute_hash(doc) if doc.exists() else None
            } for doc in CANONICAL_DOCS
        ],
        "agent_files_checked": {
            "count": len(AGENT_PROMPT_PATHS),
            "files": [str(p) for p in AGENT_PROMPT_PATHS]
        },
        "required_headers": {
            "prompts": ["Role", "Scope", "Non-Negotiables", "Stop Conditions", "Verification Commands", "Evidence Outputs", "Canonical References"],
            "approval": ["1. Summary of Change", "2. Scope of Impact", "3. Invariants & Phase Discipline", "4. AI Involvement Disclosure", "5. Verification & Evidence", "6. Risk Assessment", "7. Approval", "8. Cross-References (Machine-Readable)"]
        },
        "regulated_surface_changes_detected": regulated_changed,
        "regulated_surface_changed_paths": sorted(list(changed_files)) if regulated_changed else [],
        "approval_required": regulated_changed,
        "approval_metadata_present": approval_present,
        "approval_metadata_ref": str(ROOT / "evidence/phase1/approval_metadata.json") if (ROOT / "evidence/phase1/approval_metadata.json").exists() else None,
        "failures": FAILURES,
    }
    EVIDENCE_FILE.parent.mkdir(parents=True, exist_ok=True)
    EVIDENCE_FILE.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    role_mapping_evidence = {
        "check_id": "AGENT-ROLE-MAPPING",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "PASS" if not FAILURES else "FAIL",
        "canonical_roles": sorted(CANONICAL_ROLES),
        "agent_role_rows": role_rows,
    }
    Path(os.environ["ROLE_MAPPING_EVIDENCE_FILE"]).write_text(
        json.dumps(role_mapping_evidence, indent=2) + "\n", encoding="utf-8"
    )
    print("CONFORMANCE", "FAIL" if FAILURES else "PASS")
    if FAILURES:
        for f in FAILURES:
            print("-", f["code"], f["message"])
        sys.exit(1)
    else:
        print("evidence_written:", EVIDENCE_FILE)

main()
PY

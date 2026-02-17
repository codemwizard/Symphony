#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCAN_ROOT="${SCAN_ROOT:-$ROOT_DIR}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="${EVIDENCE_FILE:-$EVIDENCE_DIR/no_mcp_phase1_guard.json}"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP ROOT_DIR SCAN_ROOT EVIDENCE_FILE

python3 - <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
scan_root = Path(os.environ["SCAN_ROOT"])
evidence_file = Path(os.environ["EVIDENCE_FILE"])

hits = []
errors = []

if not scan_root.exists():
    errors.append(f"scan_root_missing:{scan_root}")

allowlist = [
    re.compile(r"^scripts/audit/verify_no_mcp_phase1\.sh$"),
    re.compile(r"^scripts/audit/tests/test_no_mcp_phase1_guard\.sh$"),
    re.compile(r"^scripts/audit/tests/fixtures/no_mcp/"),
    re.compile(r"^tasks/TSK-P1-033/meta\.yml$"),
    re.compile(r"^docs/plans/phase1/TSK-P1-033_"),
    re.compile(r"^docs/plans/phase2/"),
    re.compile(r"^tasks/TSK-P2-"),
    re.compile(r"^docs/phase-2/"),
    re.compile(r"^tasks/TSK-P1-0(28|29|30|31|32)/meta\.yml$"),
    re.compile(r"^docs/plans/phase1/TSK-P1-0(28|29|30|31|32)_"),
]

scan_globs = [
    "scripts/**/*.sh",
    "docs/PHASE1/**/*",
    "docs/plans/phase1/**/*.md",
    "tasks/TSK-P1-*/meta.yml",
    ".github/workflows/**/*.yml",
]

banned_files = [
    ("mcp_config_root", Path("mcp.json")),
    ("mcp_policy_verifier", Path("scripts/audit/verify_mcp_policy.sh")),
    ("mcp_connectivity_verifier", Path("scripts/audit/verify_mcp_connectivity.sh")),
]

patterns = [
    ("mcp_servers_json", re.compile(r'"mcpServers"')),
    ("mcp_package_ref", re.compile(r"@modelcontextprotocol/")),
    ("mcp_env_flag", re.compile(r"\bMCP_[A-Z0-9_]+\b")),
    ("mcp_policy_evidence", re.compile(r"evidence/phase1/mcp_policy\.json")),
    ("mcp_runtime_evidence", re.compile(r"evidence/phase1/orchestration_runtime\.json")),
    ("mcp_verifier_ref", re.compile(r"verify_mcp_(policy|connectivity)\.sh")),
    ("mcp_config_ref", re.compile(r"\bmcp\.json\b")),
]

def is_allowlisted(rel: str) -> bool:
    return any(p.search(rel) for p in allowlist)

for tag, rel in banned_files:
    p = scan_root / rel
    if p.exists() and not is_allowlisted(str(rel)):
        hits.append({"path": str(rel), "match_type": tag, "line": 0})

seen = set()
for g in scan_globs:
    for p in scan_root.glob(g):
        if p.is_dir():
            continue
        rel = p.relative_to(scan_root).as_posix()
        if rel in seen or is_allowlisted(rel):
            continue
        seen.add(rel)
        txt = p.read_text(encoding="utf-8", errors="ignore")
        for lineno, line in enumerate(txt.splitlines(), start=1):
            for tag, pat in patterns:
                if pat.search(line):
                    hits.append({"path": rel, "match_type": tag, "line": lineno})

status = "PASS" if not hits and not errors else "FAIL"
out = {
    "check_id": "NO-MCP-PHASE1-GUARD",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "scan_root": str(scan_root),
    "forbidden_hits_count": len(hits),
    "hits": hits,
    "errors": errors,
}
evidence_file.parent.mkdir(parents=True, exist_ok=True)
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Phase-1 no-MCP guard failed")
    for item in hits:
        print(f" - {item['match_type']}:{item['path']}:{item['line']}")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)

print(f"Phase-1 no-MCP guard passed. Evidence: {evidence_file}")
PY

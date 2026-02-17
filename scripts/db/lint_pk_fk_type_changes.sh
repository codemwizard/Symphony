#!/usr/bin/env bash
set -euo pipefail

# Phase-0 PK/FK type stability guardrail (static lint over migration files).
#
# Intent: prevent "quiet" type churn on key columns that breaks N-1 assumptions and rollback-by-routing.
# This is a conservative, high-signal lint: any ALTER COLUMN ... TYPE is flagged unless allowlisted
# (legacy migration) or explicitly waived via marker in the file.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_DIR="$ROOT_DIR/schema/migrations"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/pk_fk_type_stability.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<'PY' "$MIG_DIR" "$EVIDENCE_FILE"
import json
import os
import re
import sys
from pathlib import Path

mig_dir = Path(sys.argv[1])
out_path = Path(sys.argv[2])

ts = os.environ.get("EVIDENCE_TS")
sha = os.environ.get("EVIDENCE_GIT_SHA")
fp = os.environ.get("EVIDENCE_SCHEMA_FP")

tag_re = re.compile(r"\$[A-Za-z0-9_]*\$")
stmt_end_re = re.compile(r";\s*(?:--.*)?$")
type_change_re = re.compile(r"\balter\s+column\b.*\btype\b", re.I)
waiver_marker_re = re.compile(r"--\s*symphony:pk_fk_type_change_waiver\b", re.I)

# Explicit allowlist for legacy migrations (file:start_lineno) that predate this lint.
ALLOWLIST = {
    ("0017_ingress_tenant_attribution.sql", 5),
}

def extract_statements(path: Path):
    in_block = False
    tag = None
    stmts = []

    buf = []
    start = None
    waiver_active = False

    def flush():
        nonlocal buf, start, waiver_active
        if not buf:
            return
        stmts.append(
            {
                "start_lineno": start or 1,
                "sql": "\n".join(buf).strip(),
                "waived": waiver_active,
            }
        )
        buf = []
        start = None
        waiver_active = False

    def is_blank_or_comment(ln: str) -> bool:
        s = ln.strip()
        return (not s) or s.startswith("--")

    with path.open("r", encoding="utf-8", errors="ignore") as fh:
        for lineno, line in enumerate(fh, 1):
            for m in tag_re.finditer(line):
                tok = m.group(0)
                if not in_block:
                    in_block = True
                    tag = tok
                elif tok == tag:
                    in_block = False
                    tag = None
            if in_block:
                continue

            if waiver_marker_re.search(line):
                waiver_active = True

            # Statement attribution should point at the first non-comment SQL line, not file headers.
            if start is None and (not is_blank_or_comment(line)):
                start = lineno
            buf.append(line.rstrip("\n"))

            if stmt_end_re.search(line):
                flush()

    flush()
    return stmts

scanned = []
violations = []
allowlisted = []
waived = []

for p in sorted(mig_dir.glob("*.sql")):
    scanned.append(p.name)
    for st in extract_statements(p):
        sql = st["sql"]
        if not sql:
            continue
        if not type_change_re.search(sql):
            continue

        item = {
            "file": p.name,
            "start_lineno": st["start_lineno"],
            "sql": sql.splitlines()[0][:240],
        }
        if (p.name, st["start_lineno"]) in ALLOWLIST:
            allowlisted.append(item)
        elif st["waived"]:
            item["waiver"] = "symphony:pk_fk_type_change_waiver"
            waived.append(item)
        else:
            violations.append(item)

status = "PASS" if not violations else "FAIL"
out = {
    "check_id": "DB-PK-FK-TYPE-STABILITY",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": fp,
    "status": status,
    "scanned_files": scanned,
    "type_changes_found": len(violations) + len(allowlisted) + len(waived),
    "violations": violations,
    "allowlisted": allowlisted,
    "waived": waived,
    "notes": [
        "Conservative lint: any ALTER COLUMN ... TYPE is treated as key-type churn unless explicitly waived.",
        "Legacy allowlist is explicit and intentionally small.",
    ],
}

out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print(f"❌ PK/FK type stability lint failed. Evidence: {out_path}", file=sys.stderr)
    for it in violations[:50]:
        print(f" - {it['file']}:{it['start_lineno']} {it.get('sql','')}", file=sys.stderr)
    raise SystemExit(1)

print(f"PK/FK type stability lint OK. Evidence: {out_path}")
PY

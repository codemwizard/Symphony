#!/usr/bin/env bash
set -euo pipefail

# Phase-0 expand/contract guardrails (static lint over migration files).
#
# Locked decisions (AuditAnswers.txt):
# - Phase-0 forbids `-- symphony:contract_cleanup` entirely (hard FAIL)
# - Phase-0 forbids any `ADD COLUMN ... NOT NULL` in migrations (2-step expand/backfill/contract-later)
# - Phase-0 forbids destructive DDL (DROP TABLE, TRUNCATE, ALTER TABLE ... DROP COLUMN, etc.)
#
# NOTE: This lint is introduced after some migrations already exist. We keep a tiny, explicit
# allowlist for legacy statements so that we can enforce the rule for all new work without
# editing applied migrations.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_DIR="$ROOT_DIR/schema/migrations"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/migration_expand_contract_policy.json"

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

contract_cleanup_re = re.compile(r"--\s*symphony:contract_cleanup", re.I)
drop_table_re = re.compile(r"^\s*drop\s+table\b", re.I)
drop_schema_re = re.compile(r"^\s*drop\s+schema\b", re.I)
truncate_re = re.compile(r"^\s*truncate\b", re.I)
alter_drop_column_re = re.compile(r"\balter\s+table\b.*\bdrop\s+column\b", re.I)
alter_set_not_null_re = re.compile(r"\balter\s+table\b.*\balter\s+column\b.*\bset\s+not\s+null\b", re.I)
add_column_not_null_re = re.compile(r"\badd\s+column\b.*\bnot\s+null\b", re.I)

tag_re = re.compile(r"\$[A-Za-z0-9_]*\$")

# Tiny explicit allowlist for legacy migrations (file:lineno) that predate this lint.
ALLOWLIST = {
    # 0020_business_foundation_hooks.sql added `signatures` as NOT NULL for ingress_attestations.
    # Phase-0 guardrail now forbids this pattern for new migrations.
    ("0020_business_foundation_hooks.sql", 164, "add_column_not_null"),
}

def scan_file(path: Path):
    in_block = False
    tag = None
    violations = []
    allowlisted = []

    with path.open("r", encoding="utf-8", errors="ignore") as fh:
        for lineno, line in enumerate(fh, 1):
            # Toggle dollar-quoted blocks (function bodies).
            for m in tag_re.finditer(line):
                tok = m.group(0)
                if not in_block:
                    in_block = True
                    tag = tok
                elif tok == tag:
                    in_block = False
                    tag = None

            if contract_cleanup_re.search(line):
                violations.append(
                    {
                        "file": path.name,
                        "lineno": lineno,
                        "kind": "contract_cleanup_marker",
                        "line": line.strip(),
                    }
                )
                continue

            if in_block:
                continue

            kind = None
            if drop_table_re.search(line):
                kind = "drop_table"
            elif drop_schema_re.search(line):
                kind = "drop_schema"
            elif truncate_re.search(line):
                kind = "truncate"
            elif alter_drop_column_re.search(line):
                kind = "alter_drop_column"
            elif alter_set_not_null_re.search(line):
                kind = "alter_set_not_null"
            elif add_column_not_null_re.search(line):
                kind = "add_column_not_null"

            if not kind:
                continue

            item = {"file": path.name, "lineno": lineno, "kind": kind, "line": line.strip()}
            if (path.name, lineno, kind) in ALLOWLIST:
                allowlisted.append(item)
            else:
                violations.append(item)

    return violations, allowlisted

scanned = []
violations = []
allowlisted = []

for p in sorted(mig_dir.glob("*.sql")):
    v, a = scan_file(p)
    scanned.append(p.name)
    violations.extend(v)
    allowlisted.extend(a)

status = "PASS" if not violations else "FAIL"

out = {
    "check_id": "DB-EXPAND-CONTRACT-POLICY",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": fp,
    "status": status,
    "scanned_files": scanned,
    "violation_count": len(violations),
    "violations": violations,
    "allowlisted_count": len(allowlisted),
    "allowlisted": allowlisted,
    "notes": [
        "Phase-0 forbids contract_cleanup marker and destructive DDL.",
        "Phase-0 forbids any ADD COLUMN ... NOT NULL; legacy allowlist is explicit and tiny.",
    ],
}

out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print(f"❌ Expand/contract policy lint failed. Evidence: {out_path}", file=sys.stderr)
    for it in violations[:50]:
        print(f" - {it['file']}:{it['lineno']} {it['kind']}: {it.get('line','')}", file=sys.stderr)
    raise SystemExit(1)

print(f"Expand/contract policy lint OK. Evidence: {out_path}")
PY


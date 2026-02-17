#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_DECISION="$EVIDENCE_DIR/rebaseline_decision.json"
EVIDENCE_SNAPSHOT="$EVIDENCE_DIR/baseline_snapshot.json"
EVIDENCE_STRATEGY="$EVIDENCE_DIR/baseline_strategy.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

ROOT_DIR="$ROOT_DIR" \
EVIDENCE_DECISION="$EVIDENCE_DECISION" \
EVIDENCE_SNAPSHOT="$EVIDENCE_SNAPSHOT" \
EVIDENCE_STRATEGY="$EVIDENCE_STRATEGY" \
python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
evidence_decision = Path(os.environ["EVIDENCE_DECISION"])
evidence_snapshot = Path(os.environ["EVIDENCE_SNAPSHOT"])
evidence_strategy = Path(os.environ["EVIDENCE_STRATEGY"])

adr = root / "docs/decisions/ADR-0011-rebaseline-dayzero-schema.md"
decision = root / "docs/decisions/Rebaseline-Decision.md"
baseline = root / "schema/baselines/current/0001_baseline.sql"
cutoff = root / "schema/baselines/current/baseline.cutoff"
canon = root / "scripts/db/canonicalize_schema_dump.sh"
regen = root / "scripts/db/generate_baseline_snapshot.sh"
migrate = root / "scripts/db/migrate.sh"

errors = []
details = {
    "missing": [],
    "checks": {}
}

def check_exists(path: Path, key: str):
    if not path.exists():
        details["missing"].append(str(path))
        details["checks"][key] = False
        return False
    details["checks"][key] = True
    return True

check_exists(adr, "adr")
check_exists(decision, "decision")
check_exists(baseline, "baseline")
check_exists(cutoff, "cutoff")
check_exists(canon, "canonicalizer")
check_exists(regen, "snapshot_generator")
check_exists(migrate, "migrate_script")

if decision.exists() and adr.exists():
    text = decision.read_text(encoding="utf-8")
    details["checks"]["decision_refs_adr"] = "ADR-0011" in text
    if not details["checks"]["decision_refs_adr"]:
        errors.append("decision_missing_adr_reference")

if cutoff.exists():
    content = cutoff.read_text(encoding="utf-8").strip()
    details["checks"]["cutoff_nonempty"] = bool(content)
    if not content:
        errors.append("cutoff_empty")

if migrate.exists():
    mtext = migrate.read_text(encoding="utf-8")
    details["checks"]["migrate_strategy_flag"] = "SCHEMA_MIGRATION_STRATEGY" in mtext
    details["checks"]["migrate_baseline_path"] = "SCHEMA_BASELINE_PATH" in mtext
    if not details["checks"]["migrate_strategy_flag"]:
        errors.append("migrate_missing_strategy_flag")

if details["missing"]:
    errors.append("rebaseline_missing_files")

base_result = {
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "details": details,
}

outputs = [
    ("REBASELINE-DECISION", evidence_decision),
    ("BASELINE-SNAPSHOT", evidence_snapshot),
    ("BASELINE-STRATEGY", evidence_strategy),
]

# Always write evidence (even on failure)
for check_id, path in outputs:
    payload = dict(base_result)
    payload["check_id"] = check_id
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

if errors:
    for err in errors:
        print(f"ERROR: {err}")
    raise SystemExit(1)

print("Rebaseline strategy verification passed.")
PY

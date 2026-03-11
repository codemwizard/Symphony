#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-001"
LOCK_FILE="$ROOT_DIR/docs/operations/GREENTECH4CE_PRECODING_LOCK.yml"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_001_pre_coding_lock.json}"

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

python3 - <<'PY' "$LOCK_FILE" "$EVIDENCE_PATH" "$TASK_ID" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP"
import json
import sys
from pathlib import Path
import yaml

lock_file, evidence_path, task_id, ts, sha, sfp = sys.argv[1:]
lf = Path(lock_file)
if not lf.exists():
    raise SystemExit(f"missing_lock_file:{lf}")

data = yaml.safe_load(lf.read_text(encoding="utf-8"))
required_top = ["status", "confirmations", "references", "document", "section"]
for key in required_top:
    if key not in data:
        raise SystemExit(f"missing_key:{key}")

if str(data.get("status", "")).upper() != "APPROVED":
    raise SystemExit(f"lock_not_approved:{data.get('status')}")

confirmations = data.get("confirmations") or {}
required_true = [
    "db_engine_confirmed",
    "tenant_isolation_pattern_confirmed",
    "evidence_event_append_only_confirmed",
    "proof_type_registry_confirmed",
    "section4_checklist_signed_off",
]
missing_or_false = [k for k in required_true if confirmations.get(k) is not True]
if missing_or_false:
    raise SystemExit(f"missing_confirmations:{','.join(missing_or_false)}")

refs = data.get("references") or {}
for key in ("startup_review", "signoff_review", "prd_source"):
    if not refs.get(key):
        raise SystemExit(f"missing_reference:{key}")

payload = {
    "check_id": "TSK-P1-DEMO-001-PRECODING-LOCK",
    "task_id": task_id,
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": sfp,
    "status": "PASS",
    "pass": True,
    "details": {
        "lock_file": str(Path(lock_file).relative_to(Path(lock_file).parents[2])),
        "source_document": data.get("document"),
        "source_section": data.get("section"),
        "required_confirmations": required_true,
        "all_required_confirmations_true": True,
    },
}
Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY


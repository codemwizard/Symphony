#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )/../.." && pwd)"
LOADER="$ROOT_DIR/scripts/services/rail_inquiry_policy_loader.py"
STORE_SRC="$ROOT_DIR/config/hardening/rail_inquiry_policies.json"
STORE_SCHEMA="$ROOT_DIR/evidence/schemas/hardening/rail_inquiry_policy.schema.json"

[[ -x "$LOADER" ]] || { echo "missing_loader" >&2; exit 1; }
[[ -f "$STORE_SRC" ]] || { echo "missing_policy_store" >&2; exit 1; }
[[ -f "$STORE_SCHEMA" ]] || { echo "missing_policy_store_schema" >&2; exit 1; }

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
STORE="$TMP_DIR/policy_store.json"
INQUIRY_EVENT="$TMP_DIR/inquiry_decision_event.json"
DECISION_LOG="$TMP_DIR/decision_log.jsonl"
ACT_EVENT="$TMP_DIR/policy_activation_event.json"

cp "$STORE_SRC" "$STORE"

# Inject a second version to prove decision snapshots are immutable after active version changes.
STORE="$STORE" python3 - <<'PY'
import json
import os
from pathlib import Path
p = Path(os.environ["STORE"])
d = json.loads(p.read_text())
if not any(v.get("version_id") == "RIP-2026-03-05-v2" for v in d.get("versions", [])):
    base = next(v for v in d["versions"] if v["version_id"] == d["active_version_id"])
    v2 = json.loads(json.dumps(base))
    v2["version_id"] = "RIP-2026-03-05-v2"
    v2["created_at"] = "2026-03-05T01:00:00Z"
    d["versions"].append(v2)
p.write_text(json.dumps(d, indent=2) + "\n")
PY

# Capture decision snapshot while v1 is active.
python3 "$LOADER" \
  --store "$STORE" \
  --schema "$STORE_SCHEMA" \
  --rail-id ZIPSS \
  --emit-inquiry-evidence "$INQUIRY_EVENT" \
  --emit-decision-log "$DECISION_LOG" >/dev/null

# Activate new version, then capture a new decision.
STORE="$STORE" python3 - <<'PY'
import json
import os
from pathlib import Path
p = Path(os.environ["STORE"])
d = json.loads(p.read_text())
d["active_version_id"] = "RIP-2026-03-05-v2"
p.write_text(json.dumps(d, indent=2) + "\n")
PY

python3 "$LOADER" \
  --store "$STORE" \
  --schema "$STORE_SCHEMA" \
  --rail-id ZIPSS \
  --emit-decision-log "$DECISION_LOG" >/dev/null

python3 "$LOADER" \
  --store "$STORE" \
  --schema "$STORE_SCHEMA" \
  --activate-version-id RIP-2026-03-05-v2 \
  --activated-by hardening-supervisor \
  --activation-evidence "$ACT_EVENT" >/dev/null

ROOT_DIR="$ROOT_DIR" INQUIRY_EVENT="$INQUIRY_EVENT" DECISION_LOG="$DECISION_LOG" ACT_EVENT="$ACT_EVENT" python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
inquiry = json.loads(Path(os.environ["INQUIRY_EVENT"]).read_text())
lines = [json.loads(ln) for ln in Path(os.environ["DECISION_LOG"]).read_text().splitlines() if ln.strip()]
activation = json.loads(Path(os.environ["ACT_EVENT"]).read_text())

if len(lines) != 2:
    raise SystemExit("decision_log_count_invalid")
first, second = lines
if first.get("policy_version_id") != "RIP-2026-03-05-v1":
    raise SystemExit("first_decision_snapshot_invalid")
if second.get("policy_version_id") != "RIP-2026-03-05-v2":
    raise SystemExit("second_decision_snapshot_invalid")
if inquiry.get("event_class") != "inquiry_event":
    raise SystemExit("inquiry_event_class_invalid")
if not inquiry.get("policy_version_id"):
    raise SystemExit("inquiry_policy_version_missing")
if activation.get("event_class") != "policy_activation_event":
    raise SystemExit("activation_event_missing")
if activation.get("unsigned_reason") != "DEPENDENCY_NOT_READY":
    raise SystemExit("activation_unsigned_reason_invalid")

out = {
    "check_id": "TSK-HARD-011A",
    "task_id": "TSK-HARD-011A",
    "status": "PASS",
    "pass": True,
    "decision_snapshot_captured": True,
    "historical_policy_version_immutable": True,
    "inquiry_event_schema_class": inquiry.get("event_class"),
    "policy_activation_event_emitted": True,
    "activation_unsigned_reason": activation.get("unsigned_reason")
}
out_path = root / "evidence/phase1/hardening/tsk_hard_011a.json"
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(out, indent=2) + "\n")
print("TSK-HARD-011A verifier: PASS")
print(f"Evidence: {out_path}")
PY

# Validate inquiry_event sample against the registered event class schema.
TMP_EVID_PHASE0="$TMP_DIR/phase0"
TMP_EVID_PHASE1="$TMP_DIR/phase1"
mkdir -p "$TMP_EVID_PHASE0" "$TMP_EVID_PHASE1"
cp "$INQUIRY_EVENT" "$TMP_EVID_PHASE1/inquiry_event_sample.json"

EVIDENCE_DIR="$TMP_EVID_PHASE0" \
EVIDENCE_DIR_PHASE1="$TMP_EVID_PHASE1" \
REPORT_FILE="$TMP_EVID_PHASE0/report.json" \
EVENT_CLASS_SCHEMAS_DIR="$ROOT_DIR/evidence/schemas/hardening/event_classes" \
SCHEMA_FILE="$ROOT_DIR/docs/architecture/evidence_schema.json" \
APPROVAL_SCHEMA_FILE="$ROOT_DIR/docs/operations/approval_metadata.schema.json" \
  bash "$ROOT_DIR/scripts/audit/validate_evidence_schema.sh" >/dev/null

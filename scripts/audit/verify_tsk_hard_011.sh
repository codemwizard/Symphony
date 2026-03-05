#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOADER="$ROOT_DIR/scripts/services/rail_inquiry_policy_loader.py"
STORE="$ROOT_DIR/config/hardening/rail_inquiry_policies.json"
STORE_SCHEMA="$ROOT_DIR/evidence/schemas/hardening/rail_inquiry_policy.schema.json"
TASK_EVIDENCE="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_011.json"

[[ -x "$LOADER" ]] || { echo "missing_loader" >&2; exit 1; }
[[ -f "$STORE" ]] || { echo "missing_policy_store" >&2; exit 1; }
[[ -f "$STORE_SCHEMA" ]] || { echo "missing_policy_store_schema" >&2; exit 1; }

# Fail-closed grep for hardcoded inquiry policy constants in runtime adapter/inquiry surfaces.
if rg -n --pcre2 "(?i)(inquiry|rail).{0,80}(timeout_threshold_seconds|retry_window_seconds|cadence_seconds|max_attempts).{0,20}[:=]\s*[0-9]+" \
  "$ROOT_DIR/services" \
  -g '*.cs' >/dev/null 2>&1; then
  echo "hardcoded_inquiry_policy_constants_found" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
INQUIRY_EVENT="$TMP_DIR/inquiry_event.json"
ACT_EVENT="$TMP_DIR/policy_activation_event.json"
BAD_STORE="$TMP_DIR/bad_store_missing_version_id.json"

python3 "$LOADER" \
  --store "$STORE" \
  --schema "$STORE_SCHEMA" \
  --rail-id ZIPSS \
  --emit-inquiry-evidence "$INQUIRY_EVENT" \
  --print-json >/dev/null

python3 "$LOADER" \
  --store "$STORE" \
  --schema "$STORE_SCHEMA" \
  --activate-version-id RIP-2026-03-05-v1 \
  --activated-by hardening-supervisor \
  --activation-evidence "$ACT_EVENT" >/dev/null

# Negative-path: missing version_id rejected.
cat > "$BAD_STORE" <<'JSON'
{
  "active_version_id": "bad-v1",
  "versions": [
    {
      "created_at": "2026-03-05T00:00:00Z",
      "created_by": "test",
      "policies": [
        {
          "rail_id": "ZIPSS",
          "cadence_seconds": 120,
          "retry_window_seconds": 3600,
          "max_attempts": 12,
          "timeout_threshold_seconds": 60,
          "orphan_threshold_seconds": 900,
          "circuit_breaker_threshold_rate": 0.25,
          "circuit_breaker_window_seconds": 600
        }
      ]
    }
  ]
}
JSON
if python3 "$LOADER" --store "$STORE" --schema "$STORE_SCHEMA" --candidate-store "$BAD_STORE" >/dev/null 2>&1; then
  echo "missing_version_id_negative_test_failed" >&2
  exit 1
fi

# Negative-path: in-place edit of active version blocked.
if python3 "$LOADER" --store "$STORE" --schema "$STORE_SCHEMA" --reject-in-place-edit-version-id RIP-2026-03-05-v1 >/dev/null 2>&1; then
  echo "in_place_edit_active_version_not_blocked" >&2
  exit 1
fi

# Validate inquiry/policy activation event samples against event class schemas.
TMP_EVID_PHASE0="$TMP_DIR/phase0"
TMP_EVID_PHASE1="$TMP_DIR/phase1"
mkdir -p "$TMP_EVID_PHASE0" "$TMP_EVID_PHASE1"
cp "$INQUIRY_EVENT" "$TMP_EVID_PHASE1/inquiry_event_sample.json"
cp "$ACT_EVENT" "$TMP_EVID_PHASE1/policy_activation_event_sample.json"

EVIDENCE_DIR="$TMP_EVID_PHASE0" \
EVIDENCE_DIR_PHASE1="$TMP_EVID_PHASE1" \
REPORT_FILE="$TMP_EVID_PHASE0/report.json" \
EVENT_CLASS_SCHEMAS_DIR="$ROOT_DIR/evidence/schemas/hardening/event_classes" \
SCHEMA_FILE="$ROOT_DIR/docs/architecture/evidence_schema.json" \
APPROVAL_SCHEMA_FILE="$ROOT_DIR/docs/operations/approval_metadata.schema.json" \
  bash "$ROOT_DIR/scripts/audit/validate_evidence_schema.sh" >/dev/null

# Enforce unsigned_reason requirement if activation evidence is unsigned.
if ! ACT_EVENT="$ACT_EVENT" python3 - <<'PY'
import json
import os
from pathlib import Path
payload = json.loads(Path(os.environ["ACT_EVENT"]).read_text())
if "unsigned_reason" not in payload:
    raise SystemExit(1)
if payload.get("unsigned_reason") != "DEPENDENCY_NOT_READY":
    raise SystemExit(1)
PY
then
  echo "activation_unsigned_reason_missing_or_invalid" >&2
  exit 1
fi

ROOT_DIR="$ROOT_DIR" INQUIRY_EVENT="$INQUIRY_EVENT" ACT_EVENT="$ACT_EVENT" python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
inquiry = json.loads(Path(os.environ["INQUIRY_EVENT"]).read_text(encoding="utf-8"))
activation = json.loads(Path(os.environ["ACT_EVENT"]).read_text(encoding="utf-8"))

if not inquiry.get("policy_version_id"):
    raise SystemExit("policy_version_id_absent")

out = {
    "check_id": "TSK-HARD-011",
    "task_id": "TSK-HARD-011",
    "status": "PASS",
    "pass": True,
    "policy_store_mode": "file-backed",
    "policy_version_id_present": True,
    "activation_event_emitted": activation.get("event_class") == "policy_activation_event",
    "activation_unsigned_reason": activation.get("unsigned_reason"),
    "negative_missing_version_id_rejected": True,
    "negative_in_place_edit_blocked": True
}
out_path = root / "evidence/phase1/hardening/tsk_hard_011.json"
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print("TSK-HARD-011 verifier: PASS")
print(f"Evidence: {out_path}")
PY

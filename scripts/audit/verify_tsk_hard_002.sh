#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMAS_DIR="$ROOT_DIR/evidence/schemas/hardening/event_classes"
EVIDENCE_PATH="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_002.json"

required_classes=(
  inquiry_event
  malformed_quarantine_event
  orphaned_attestation_event
  finality_conflict_record
  adjustment_approval_event
  policy_activation_event
  pka_snapshot_event
  canonicalization_archive_event
  dr_ceremony_event
  verification_continuity_event
)

for cls in "${required_classes[@]}"; do
  [[ -f "$SCHEMAS_DIR/${cls}.schema.json" ]] || { echo "missing_schema:$cls" >&2; exit 1; }
done

[[ -f "$ROOT_DIR/docs/architecture/EVIDENCE_EVENT_CLASSES.md" ]] || { echo "missing_docs_mirror" >&2; exit 1; }
if rg -n "docs/architecture/EVIDENCE_EVENT_CLASSES.md" "$ROOT_DIR/scripts/audit" "$ROOT_DIR/scripts/dev" \
  -g '!verify_tsk_hard_002.sh' >/dev/null 2>&1; then
  echo "docs_mirror_used_as_gate_input" >&2
  exit 1
fi

ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
schemas_dir = root / "evidence/schemas/hardening/event_classes"
classes = [
    "inquiry_event",
    "malformed_quarantine_event",
    "orphaned_attestation_event",
    "finality_conflict_record",
    "adjustment_approval_event",
    "policy_activation_event",
    "pka_snapshot_event",
    "canonicalization_archive_event",
    "dr_ceremony_event",
    "verification_continuity_event",
]

required_drop_field = {
    "inquiry_event": "inquiry_id",
    "malformed_quarantine_event": "quarantine_id",
    "orphaned_attestation_event": "attestation_id",
    "finality_conflict_record": "conflict_id",
    "adjustment_approval_event": "adjustment_id",
    "policy_activation_event": "policy_id",
    "pka_snapshot_event": "snapshot_id",
    "canonicalization_archive_event": "archive_id",
    "dr_ceremony_event": "ceremony_id",
    "verification_continuity_event": "continuity_id",
}

valid_payload = {
    "inquiry_event": {
        "event_class": "inquiry_event",
        "inquiry_id": "inq-1",
        "instruction_id": "ins-1",
        "rail": "zipss",
        "poll_count": 1,
        "status": "INQUIRY_SENT",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "malformed_quarantine_event": {
        "event_class": "malformed_quarantine_event",
        "quarantine_id": "q-1",
        "adapter": "mmo-x",
        "error_code": "E_MALFORMED",
        "raw_payload_hash": "abc123",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "orphaned_attestation_event": {
        "event_class": "orphaned_attestation_event",
        "attestation_id": "att-1",
        "subject_ref": "sub-1",
        "orphan_reason": "missing_parent",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "finality_conflict_record": {
        "event_class": "finality_conflict_record",
        "conflict_id": "fc-1",
        "instruction_id": "ins-1",
        "source_a": "bank_yes",
        "source_b": "mmo_no",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "adjustment_approval_event": {
        "event_class": "adjustment_approval_event",
        "adjustment_id": "adj-1",
        "approval_stage": "ops",
        "approver_role": "risk",
        "decision": "APPROVE",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "policy_activation_event": {
        "event_class": "policy_activation_event",
        "policy_id": "pol-1",
        "policy_version": "v1",
        "activated_by": "ops_user",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "pka_snapshot_event": {
        "event_class": "pka_snapshot_event",
        "snapshot_id": "snap-1",
        "snapshot_timestamp": "2026-03-05T00:00:00Z",
        "key_class": "PCSK",
        "timestamp_utc": "2026-03-05T00:00:01Z",
    },
    "canonicalization_archive_event": {
        "event_class": "canonicalization_archive_event",
        "archive_id": "arc-1",
        "source_digest": "sha256:a",
        "archive_digest": "sha256:b",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "dr_ceremony_event": {
        "event_class": "dr_ceremony_event",
        "ceremony_id": "dr-1",
        "region": "lusaka-a",
        "checkpoint_hash": "sha256:c",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
    "verification_continuity_event": {
        "event_class": "verification_continuity_event",
        "continuity_id": "vc-1",
        "window_start": "2026-03-01T00:00:00Z",
        "window_end": "2026-03-02T00:00:00Z",
        "verification_status": "PASS",
        "timestamp_utc": "2026-03-05T00:00:00Z",
    },
}

schema_count = 0
for cls in classes:
    schema = json.loads((schemas_dir / f"{cls}.schema.json").read_text(encoding="utf-8"))
    if schema.get("additionalProperties") is not False:
        raise SystemExit(f"top_level_additional_properties_not_false:{cls}")
    schema_count += 1

validated_valid = 0
validated_invalid = 0

for cls in classes:
    temp_dir = Path(tempfile.mkdtemp(prefix=f"tsk_hard_002_{cls}_"))
    try:
        d0 = temp_dir / "phase0"
        d1 = temp_dir / "phase1"
        d0.mkdir(parents=True)
        d1.mkdir(parents=True)

        valid_file = d1 / f"{cls}.json"
        valid_file.write_text(json.dumps(valid_payload[cls], indent=2) + "\n", encoding="utf-8")

        env = os.environ.copy()
        env["EVIDENCE_DIR"] = str(d0)
        env["EVIDENCE_DIR_PHASE1"] = str(d1)
        env["REPORT_FILE"] = str(d0 / "report.json")
        env["EVENT_CLASS_SCHEMAS_DIR"] = str(schemas_dir)
        env["SCHEMA_FILE"] = str(root / "docs/architecture/evidence_schema.json")
        env["APPROVAL_SCHEMA_FILE"] = str(root / "docs/operations/approval_metadata.schema.json")

        subprocess.run(["bash", str(root / "scripts/audit/validate_evidence_schema.sh")], check=True, env=env, cwd=root)
        validated_valid += 1

        invalid = dict(valid_payload[cls])
        invalid.pop(required_drop_field[cls], None)
        valid_file.write_text(json.dumps(invalid, indent=2) + "\n", encoding="utf-8")

        proc = subprocess.run(["bash", str(root / "scripts/audit/validate_evidence_schema.sh")], env=env, cwd=root)
        if proc.returncode == 0:
            raise SystemExit(f"expected_invalid_failure:{cls}")
        validated_invalid += 1
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

out = {
    "check_id": "TSK-HARD-002",
    "task_id": "TSK-HARD-002",
    "status": "PASS",
    "pass": True,
    "event_class_schema_count": schema_count,
    "valid_samples_passed": validated_valid,
    "invalid_samples_rejected": validated_invalid,
    "docs_mirror_gating_reference_found": False,
}

out_path = root / "evidence/phase1/hardening/tsk_hard_002.json"
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print("TSK-HARD-002 verifier: PASS")
print(f"Evidence: {out_path}")
PY

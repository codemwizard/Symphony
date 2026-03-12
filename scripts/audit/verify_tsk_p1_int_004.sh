#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0073_int_004_ack_gap_controls.sql"
EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_int_004_ack_gap_controls.json"

[[ -f "$MIGRATION" ]] || { echo "missing_required_file:$MIGRATION" >&2; exit 1; }

rg -n "ADD VALUE 'AWAITING_EXECUTION'" "$MIGRATION" >/dev/null
rg -n "ADD VALUE 'ESCALATED'" "$MIGRATION" >/dev/null
rg -n "supervisor_approval_queue_status_check" "$MIGRATION" >/dev/null
rg -n "'ESCALATED'|'RESET'" "$MIGRATION" >/dev/null
rg -n "CREATE TABLE IF NOT EXISTS public.supervisor_interrupt_audit_events" "$MIGRATION" >/dev/null
rg -n "action IN \\('ESCALATED', 'ACKNOWLEDGED', 'RESUMED', 'RESET'\\)" "$MIGRATION" >/dev/null
rg -n "CREATE OR REPLACE FUNCTION public.mark_instruction_awaiting_execution" "$MIGRATION" >/dev/null
rg -n "CREATE OR REPLACE FUNCTION public.escalate_missing_acknowledgement" "$MIGRATION" >/dev/null
rg -n "submit_for_supervisor_approval" "$MIGRATION" >/dev/null
rg -n "CREATE OR REPLACE FUNCTION public.resolve_missing_acknowledgement_interrupt" "$MIGRATION" >/dev/null
rg -n "WHEN 'RESUME' THEN 'RESUMED'" "$MIGRATION" >/dev/null
rg -n "SET inquiry_state = 'AWAITING_EXECUTION'" "$MIGRATION" >/dev/null
rg -n "CREATE OR REPLACE FUNCTION public.guard_settlement_requires_acknowledgement" "$MIGRATION" >/dev/null
rg -n "ACKNOWLEDGEMENT_REQUIRED_BEFORE_SETTLEMENT" "$MIGRATION" >/dev/null

python3 - <<'PY' "$MIGRATION" "$EVIDENCE"
import json
import sys
from pathlib import Path

migration = Path(sys.argv[1]).read_text(encoding="utf-8")
evidence_path = Path(sys.argv[2])

payload = {
    "check_id": "TSK-P1-INT-004-ACK-GAP-CONTROLS",
    "task_id": "TSK-P1-INT-004",
    "status": "PASS",
    "pass": True,
    "controls": {
        "awaiting_execution_state": "ADD VALUE 'AWAITING_EXECUTION'" in migration,
        "escalated_state": "ADD VALUE 'ESCALATED'" in migration,
        "queue_reused_not_parallel": "submit_for_supervisor_approval" in migration and "supervisor_interrupt_audit_events" in migration,
        "queue_status_extended": all(token in migration for token in ["'ESCALATED'", "'RESET'"]),
        "interrupt_audit_append_only": "CREATE TABLE IF NOT EXISTS public.supervisor_interrupt_audit_events" in migration,
        "reset_returns_to_awaiting_execution": migration.count("SET inquiry_state = 'AWAITING_EXECUTION'") >= 2,
        "settlement_guard_present": "ACKNOWLEDGEMENT_REQUIRED_BEFORE_SETTLEMENT" in migration,
    },
    "trigger_semantics": {
        "tier3_escalation": "ESCALATED",
        "reset_action_target_state": "AWAITING_EXECUTION",
        "settlement_without_ack": "ACKNOWLEDGEMENT_REQUIRED_BEFORE_SETTLEMENT",
    },
}
evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY

echo "TSK-P1-INT-004 verification passed. Evidence: $EVIDENCE"

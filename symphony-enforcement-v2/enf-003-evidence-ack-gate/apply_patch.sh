#!/usr/bin/env bash
# enf-003-evidence-ack-gate/apply_patch.sh
# Applies the evidence acknowledgement gate and retry counter to run_task.sh.
# Must be run AFTER enf-001 apply.sh (the DRD gate must already be present).
# Idempotent: skips if already applied.
# Run from repo root: bash _staging/symphony-enforcement-v2/enf-003-evidence-ack-gate/apply_patch.sh
set -euo pipefail

TARGET="scripts/agent/run_task.sh"
MARKER_GATE="ENF-003: evidence ack gate"
MARKER_FAILURE="ENF-003: retry counter increment on failure"
MARKER_SUCCESS="ENF-003: cleanup on success"

if grep -q "$MARKER_GATE" "$TARGET" 2>/dev/null; then
  echo "ENF-003: already applied to $TARGET -- skipping."
  exit 0
fi

# Verify ENF-001 was applied first
if ! grep -q "ENF-001: DRD lockout gate" "$TARGET"; then
  echo "ERROR: ENF-001 must be applied before ENF-003." >&2
  echo "  Run: bash _staging/symphony-enforcement-v2/enf-001-run-task-drd-gate/apply.sh" >&2
  exit 1
fi

python3 - "$TARGET" "$MARKER_GATE" "$MARKER_FAILURE" "$MARKER_SUCCESS" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker_gate    = sys.argv[2]
marker_failure = sys.argv[3]
marker_success = sys.argv[4]

text = target.read_text(encoding="utf-8")

# ── INSERTION 1: evidence ack gate at startup ─────────────────────────────────
# Insert after the end of the ENF-001 DRD gate block, before pack readiness.
# Anchor: the line that starts the pack readiness gate echo.
anchor_gate = 'echo "==> Pack readiness gate"'
if anchor_gate not in text:
    print(f"ERROR: startup anchor not found: {repr(anchor_gate)}", file=sys.stderr)
    sys.exit(1)

gate_block = f"""
# {marker_gate} -- startup checks
# Runs after DRD gate (ENF-001) and before pack readiness.
_enf003_ack_dir="${{ROOT}}/.toolchain/evidence_ack"
_enf003_required="$_enf003_ack_dir/${{TASK_ID}}.required"
_enf003_retries_file="$_enf003_ack_dir/${{TASK_ID}}.retries"
mkdir -p "$_enf003_ack_dir"

# Retry counter: read current count; hard-block at >= 3
_enf003_retry_count=0
if [[ -f "$_enf003_retries_file" ]]; then
  _enf003_retry_count="$(cat "$_enf003_retries_file" | tr -d '[:space:]')"
  _enf003_retry_count="${{_enf003_retry_count:-0}}"
fi
if (( _enf003_retry_count >= 3 )); then
  echo "" >&2
  echo "==> HARD BLOCK: task ${{TASK_ID}} has failed $_enf003_retry_count times." >&2
  echo "   Three consecutive failures require human review before continuing." >&2
  echo "" >&2
  echo "   To reset after reviewing artifacts:" >&2
  echo "     bash scripts/audit/reset_evidence_gate.sh ${{TASK_ID}}" >&2
  exit 50
fi

# Evidence ack gate: if .required exists, check for a valid .ack file
if [[ -f "$_enf003_required" ]]; then
  _enf003_ack_valid=0
  for _ack_file in "$_enf003_ack_dir/${{TASK_ID}}.ack.attempt_"*; do
    [[ -f "$_ack_file" ]] || continue
    _ack_check="$(python3 - "$_ack_file" "${{TASK_ID}}" <<'PYACK'
import sys, yaml
ack_path = sys.argv[1]
expected_task = sys.argv[2]
try:
    data = yaml.safe_load(open(ack_path, encoding="utf-8")) or {{}}
except Exception as e:
    print(f"INVALID: cannot parse ack file: {{e}}")
    sys.exit(0)
task_id = str(data.get("task_id", "")).strip()
ev_read = data.get("evidence_read", False)
root_cause = str(data.get("root_cause", "")).strip()
ack_at = str(data.get("acknowledged_at", "")).strip()
if task_id != expected_task:
    print(f"INVALID: task_id mismatch: got {{task_id}}, expected {{expected_task}}")
elif not ev_read:
    print("INVALID: evidence_read must be true")
elif not root_cause or root_cause.lower() in ("pending", ""):
    print("INVALID: root_cause must be a specific diagnosis, not 'pending' or empty")
elif not ack_at:
    print("INVALID: acknowledged_at must be an ISO timestamp")
else:
    print("VALID")
PYACK
)"
    if [[ "$_ack_check" == "VALID" ]]; then
      _enf003_ack_valid=1
      break
    fi
  done

  if [[ "$_enf003_ack_valid" -eq 0 ]]; then
    _enf003_ack_n=$(( _enf003_retry_count ))
    _enf003_ack_path="$_enf003_ack_dir/${{TASK_ID}}.ack.attempt_${{_enf003_ack_n}}"
    echo "" >&2
    echo "==> EVIDENCE ACK REQUIRED for task ${{TASK_ID}}" >&2
    echo "   A previous run failed. You must acknowledge reading the failure" >&2
    echo "   artifacts before this task can be retried." >&2
    echo "" >&2
    echo "   Read the failure artifacts at:" >&2
    echo "     tmp/task_runs/${{TASK_ID}}/" >&2
    echo "" >&2
    echo "   Then create this file: $_enf003_ack_path" >&2
    echo "   With contents:" >&2
    echo "     task_id: ${{TASK_ID}}" >&2
    echo "     evidence_read: true" >&2
    echo "     root_cause: <your specific diagnosis here>" >&2
    echo "     acknowledged_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >&2
    echo "" >&2
    echo "   root_cause must not be 'pending' or empty." >&2
    exit 51
  fi
fi
# end {marker_gate}

"""
text = text.replace(anchor_gate, gate_block + anchor_gate, 1)

# ── INSERTION 2: retry counter increment in the failure block ─────────────────
# Correct placement: increment AFTER a failure is detected, not on ack pass.
# Anchor: the line that writes the rejection context file.
anchor_failure = 'REJECTION_CTX="$ROOT/.agent/rejection_context.md"'
if anchor_failure not in text:
    print(f"ERROR: failure anchor not found: {repr(anchor_failure)}", file=sys.stderr)
    sys.exit(1)

failure_block = f"""  # {marker_failure}
  # Increment AFTER failure is confirmed, not on ack check.
  # This ensures the counter tracks actual failures, not retry attempts.
  _enf003_new_count=$(( _enf003_retry_count + 1 ))
  echo "$_enf003_new_count" > "$_enf003_retries_file"
  # Write .required to signal that ack is needed before next run
  touch "$_enf003_required"
  echo "Evidence ack required for next run. Retry count: $_enf003_new_count" >&2
  # end {marker_failure}

  """

text = text.replace(
    "  " + anchor_failure,
    failure_block + "  " + anchor_failure,
    1
)

# ── INSERTION 3: cleanup on success ──────────────────────────────────────────
# After evidence freshness check passes, clean up .required and .retries.
# Keep .ack.attempt_* files for audit trail.
# Anchor: the final success echo line.
anchor_success = 'echo "==> Task runner complete: $TASK_ID"'
if anchor_success not in text:
    print(f"ERROR: success anchor not found: {repr(anchor_success)}", file=sys.stderr)
    sys.exit(1)

success_block = f"""# {marker_success}
# Remove transient state files on clean run. Keep .ack.attempt_* for audit.
if [[ -f "$_enf003_required" ]]; then
  rm "$_enf003_required"
fi
if [[ -f "$_enf003_retries_file" ]]; then
  rm "$_enf003_retries_file"
fi
# end {marker_success}

"""
text = text.replace(anchor_success, success_block + anchor_success, 1)

tmp = target.with_suffix(".tmp")
tmp.write_text(text, encoding="utf-8")
tmp.replace(target)
print(f"ENF-003: evidence ack gate applied to {target}")
PY

echo "ENF-003: apply_patch complete. Verify with:"
echo "  grep 'ENF-003' scripts/agent/run_task.sh | head -5"

#!/usr/bin/env bash
# enf-001-run-task-drd-gate/apply.sh
# Applies the ENF-001 DRD lockout gate to scripts/agent/run_task.sh.
# Idempotent: skips if the gate is already present.
# Run from repo root: bash _staging/symphony-enforcement-v2/enf-001-run-task-drd-gate/apply.sh
set -euo pipefail

TARGET="scripts/agent/run_task.sh"
MARKER="ENF-001: DRD lockout gate"

if grep -q "$MARKER" "$TARGET" 2>/dev/null; then
  echo "ENF-001: already applied to $TARGET -- skipping."
  exit 0
fi

# The gate must be inserted immediately after TASK_ID validation and before
# anything else -- meta parse, OUTDIR creation, bootstrap, pack readiness.
# The anchor is the line that exports TASK_ID, which is always present and unique.

ANCHOR='export TASK_ID'

if ! grep -q "^$ANCHOR" "$TARGET"; then
  echo "ERROR: anchor line not found in $TARGET: '$ANCHOR'" >&2
  echo "  The file may have changed. Review and apply manually." >&2
  exit 1
fi

# Use Python for the insertion so there are no sed quoting issues with
# multi-line blocks and no risk of locale-dependent behaviour.
python3 - "$TARGET" "$ANCHOR" "$MARKER" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
anchor = sys.argv[2]
marker = sys.argv[3]

original = target.read_text(encoding="utf-8")
lines = original.splitlines(keepends=True)

insert_after = None
for i, line in enumerate(lines):
    if line.strip() == anchor:
        insert_after = i
        break

if insert_after is None:
    print(f"ERROR: anchor '{anchor}' not found", file=sys.stderr)
    sys.exit(1)

gate_block = f"""
# {marker}
# Inserted by _staging/symphony-enforcement-v2/enf-001-run-task-drd-gate/apply.sh
# If a DRD lockout is active, block run_task.sh immediately -- before meta parse,
# OUTDIR creation, bootstrap, or any other work. Exit 99 matches pre_ci.sh
# so orchestrators can handle both with the same exit-code check.
_enf001_drd_lockout_file="${{ROOT}}/.toolchain/pre_ci_debug/drd_lockout.env"
if [[ -f "$_enf001_drd_lockout_file" ]]; then
  # shellcheck disable=SC1090
  source "$_enf001_drd_lockout_file"
  echo "" >&2
  echo "==> DRD LOCKOUT ACTIVE -- run_task.sh is blocked." >&2
  echo "" >&2
  echo "  Task             : ${{TASK_ID}}" >&2
  echo "  Failure signature: ${{DRD_LOCKED_SIGNATURE:-unknown}}" >&2
  echo "  Failure gate     : ${{DRD_LOCKED_GATE_ID:-unknown}}" >&2
  echo "  Nonconvergence   : ${{DRD_LOCKED_COUNT:-?}} consecutive failures" >&2
  echo "  Locked at        : ${{DRD_LOCKED_AT:-unknown}}" >&2
  echo "" >&2
  echo "  You cannot run any task until the DRD lockout is cleared." >&2
  echo "" >&2
  echo "  REQUIRED STEPS (in order):" >&2
  echo "  1. Create the remediation casefile:" >&2
  echo "     ${{DRD_SCAFFOLD_CMD:-scripts/audit/new_remediation_casefile.sh ...}}" >&2
  echo "  2. Document root cause in the generated PLAN.md" >&2
  echo "  3. Verify the casefile and clear the lockout:" >&2
  echo "     bash scripts/audit/verify_drd_casefile.sh --clear" >&2
  echo "" >&2
  echo "  See: docs/troubleshooting/ for the playbook for this signature." >&2
  exit 99
fi
# end {marker}
"""

lines.insert(insert_after + 1, gate_block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"ENF-001: gate inserted into {target} after line {insert_after + 1}")
PY

echo "ENF-001: apply complete. Verify with:"
echo "  grep 'ENF-001' scripts/agent/run_task.sh"

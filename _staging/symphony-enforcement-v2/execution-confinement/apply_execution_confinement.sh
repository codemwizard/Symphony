#!/usr/bin/env bash
# =============================================================================
# apply_execution_confinement.sh
# Symphony -- Execution Confinement Package
#
# Implements targeted hardening measures against execution bypass:
#   1. PRE_CI_CONTEXT guard on evidence-writing verifier scripts
#   2. Verifier script integrity manifest (sha256 of all guarded scripts)
#   3. Integrity check inside pre_ci.sh before any gate runs
#   4. Bypass env var stripping inside pre_ci.sh
#
# USAGE (from repo root on Ubuntu Server):
#   bash _staging/symphony-enforcement-v2/execution-confinement/apply_execution_confinement.sh
#
# SAFE TO RE-RUN: all operations are idempotent.
# Re-running WILL regenerate the integrity manifest with current hashes.
#
# BUGS FIXED vs original:
#   - Absolute /usr/bin/python3 — no PATH fallback
#   - Missing guarded scripts now cause exit 1 (fail-closed), not WARN+skip
#   - Manifest self-checked with sha256sum --check after write
#   - python3 replaced with /usr/bin/python3 throughout
#   - No anchor-based text.find() — line-level scanning used throughout
# =============================================================================
set -euo pipefail

# Absolute python3 — do not trust PATH.
PYTHON3="/usr/bin/python3"
if [[ ! -x "$PYTHON3" ]]; then
  echo "ERROR: /usr/bin/python3 not found. Install python3 before running." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

MANIFEST_FILE=".toolchain/script_integrity/verifier_hashes.sha256"
MARKER="PRE_CI_CONTEXT_GUARD"

GUARDED_SCRIPTS=(
  scripts/db/verify_gf_sch_001.sh
  scripts/db/verify_gf_sch_002a.sh
  scripts/db/verify_gf_sch_008.sh
  scripts/db/verify_gf_fnc_001.sh
  scripts/db/verify_gf_fnc_002.sh
  scripts/db/verify_gf_fnc_003.sh
  scripts/db/verify_gf_fnc_004.sh
  scripts/db/verify_gf_fnc_005.sh
  scripts/db/verify_gf_fnc_006.sh
  scripts/audit/verify_agent_conformance.sh
  scripts/audit/verify_remediation_trace.sh
  scripts/audit/verify_remediation_artifact_freshness.sh
  scripts/audit/verify_task_meta_schema.sh
  scripts/audit/verify_task_plans_present.sh
  scripts/audit/verify_tsk_p1_206.sh
  scripts/audit/verify_tsk_p1_207.sh
  scripts/audit/verify_tsk_p1_208.sh
  scripts/audit/verify_tsk_p1_209.sh
  scripts/audit/verify_tsk_p1_210.sh
  scripts/audit/verify_tsk_p1_211.sh
  scripts/audit/verify_tsk_p1_212.sh
  scripts/audit/verify_tsk_p1_213.sh
  scripts/audit/verify_tsk_p1_214.sh
  scripts/audit/verify_tsk_p1_215.sh
  scripts/audit/verify_tsk_p1_216.sh
  scripts/audit/verify_tsk_p1_217.sh
  scripts/audit/verify_tsk_p1_218.sh
  scripts/audit/verify_tsk_p1_219.sh
  scripts/audit/verify_tsk_p1_220.sh
  scripts/audit/verify_tsk_p1_221.sh
  scripts/audit/verify_tsk_p1_247.sh
  scripts/audit/verify_human_governance_review_signoff.sh
  scripts/audit/verify_invproc_06_ci_wiring_closeout.sh
  scripts/audit/sign_evidence.py
  scripts/audit/signed_evidence_enrollment.txt
)

# ---------------------------------------------------------------------------
# STEP 1 -- Insert PRE_CI_CONTEXT guard into each verifier script
#
# BUG FIXED: missing scripts now exit 1 (fail-closed). Previously they were
# silently skipped with a WARN, giving a false sense of security that all
# guards were applied.
# ---------------------------------------------------------------------------
echo "==> Step 1: Inserting PRE_CI_CONTEXT guards into verifier scripts"

insert_count=0
skip_count=0
error_count=0

for script in "${GUARDED_SCRIPTS[@]}"; do
  if [[ ! -f "$script" ]]; then
    echo "  ERROR: $script not found -- all guarded scripts must exist before applying confinement" >&2
    error_count=$((error_count + 1))
    continue
  fi

  if grep -qF "$MARKER" "$script" 2>/dev/null; then
    echo "  SKIP (already guarded): $script"
    skip_count=$((skip_count + 1))
    continue
  fi

  if [[ "$script" != *.sh ]]; then
    echo "  SKIP (guard injection is shell-only, skipping): $script"
    skip_count=$((skip_count + 1))
    continue
  fi

  "$PYTHON3" - "$script" "$MARKER" <<'PY'
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
marker = sys.argv[2]

# Capture original mode to prevent permission drift [ID permission_remediation_work_item_03]
original_mode = script_path.stat().st_mode
lines = script_path.read_text(encoding="utf-8").splitlines(keepends=True)

# Find insertion point: after the first 'set -' line.
# Fall back to after shebang if no set line exists.
insert_after = 1
for i, line in enumerate(lines):
    if line.strip().startswith("set -"):
        insert_after = i + 1
        break

# Build guard using plain string concatenation — no f-string with bash braces
# that could be consumed by Python's formatter.
guard = (
    "\n"
    "# --- " + marker + " ---\n"
    "# This script writes evidence and must run via pre_ci.sh or run_task.sh.\n"
    "# Direct execution bypasses the enforcement harness and is blocked.\n"
    "# Debugging override: PRE_CI_CONTEXT=1 bash <script>\n"
    'if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then\n'
    '  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2\n'
    '  echo "  Direct execution blocked to protect evidence integrity." >&2\n'
    '  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2\n'
    "  mkdir -p .toolchain/audit\n"
    '  printf \'%s rogue_execution attempted: %s\\n\' \\\n'
    '    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \\\n'
    "    >> .toolchain/audit/rogue_execution.log\n"
    "  return 1 2>/dev/null || exit 1\n"
    "fi\n"
    "# --- end " + marker + " ---\n"
    "\n"
)

lines.insert(insert_after, guard)
tmp = script_path.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(script_path)
script_path.chmod(original_mode)
print(f"  GUARDED: {script_path}")
PY

  insert_count=$((insert_count + 1))
done

if [[ "$error_count" -gt 0 ]]; then
  echo "  ERROR: $error_count guarded script(s) were missing. Fix before applying confinement." >&2
  exit 1
fi

echo "  Inserted: $insert_count  |  Already guarded: $skip_count"

# ---------------------------------------------------------------------------
# STEP 2 -- Patch pre_ci.sh: PRE_CI_CONTEXT export, run ID, bypass var strip
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 2: Patching pre_ci.sh with context export and run ID"

PRE_CI="scripts/dev/pre_ci.sh"
PRECI_CONTEXT_MARKER="PRE_CI_CONTEXT_EXPORT"

if grep -qF "$PRECI_CONTEXT_MARKER" "$PRE_CI" 2>/dev/null; then
  echo "  SKIP: context export block already present in $PRE_CI"
else
  "$PYTHON3" - "$PRE_CI" "$PRECI_CONTEXT_MARKER" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker = sys.argv[2]

lines = target.read_text(encoding="utf-8").splitlines(keepends=True)

anchor = "pre_ci_check_drd_lockout"
insert_idx = None
for i, line in enumerate(lines):
    if line.strip() == anchor:
        insert_idx = i
        break

if insert_idx is None:
    print(f"ERROR: anchor '{anchor}' not found in {target}", file=sys.stderr)
    sys.exit(1)

block = (
    "\n"
    "# --- " + marker + " ---\n"
    "# Export execution context so guarded verifiers know they run inside the harness.\n"
    "export PRE_CI_CONTEXT=1\n"
    "\n"
    "# Unique run ID. Evidence files embed this; pre-generated outputs won't match.\n"
    'PRE_CI_RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$$"\n'
    "export PRE_CI_RUN_ID\n"
    "\n"
    "# Strip known bypass variables. Presence indicates an exploit attempt.\n"
    "unset SKIP_VALIDATION SKIP_GATES CI_BYPASS DEBUG_OVERRIDE FORCE_PASS 2>/dev/null || true\n"
    "# --- end " + marker + " ---\n"
)

lines.insert(insert_idx + 1, block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"  PATCHED: {target}")
PY
fi

# ---------------------------------------------------------------------------
# STEP 3 -- Build the verifier script integrity manifest
#
# BUG FIXED: manifest is self-verified with sha256sum --check after write
# to catch any filesystem write errors.
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 3: Building verifier script integrity manifest"

mkdir -p "$(dirname "$MANIFEST_FILE")"
chmod 644 "$MANIFEST_FILE" 2>/dev/null || true

{
  echo "# Symphony verifier script integrity manifest"
  echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Regenerate: bash _staging/symphony-enforcement-v2/execution-confinement/apply_execution_confinement.sh"
  echo "#"
  for script in "${GUARDED_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
      sha256sum "$script"
    fi
  done
} > "$MANIFEST_FILE"

# Self-check: verify the manifest is readable and hashes are valid right now.
if ! sha256sum --check "$MANIFEST_FILE" --quiet 2>/dev/null; then
  echo "  ERROR: manifest self-check failed immediately after write." >&2
  echo "  A script may have been modified concurrently, or the filesystem is unreliable." >&2
  exit 1
fi

chmod 444 "$MANIFEST_FILE"

entry_count="$(grep -c '^[0-9a-f]' "$MANIFEST_FILE" 2>/dev/null || echo 0)"
echo "  Manifest written and self-verified (read-only): $MANIFEST_FILE ($entry_count entries)"

# ---------------------------------------------------------------------------
# STEP 4 -- Insert integrity verification block into pre_ci.sh
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 4: Inserting integrity check into pre_ci.sh"

INTEGRITY_MARKER="PRE_CI_INTEGRITY_CHECK"

if grep -qF "$INTEGRITY_MARKER" "$PRE_CI" 2>/dev/null; then
  echo "  SKIP: integrity check already present in $PRE_CI"
else
  "$PYTHON3" - "$PRE_CI" "$INTEGRITY_MARKER" "$MANIFEST_FILE" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker = sys.argv[2]
manifest_path = sys.argv[3]

lines = target.read_text(encoding="utf-8").splitlines(keepends=True)

# Locate the anchor by scanning lines — avoids text.find() partial-match bugs.
anchor_fragment = "end PRE_CI_CONTEXT_EXPORT"
insert_idx = None
for i, line in enumerate(lines):
    if anchor_fragment in line:
        insert_idx = i
        break

if insert_idx is None:
    print(
        f"ERROR: anchor containing '{anchor_fragment}' not found in {target}\n"
        "  Was Step 2 applied successfully?",
        file=sys.stderr,
    )
    sys.exit(1)

block = (
    "\n"
    "# --- " + marker + " ---\n"
    "# Verify integrity of guarded verifier scripts before any gate runs.\n"
    "# Hard-fails if manifest is missing or any hash mismatches.\n"
    '_ic_manifest="' + manifest_path + '"\n'
    'if [[ ! -f "$_ic_manifest" ]]; then\n'
    '  echo "ERROR: integrity manifest not found at $_ic_manifest" >&2\n'
    '  echo "  Run apply_execution_confinement.sh to generate it." >&2\n'
    "  exit 1\n"
    "fi\n"
    "if ! sha256sum --check \"$_ic_manifest\" --quiet 2>/dev/null; then\n"
    '  echo "INTEGRITY FAIL: one or more guarded scripts have been modified." >&2\n'
    '  echo "  Run sha256sum --check $_ic_manifest to identify which files changed." >&2\n'
    '  echo "  After reviewing, regenerate: bash _staging/symphony-enforcement-v2/execution-confinement/apply_execution_confinement.sh" >&2\n'
    "  exit 1\n"
    "fi\n"
    '_ic_count="$(grep -c \'^[0-9a-f]\' "$_ic_manifest" 2>/dev/null || echo 0)"\n'
    'echo "==> Script integrity OK ($_ic_count guarded scripts verified)"\n'
    "unset _ic_manifest _ic_count\n"
    "# --- end " + marker + " ---\n"
)

lines.insert(insert_idx + 1, block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"  INSERTED: integrity check into {target}")
PY
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "====================================================="
echo " Execution confinement applied successfully."
echo "====================================================="
echo ""
echo "What was done:"
echo "  1. PRE_CI_CONTEXT guard inserted into ${#GUARDED_SCRIPTS[@]} verifier scripts"
echo "     (direct exits 1; sourced returns 1 -- both blocked)"
echo "  2. Rogue attempts logged to .toolchain/audit/rogue_execution.log"
echo "  3. pre_ci.sh exports PRE_CI_CONTEXT=1 and PRE_CI_RUN_ID before gates"
echo "  4. Integrity manifest written, self-verified, locked 444: $MANIFEST_FILE"
echo "  5. pre_ci.sh verifies all guarded script hashes before any gate runs"
echo ""
echo "Maintenance:"
echo "  After any legitimate change to a guarded script, re-run this script."
echo "  Without regeneration, pre_ci.sh will block on the integrity check."

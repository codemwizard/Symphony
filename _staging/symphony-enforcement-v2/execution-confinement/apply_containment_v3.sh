#!/usr/bin/env bash
# =============================================================================
# apply_containment_v3.sh
# Symphony -- Containment Layer v3 (Environment + Evidence + AST Lint)
#
# Applies changes to the live repository:
#   1. Copies strip_bypass_env_vars.sh  → scripts/audit/
#   2. Copies sign_evidence.py          → scripts/audit/
#   3. Copies lint_verifier_ast.py      → scripts/audit/
#   4. Patches pre_ci.sh to:
#        a. source strip_bypass_env_vars.sh immediately after DRD lockout
#        b. call lint_verifier_ast.py alongside the bash posture lint
#        c. call sign_evidence.py --verify before accepting phase1 evidence
#
# SAFE TO RE-RUN: all patches are idempotent.
#
# USAGE (from repo root):
#   bash _staging/symphony-enforcement-v2/execution-confinement/apply_containment_v3.sh
#
# BUGS FIXED vs original:
#   - mkdir -p on AUDIT_DIR before cp (fresh-repo safety)
#   - All security tool checks are mandatory exit 1, never optional
#   - Absolute /usr/bin/python3 path — no PATH fallback
#   - Removed mixed f-string + .replace() templating in Step 4c (was a no-op)
#   - Anchor matching now uses line-level scan not text.find() to avoid
#     matching partial or duplicate strings
#   - Post-copy sha256 self-check on each installed file
# =============================================================================
set -euo pipefail

# Absolute python3 path — do not allow PATH hijacking.
PYTHON3="/usr/bin/python3"
if [[ ! -x "$PYTHON3" ]]; then
  echo "ERROR: /usr/bin/python3 not found. Install python3 before running this script." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

STAGING="$ROOT/_staging/symphony-enforcement-v2/execution-confinement"
AUDIT_DIR="$ROOT/scripts/audit"
PRE_CI="$ROOT/scripts/dev/pre_ci.sh"

echo "==> Containment v3: applying environment, evidence signing, and AST lint patches"

# ---------------------------------------------------------------------------
# Helper: install a file and verify the copy hash matches the source
# ---------------------------------------------------------------------------
install_file() {
  local src="$1"
  local dst="$2"
  local mode="${3:-755}"

  if [[ ! -f "$src" ]]; then
    echo "  ERROR: source file not found: $src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  chmod "$mode" "$dst"

  # Verify the copy is bit-for-bit identical to the source.
  src_hash="$(sha256sum "$src" | awk '{print $1}')"
  dst_hash="$(sha256sum "$dst" | awk '{print $1}')"
  if [[ "$src_hash" != "$dst_hash" ]]; then
    echo "  ERROR: copy verification failed for $dst (hash mismatch)" >&2
    echo "    src: $src_hash" >&2
    echo "    dst: $dst_hash" >&2
    exit 1
  fi

  echo "  INSTALLED (verified): $dst"
}

# ---------------------------------------------------------------------------
# STEP 1 -- Install strip_bypass_env_vars.sh
# ---------------------------------------------------------------------------
echo ""
echo "  Step 1: installing strip_bypass_env_vars.sh"
install_file "$STAGING/strip_bypass_env_vars.sh" "$AUDIT_DIR/strip_bypass_env_vars.sh" 755

# ---------------------------------------------------------------------------
# STEP 2 -- Install sign_evidence.py
# ---------------------------------------------------------------------------
echo ""
echo "  Step 2: installing sign_evidence.py"
install_file "$STAGING/sign_evidence.py" "$AUDIT_DIR/sign_evidence.py" 755

# ---------------------------------------------------------------------------
# STEP 3 -- Install lint_verifier_ast.py
# ---------------------------------------------------------------------------
echo ""
echo "  Step 3: installing lint_verifier_ast.py"
install_file "$STAGING/lint_verifier_ast.py" "$AUDIT_DIR/lint_verifier_ast.py" 755

# ---------------------------------------------------------------------------
# STEP 4a -- Patch pre_ci.sh: source strip_bypass_env_vars.sh after DRD lockout
# ---------------------------------------------------------------------------
echo ""
echo "  Step 4a: patching pre_ci.sh -- bypass env var strip"

BYPASS_MARKER="STRIP_BYPASS_ENV_VARS_SOURCED"

if grep -qF "$BYPASS_MARKER" "$PRE_CI" 2>/dev/null; then
  echo "  SKIP: bypass strip already present in $PRE_CI"
else
  "$PYTHON3" - "$PRE_CI" "$BYPASS_MARKER" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker = sys.argv[2]

lines = target.read_text(encoding="utf-8").splitlines(keepends=True)

# Find anchor by scanning lines exactly — avoids text.find() matching substrings.
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
    f"\n"
    f"# --- {marker} ---\n"
    f"# Strip all known bypass environment variables unconditionally.\n"
    f"# An agent that sets SKIP_CI_DB_PARITY_PROBE=1 or similar is detected,\n"
    f"# logged, and blocked here before any gate runs.\n"
    f"# Sourced (not executed) so unset affects this shell.\n"
    f"[[ -f scripts/audit/strip_bypass_env_vars.sh ]] || {{\n"
    f"  echo \"FATAL: scripts/audit/strip_bypass_env_vars.sh missing -- env hygiene cannot be enforced\" >&2\n"
    f"  exit 1\n"
    f"}}\n"
    f"source scripts/audit/strip_bypass_env_vars.sh\n"
    f"# --- end {marker} ---\n"
)

lines.insert(insert_idx + 1, block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"  PATCHED: {target}")
PY
fi

# ---------------------------------------------------------------------------
# STEP 4b -- Patch pre_ci.sh: add AST lint gate after bash posture lint
# ---------------------------------------------------------------------------
echo ""
echo "  Step 4b: patching pre_ci.sh -- AST lint gate"

AST_MARKER="AST_LINT_GATE"

if grep -qF "$AST_MARKER" "$PRE_CI" 2>/dev/null; then
  echo "  SKIP: AST lint gate already present in $PRE_CI"
else
  "$PYTHON3" - "$PRE_CI" "$AST_MARKER" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker = sys.argv[2]

lines = target.read_text(encoding="utf-8").splitlines(keepends=True)

# Scan for the anchor line exactly to avoid partial-string matches.
anchor_fragment = "GF verifier execution posture lint (anti-deception gate)"
insert_idx = None
for i, line in enumerate(lines):
    if anchor_fragment in line:
        insert_idx = i
        break

if insert_idx is None:
    print(
        f"ERROR: anchor containing '{anchor_fragment}' not found in {target}\n"
        "  Was the bash posture lint applied first?",
        file=sys.stderr,
    )
    sys.exit(1)

block = (
    f"\n"
    f"# --- {marker} ---\n"
    f"# AST-level structural lint: verifies psql appears as a real command\n"
    f"# invocation, not a comment or dead string. Mandatory — missing tool = exit 1.\n"
    f"echo \"==> GF verifier AST lint (structural command invocation check)\"\n"
    f"[[ -f scripts/audit/lint_verifier_ast.py ]] || {{\n"
    f"  echo \"FATAL: scripts/audit/lint_verifier_ast.py not found\" >&2\n"
    f"  exit 1\n"
    f"}}\n"
    f"/usr/bin/python3 scripts/audit/lint_verifier_ast.py \\\\\n"
    f"  scripts/db/verify_gf_w1_fnc_001.sh \\\\\n"
    f"  scripts/db/verify_gf_w1_fnc_002.sh \\\\\n"
    f"  scripts/db/verify_gf_w1_fnc_003.sh \\\\\n"
    f"  scripts/db/verify_gf_w1_fnc_004.sh \\\\\n"
    f"  scripts/db/verify_gf_w1_fnc_005.sh \\\\\n"
    f"  scripts/db/verify_gf_w1_fnc_006.sh\n"
    f"# --- end {marker} ---\n"
)

# Insert after the anchor line (not inside it).
lines.insert(insert_idx + 1, block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"  PATCHED: {target}")
PY
fi

# ---------------------------------------------------------------------------
# STEP 4c -- Patch pre_ci.sh: evidence signature verification
#
# BUG FIXED: original used a mixed f-string + .replace("{EV_SIG_MARKER}", marker)
# The f-string consumed the braces first, making .replace() a no-op. The marker
# variable was never interpolated into the block. Fixed by using plain string
# concatenation with explicit marker substitution before writing.
# ---------------------------------------------------------------------------
echo ""
echo "  Step 4c: patching pre_ci.sh -- evidence signature verification"

EV_SIG_MARKER="EVIDENCE_SIGNATURE_VERIFY"

if grep -qF "$EV_SIG_MARKER" "$PRE_CI" 2>/dev/null; then
  echo "  SKIP: evidence signature verification already present in $PRE_CI"
else
  "$PYTHON3" - "$PRE_CI" "$EV_SIG_MARKER" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker = sys.argv[2]

lines = target.read_text(encoding="utf-8").splitlines(keepends=True)

# Scan line-by-line for the anchor to avoid partial matches.
anchor_fragment = "Green Finance Schema + Function Verification"
insert_idx = None
for i, line in enumerate(lines):
    if anchor_fragment in line:
        insert_idx = i
        break

if insert_idx is None:
    print(
        f"ERROR: anchor containing '{anchor_fragment}' not found in {target}",
        file=sys.stderr,
    )
    sys.exit(1)

# Build the block using plain string operations — no f-string with bash braces,
# no mixed .replace() templating. Marker is substituted explicitly.
block = (
    "# --- " + marker + " ---\n"
    "# Verify phase1 evidence was signed by sign_evidence.py in THIS run.\n"
    "# Pre-generated, hand-typed, or tampered JSON files are rejected.\n"
    "echo \"==> Phase-1 evidence signature integrity check\"\n"
    "[[ -f scripts/audit/sign_evidence.py ]] || {\n"
    "  echo \"FATAL: scripts/audit/sign_evidence.py not found\" >&2\n"
    "  exit 1\n"
    "}\n"
    "if [[ -d evidence/phase1 ]] && compgen -G \"evidence/phase1/*.json\" > /dev/null 2>&1; then\n"
    "  /usr/bin/python3 scripts/audit/sign_evidence.py --verify --dir evidence/phase1\n"
    "else\n"
    "  echo \"  INFO: no phase1 evidence files yet -- skipping signature check\"\n"
    "fi\n"
    "# --- end " + marker + " ---\n"
    "\n"
)

# Insert the block BEFORE the anchor line.
lines.insert(insert_idx, block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"  PATCHED: {target}")
PY
fi

# ---------------------------------------------------------------------------
# Post-patch: record sha256 of the patched pre_ci.sh for later verification
# ---------------------------------------------------------------------------
PRE_CI_HASH_FILE="$ROOT/.toolchain/script_integrity/pre_ci_patched.sha256"
mkdir -p "$(dirname "$PRE_CI_HASH_FILE")"
sha256sum "$PRE_CI" > "$PRE_CI_HASH_FILE"
echo ""
echo "  Post-patch hash recorded: $PRE_CI_HASH_FILE"
echo "  $(cat "$PRE_CI_HASH_FILE")"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "====================================================="
echo " Containment v3 applied."
echo "====================================================="
echo ""
echo "What was installed (hash-verified):"
echo "  scripts/audit/strip_bypass_env_vars.sh"
echo "  scripts/audit/sign_evidence.py"
echo "  scripts/audit/lint_verifier_ast.py"
echo ""
echo "What was patched in scripts/dev/pre_ci.sh:"
echo "  1. Bypass env vars stripped immediately after DRD lockout (mandatory)"
echo "  2. AST lint gate added (mandatory, uses /usr/bin/python3)"
echo "  3. Evidence signature check added before GF verifiers (mandatory)"
echo ""
echo "Next step:"
echo "  Apply UBUNTU_ACCESS_HARDENING.md to prevent agents editing installed scripts."

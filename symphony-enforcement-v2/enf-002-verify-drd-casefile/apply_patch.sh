#!/usr/bin/env bash
# enf-002-verify-drd-casefile/apply_patch.sh
# Patches the lockout message in pre_ci_debug_contract.sh to reference
# verify_drd_casefile.sh --clear instead of raw rm.
# Idempotent: skips if already patched.
# Run from repo root: bash _staging/symphony-enforcement-v2/enf-002-verify-drd-casefile/apply_patch.sh
set -euo pipefail

TARGET="scripts/audit/pre_ci_debug_contract.sh"
MARKER="verify_drd_casefile.sh --clear"

if grep -q "$MARKER" "$TARGET" 2>/dev/null; then
  echo "ENF-002: lockout message patch already applied to $TARGET -- skipping."
  exit 0
fi

# The patch replaces the raw rm instruction in the lockout message with the
# controlled verify_drd_casefile.sh --clear instruction.
# The anchor is the echo line that prints the raw rm command.

python3 - "$TARGET" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
text = target.read_text(encoding="utf-8")

old = '  echo "  3. Remove the lockout file:" >&2\n  echo "     rm $PRE_CI_DRD_LOCKOUT_FILE" >&2'
new = '  echo "  3. Verify the casefile and clear the lockout:" >&2\n  echo "     bash scripts/audit/verify_drd_casefile.sh --clear" >&2'

if old not in text:
    print(f"ERROR: anchor text not found in {target}.", file=sys.stderr)
    print("  The file may have changed. Review and apply manually.", file=sys.stderr)
    print("  Looking for:", file=sys.stderr)
    print(repr(old), file=sys.stderr)
    sys.exit(1)

patched = text.replace(old, new, 1)
tmp = target.with_suffix(".tmp")
tmp.write_text(patched, encoding="utf-8")
tmp.replace(target)
print(f"ENF-002: lockout message patched in {target}")
PY

echo "ENF-002: apply_patch complete. Verify with:"
echo "  grep 'verify_drd_casefile' scripts/audit/pre_ci_debug_contract.sh"

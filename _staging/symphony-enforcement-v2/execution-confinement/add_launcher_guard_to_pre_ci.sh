#!/usr/bin/env bash
# =============================================================================
# add_launcher_guard_to_pre_ci.sh
# Symphony -- Adds the trusted_launcher guard to pre_ci.sh
#
# Adds two things at the top of pre_ci.sh (immediately after set -Eeuo pipefail):
#
#   1. A check that TSK_TRUSTED_LAUNCH is set and the corresponding token file
#      exists on disk. Rejects direct invocation by agents.
#
#   2. A post-execution integrity re-check that rehashes all guarded scripts
#      AFTER the run completes, detecting any swap attacks that occurred during
#      execution.
#
# SAFE TO RE-RUN: idempotent.
#
# BUGS FIXED:
#   - bare `python3` replaced with /usr/bin/python3 (PATH hijack prevention)
#   - post-exec anchor changed from text.find() to line-level scan
#     (text.find() silently patches wrong location if anchor text appears
#      more than once or with different surrounding whitespace)
#
# USAGE (from repo root):
#   bash _staging/symphony-enforcement-v2/execution-confinement/add_launcher_guard_to_pre_ci.sh
# =============================================================================
set -euo pipefail

# Absolute python3 — do not trust PATH.
PYTHON3="/usr/bin/python3"
if [[ ! -x "$PYTHON3" ]]; then
  echo "ERROR: /usr/bin/python3 not found." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

PRE_CI="$ROOT/scripts/dev/pre_ci.sh"
MANIFEST="$ROOT/.toolchain/trust_manifest.sha256"

LAUNCH_GUARD_MARKER="TSK_TRUSTED_LAUNCH_GUARD"
POST_EXEC_MARKER="TSK_POST_EXEC_INTEGRITY"

# ---------------------------------------------------------------------------
# PART 1 -- Insert the launch guard at the top of pre_ci.sh
# ---------------------------------------------------------------------------
echo "==> Adding trusted launcher guard to pre_ci.sh"

if grep -qF "$LAUNCH_GUARD_MARKER" "$PRE_CI" 2>/dev/null; then
  echo "  SKIP: launch guard already present"
else
  "$PYTHON3" - "$PRE_CI" "$LAUNCH_GUARD_MARKER" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker = sys.argv[2]

lines = target.read_text(encoding="utf-8").splitlines(keepends=True)

# Insert immediately after the first 'set -' line.
insert_after = 1
for i, line in enumerate(lines):
    if line.strip().startswith("set -"):
        insert_after = i + 1
        break

# Build block using plain string concatenation — no f-string consuming bash braces.
block = (
    "\n"
    "# --- " + marker + " ---\n"
    "# Verify this shell was started by trusted_launcher.sh, not invoked directly.\n"
    "# Agents calling pre_ci.sh directly bypass integrity verification,\n"
    "# environment lockdown, and the TOCTOU-safe snapshot the launcher provides.\n"
    'if [[ -z "${TSK_TRUSTED_LAUNCH:-}" ]]; then\n'
    '  echo "FATAL: pre_ci.sh must be executed via trusted_launcher.sh" >&2\n'
    '  echo "  Direct invocation is blocked. Use:" >&2\n'
    '  echo "    symphony_ci   (if installed)" >&2\n'
    '  echo "    bash _staging/symphony-enforcement-v2/execution-confinement/trusted_launcher.sh" >&2\n'
    "  exit 1\n"
    "fi\n"
    "# Verify the one-time token file exists — proves the launcher process created it.\n"
    '# An agent setting TSK_TRUSTED_LAUNCH manually cannot produce a matching token file.\n'
    '_token_file="${TSK_LAUNCH_TOKEN_DIR:-/nonexistent}/${TSK_TRUSTED_LAUNCH}.token"\n'
    'if [[ ! -f "$_token_file" ]]; then\n'
    '  echo "FATAL: launch token file not found: $_token_file" >&2\n'
    '  echo "  TSK_TRUSTED_LAUNCH may have been set manually to bypass this check." >&2\n'
    '  echo "  Only trusted_launcher.sh creates valid token files." >&2\n'
    "  exit 1\n"
    "fi\n"
    "# Consume the token immediately — one-time use only.\n"
    'rm -f "$_token_file"\n'
    "unset _token_file\n"
    "# --- end " + marker + " ---\n"
    "\n"
)

lines.insert(insert_after, block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"  PATCHED: {target}")
PY
fi

# ---------------------------------------------------------------------------
# PART 2 -- Insert post-execution integrity re-check at the end of pre_ci.sh
#
# Verifies file hashes AGAIN after the run completes. When the launcher
# snapshots to tmpdir, this check runs against the snapshot copies —
# proving the snapshot itself was not mutated during the run.
# ---------------------------------------------------------------------------
echo "==> Adding post-execution integrity re-check to pre_ci.sh"

if grep -qF "$POST_EXEC_MARKER" "$PRE_CI" 2>/dev/null; then
  echo "  SKIP: post-execution integrity check already present"
else
  "$PYTHON3" - "$PRE_CI" "$POST_EXEC_MARKER" "$MANIFEST" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
marker = sys.argv[2]
manifest_path = sys.argv[3]

lines = target.read_text(encoding="utf-8").splitlines(keepends=True)

# BUG FIXED: use line-level scan instead of text.find().
# text.find() silently patches the wrong location if the anchor string
# appears more than once or with different surrounding whitespace.
anchor_fragment = "Pre-CI local checks PASSED"
insert_idx = None
for i, line in enumerate(lines):
    if anchor_fragment in line:
        insert_idx = i
        break

if insert_idx is None:
    print(f"ERROR: anchor containing '{anchor_fragment}' not found in {target}", file=sys.stderr)
    sys.exit(1)

block = (
    "\n"
    "# --- " + marker + " ---\n"
    "# Post-execution integrity re-check: re-verify all manifested files have not\n"
    "# been swapped or modified during this run. Catches runtime swap attacks.\n"
    'echo "==> Post-execution integrity check"\n'
    '_post_manifest="' + manifest_path + '"\n'
    'if [[ -f "$_post_manifest" ]]; then\n'
    '  if ! sha256sum --check "$_post_manifest" --quiet 2>/dev/null; then\n'
    '    echo "POST-EXECUTION INTEGRITY FAILURE: files were modified during the run." >&2\n'
    '    echo "  This indicates a runtime swap attack or concurrent modification." >&2\n'
    '    echo "  The run result is UNTRUSTED even though gates passed." >&2\n'
    "    exit 1\n"
    "  fi\n"
    '  echo "  Post-execution integrity: OK"\n'
    "else\n"
    '  echo "WARN: post-execution manifest not found -- skipping re-check" >&2\n'
    "fi\n"
    "# --- end " + marker + " ---\n"
)

# Insert the block BEFORE the anchor line (not after, not via text.find).
lines.insert(insert_idx, block)
tmp = target.with_suffix(".tmp")
tmp.write_text("".join(lines), encoding="utf-8")
tmp.replace(target)
print(f"  PATCHED: {target} (post-execution check added)")
PY
fi

echo ""
echo "====================================================="
echo " Launcher guard and post-execution check applied."
echo "====================================================="
echo ""
echo "  pre_ci.sh now requires TSK_TRUSTED_LAUNCH + token file."
echo "  Direct invocation (without trusted_launcher.sh) is blocked."
echo ""
echo "Next steps:"
echo "  1. Generate signing key pair (once, store private key off-server):"
echo "     openssl genrsa -out trust_private.pem 4096"
echo "     openssl rsa -in trust_private.pem -pubout -out .toolchain/trust_pubkey.pem"
echo ""
echo "  2. Generate and sign the manifest:"
echo "     TRUST_PRIVATE_KEY=./trust_private.pem \\"
echo "       bash _staging/symphony-enforcement-v2/execution-confinement/generate_trust_manifest.sh"
echo ""
echo "  3. Install the launcher as an immutable system binary:"
echo "     sudo cp _staging/symphony-enforcement-v2/execution-confinement/trusted_launcher.sh \\"
echo "             /usr/local/bin/symphony_ci"
echo "     sudo chown root:root /usr/local/bin/symphony_ci"
echo "     sudo chmod 755 /usr/local/bin/symphony_ci"
echo "     sudo chattr +i /usr/local/bin/symphony_ci"
echo ""
echo "  4. Apply UBUNTU_ACCESS_HARDENING.md to prevent agents modifying scripts/audit/ and scripts/dev/"

#!/usr/bin/env bash
# =============================================================================
# generate_trust_manifest.sh
# Symphony -- Trust Manifest Generator
# Version: 2.0 (simplified scope)
#
# Generates and signs the integrity manifest that trusted_launcher.sh (symphony_ci)
# verifies before executing any CI code.
#
# SCOPE CHANGE vs v1
# ------------------
# v1 included 24 specific files. v2 uses a scoped find that covers:
#   - scripts/dev/pre_ci.sh          (the main CI entry point)
#   - scripts/audit/*.sh             (all audit/enforcement scripts)
#   - scripts/audit/*.py             (Python enforcement tools)
#   - scripts/db/verify_*.sh        (all DB verifier scripts)
#
# This is broader than the v1 explicit list (catches new scripts automatically)
# but narrower than the simplified proposal's "find scripts -type f" (excludes
# hundreds of test, bootstrap, and migration scripts that are not attack surfaces).
#
# PREREQUISITES
# -------------
#   openssl genrsa -out ~/trust_private.pem 4096
#   openssl rsa -in ~/trust_private.pem -pubout -out .toolchain/trust_pubkey.pem
#   # Keep private key OFF the server.
#
# USAGE (run as mwiza or ci_harness_owner, from repo root)
# --------------------------------------------------------
#   TRUST_PRIVATE_KEY=/path/to/trust_private.pem \
#     bash _staging/symphony-enforcement-v2/execution-confinement/generate_trust_manifest.sh
#
# RE-RUN WHENEVER: any file in the manifest scope is legitimately changed.
#
# EXIT CODES
#   0  success
#   1  error
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

TOOLCHAIN_DIR="$ROOT/.toolchain"
MANIFEST="$TOOLCHAIN_DIR/trust_manifest.sha256"
SIGNATURE="$TOOLCHAIN_DIR/trust_manifest.sig"
PUBKEY="$TOOLCHAIN_DIR/trust_pubkey.pem"
PRIVATE_KEY="${TRUST_PRIVATE_KEY:-}"

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -n "$PRIVATE_KEY" ]] || die "TRUST_PRIVATE_KEY env var must point to the private key."
[[ -f "$PRIVATE_KEY" ]] || die "Private key not found: $PRIVATE_KEY"
[[ -f "$PUBKEY" ]]      || die "Public key not found: $PUBKEY"

mkdir -p "$TOOLCHAIN_DIR"

echo "==> Generating trust manifest"
echo "    Scope: scripts/dev/pre_ci.sh + scripts/audit/{*.sh,*.py} + scripts/db/verify_*.sh"

{
  echo "# Symphony trust manifest"
  echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Signer: $(id -un)@$(hostname -f 2>/dev/null || hostname)"
  echo "#"

  # The CI entry point
  sha256sum scripts/dev/pre_ci.sh
  echo "  hashed: scripts/dev/pre_ci.sh" >&2

  # All audit enforcement scripts and Python tools
    # All audit enforcement scripts, Python tools, and .env configs
  find scripts/audit \( -name "*.sh" -o -name "*.py" -o -name "*.env" \) -type f | sort | while read -r f; do
    sha256sum "$f"
    echo "  hashed: $f" >&2
  done

  # All supporting libraries (e.g., evidence.sh)
  find scripts/lib -maxdepth 1 -name "*.sh" -type f | sort | while read -r f; do
    sha256sum "$f"
    echo "  hashed: $f" >&2
  done

  # All DB verifier scripts
  find scripts/db -maxdepth 1 -name "verify_*.sh" -type f | sort | while read -r f; do
    sha256sum "$f"
    echo "  hashed: $f" >&2
  done

} > "$MANIFEST"

entry_count="$(grep -c '^[0-9a-f]' "$MANIFEST" || echo 0)"
echo "  Manifest written: $MANIFEST ($entry_count entries)"

echo ""
echo "==> Signing manifest"
openssl dgst -sha256 -sign "$PRIVATE_KEY" -out "$SIGNATURE" "$MANIFEST"
echo "  Signature: $SIGNATURE"

echo ""
echo "==> Self-check"
openssl dgst -sha256 -verify "$PUBKEY" -signature "$SIGNATURE" "$MANIFEST" \
  > /dev/null 2>&1 && echo "  Signature self-check: PASS" || {
    rm -f "$SIGNATURE"
    die "Signature self-check failed — manifest or key mismatch. Signature removed."
  }

# Lock both files to read-only
chmod 444 "$MANIFEST" "$SIGNATURE"

echo ""
echo "====================================================="
echo " Trust manifest generated and signed."
echo "====================================================="
echo "  Manifest ($entry_count files): $MANIFEST"
echo "  Signature:                     $SIGNATURE"
echo ""
echo "  IMPORTANT: Keep the private key OFF this server."
echo "  Anyone with the private key can sign a tampered manifest."
echo ""
echo "  Next: update EXPECTED_PUBKEY_HASH in trusted_launcher.sh"
echo "  and reinstall it with chattr +i."

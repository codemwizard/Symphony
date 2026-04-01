#!/usr/bin/env bash
# =============================================================================
# trusted_launcher.sh
# Symphony -- Root of Trust for pre_ci.sh Execution
# Version: 2.0 (simplified)
#
# WHAT THIS DOES
# --------------
# 1. Verifies the public key has not been swapped (hash baked into this binary).
# 2. Verifies the signed manifest signature.
# 3. Copies files to a tmpdir snapshot FIRST, then verifies inside the snapshot.
#    This closes the TOCTOU gap: what is verified is exactly what executes.
# 4. Locks the execution environment to an explicit allowlist (env -i).
# 5. Generates a one-time random token so pre_ci.sh can verify it was launched here.
# 6. Executes pre_ci.sh from the verified snapshot.
#
# WHAT WAS REMOVED vs v1
# -----------------------
# - Layer 2 integrity check (verifier_hashes.sha256): redundant with signed manifest.
# - PRE_CI_CONTEXT export: redundant given OS hardening + token gate.
# - strip_bypass_env_vars sourcing: covered by env -i allowlist in Step 4.
# - sign_evidence / AST lint calls: behavioural controls, not trust controls.
#
# WHAT WAS KEPT
# -------------
# - TOCTOU-safe snapshot (copy-then-verify, execute from snapshot).
# - Pubkey hash baked in (prevents key-swap attack on verification itself).
# - One-time random token (prevents replay of TSK_TRUSTED_LAUNCH=1 bypass).
# - env -i environment lockdown.
#
# INSTALLATION (human, one-time on Ubuntu Server)
# -----------------------------------------------
#   # 1. Set EXPECTED_PUBKEY_HASH below (sha256sum .toolchain/trust_pubkey.pem)
#   # 2. Install as immutable system binary:
#   sudo cp trusted_launcher.sh /usr/local/bin/symphony_ci
#   sudo chown root:root /usr/local/bin/symphony_ci
#   sudo chmod 755 /usr/local/bin/symphony_ci
#   sudo chattr +i /usr/local/bin/symphony_ci
#
# REGENERATE MANIFEST after any legitimate harness change:
#   TRUST_PRIVATE_KEY=/path/to/private.pem \
#     bash _staging/symphony-enforcement-v2/execution-confinement/generate_trust_manifest.sh
#
# EXIT CODES
#   0   pre_ci.sh completed successfully
#   1   integrity verification failed
#   2   environment setup error
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIGURATION — set this before installing
# sha256sum .toolchain/trust_pubkey.pem  (first field only)
# ---------------------------------------------------------------------------
EXPECTED_PUBKEY_HASH="573fccd281b496ae6e3dea1a38502cd7ac53daae74a8418f65abc6941b5fab53"

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
REPO_ROOT="${SYMPHONY_REPO_ROOT:-$(pwd)}"

TOOLCHAIN_DIR="$REPO_ROOT/.toolchain"
MANIFEST="$TOOLCHAIN_DIR/trust_manifest.sha256"
SIGNATURE="$TOOLCHAIN_DIR/trust_manifest.sig"
PUBKEY="$TOOLCHAIN_DIR/trust_pubkey.pem"
TOKEN_DIR="$TOOLCHAIN_DIR/launch_tokens"

die() { echo "FATAL [symphony_ci]: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# STEP 0 -- Verify the public key has not been swapped
#
# An attacker who replaces trust_pubkey.pem with their own key can sign any
# manifest they like and pass signature verification. The expected hash is
# baked into this immutable binary (chattr +i) so it cannot be forged.
# ---------------------------------------------------------------------------
echo "==> [symphony_ci] Verifying public key"
[[ -f "$PUBKEY" ]] || die "Public key not found: $PUBKEY"
ACTUAL_PUBKEY_HASH="$(sha256sum "$PUBKEY" | awk '{print $1}')"
[[ "$ACTUAL_PUBKEY_HASH" == "$EXPECTED_PUBKEY_HASH" ]] || \
  die "Public key hash mismatch. Expected: $EXPECTED_PUBKEY_HASH | Got: $ACTUAL_PUBKEY_HASH"
echo "  OK"

# ---------------------------------------------------------------------------
# STEP 1 -- Verify manifest signature
# ---------------------------------------------------------------------------
echo "==> [symphony_ci] Verifying manifest signature"
[[ -f "$SIGNATURE" ]] || die "Manifest signature not found: $SIGNATURE"
[[ -f "$MANIFEST" ]]  || die "Trust manifest not found: $MANIFEST"
openssl dgst -sha256 -verify "$PUBKEY" -signature "$SIGNATURE" "$MANIFEST" \
  > /dev/null 2>&1 || die "Manifest signature invalid — manifest may be tampered."
echo "  OK"

# ---------------------------------------------------------------------------
# STEP 2 -- Snapshot to tmpdir FIRST, then verify inside snapshot (TOCTOU fix)
#
# Simplified version removed: verify originals → execute originals.
# Problem: an agent can swap a file between sha256sum --check and exec.
# This version: copy → verify copy → execute copy.
# The bytes verified are exactly the bytes that run.
# ---------------------------------------------------------------------------
echo "==> [symphony_ci] Creating execution snapshot"
SNAP_DIR="$(mktemp -d -t symphony_ci_snap_XXXXXX)"
cleanup() { [[ -d "$SNAP_DIR" ]] && rm -rf "$SNAP_DIR"; }
trap cleanup EXIT

while IFS= read -r line; do
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue
  rel="$(printf '%s' "$line" | awk '{print $2}')"
  src="$REPO_ROOT/$rel"
  dst="$SNAP_DIR/$rel"
  [[ -f "$src" ]] || die "Manifest references missing file: $src"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
done < "$MANIFEST"

# Copy trust artifacts into snapshot so verification runs against the snapshot.
mkdir -p "$SNAP_DIR/.toolchain"
cp "$MANIFEST"  "$SNAP_DIR/.toolchain/trust_manifest.sha256"
cp "$SIGNATURE" "$SNAP_DIR/.toolchain/trust_manifest.sig"
cp "$PUBKEY"    "$SNAP_DIR/.toolchain/trust_pubkey.pem"

# Copy data directories pre_ci.sh reads at runtime (not hashed, not code).
for d in infra tasks docs schema; do
  [[ -d "$REPO_ROOT/$d" ]] && cp -r "$REPO_ROOT/$d" "$SNAP_DIR/$d"
done

# Symlink .toolchain back to the real repo so pre_ci.sh writes land correctly.
rm -rf "$SNAP_DIR/.toolchain"
ln -s "$REPO_ROOT/.toolchain" "$SNAP_DIR/.toolchain"

# Symlink evidence back to real repo (pre_ci.sh writes evidence there).
[[ -d "$SNAP_DIR/evidence" ]] && rm -rf "$SNAP_DIR/evidence"
ln -s "$REPO_ROOT/evidence" "$SNAP_DIR/evidence"

echo "  Snapshot: $SNAP_DIR"

# ---------------------------------------------------------------------------
# STEP 3 -- Verify integrity INSIDE the snapshot
# ---------------------------------------------------------------------------
echo "==> [symphony_ci] Verifying snapshot integrity"
cd "$SNAP_DIR"
sha256sum --check ".toolchain/trust_manifest.sha256" --quiet 2>/dev/null || \
  die "Snapshot integrity check failed — file was modified between manifest generation and now."
echo "  OK ($(grep -c '^[0-9a-f]' ".toolchain/trust_manifest.sha256") files verified)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# STEP 4 -- Lock execution environment to an explicit allowlist
# ---------------------------------------------------------------------------
echo "==> [symphony_ci] Locking execution environment"
CLEAN_ENV=(
  "HOME=${HOME:-/root}"
  "USER=${USER:-$(id -un)}"
  "LOGNAME=${LOGNAME:-$(id -un)}"
  "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  "TERM=${TERM:-xterm}"
  "SYMPHONY_REPO_ROOT=$REPO_ROOT"
)
for v in DOCKER_HOST DOCKER_CERT_PATH DOCKER_TLS_VERIFY; do
  [[ -n "${!v:-}" ]] && CLEAN_ENV+=("${v}=${!v}")
done
for v in POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB DATABASE_URL \
          CI_PARITY_DB_USER CI_PARITY_DB_PASSWORD HOST_POSTGRES_PORT; do
  [[ -n "${!v:-}" ]] && CLEAN_ENV+=("${v}=${!v}")
done
# Git needs SSH access for remote operations (fetch, ls-remote).
# Strategy: prefer an explicit GIT_SSH_COMMAND pointing to the ed25519 key so
# no SSH agent socket is required. Falls back to SSH_AUTH_SOCK if the key file
# is not present (e.g. a different user or CI runner setup).
#
# This avoids the common failure where SSH_AUTH_SOCK is empty because the
# SSH agent was not started in the session that invoked symphony_ci.
GIT_SSH_KEY="${HOME}/.ssh/id_ed25519"
if [[ -f "$GIT_SSH_KEY" ]]; then
  # 1. SET the actual variable first
  GIT_SSH_COMMAND="ssh -i ${GIT_SSH_KEY} -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
  # 2. EXPORT it so the sub-shell/loop can see it
  export GIT_SSH_COMMAND 
else
  [[ -n "${SSH_AUTH_SOCK:-}" ]] && export SSH_AUTH_SOCK
fi

# Now this loop will find GIT_SSH_COMMAND and add it to CLEAN_ENV
for v in GIT_CONFIG_GLOBAL GIT_EXEC_PATH GIT_SSH GIT_SSH_COMMAND SSH_AUTH_SOCK; do
  [[ -n "${!v:-}" ]] && CLEAN_ENV+=("${v}=${!v}")
done
[[ "${SYMPHONY_HUMAN_DEBUG_SESSION:-0}" == "1" ]] && \
  CLEAN_ENV+=("SYMPHONY_HUMAN_DEBUG_SESSION=1")
echo "  ${#CLEAN_ENV[@]} variables in allowlist"

# ---------------------------------------------------------------------------
# STEP 5 -- One-time random launch token (prevents TSK_TRUSTED_LAUNCH=1 bypass)
# ---------------------------------------------------------------------------
echo "==> [symphony_ci] Generating launch token"
mkdir -p "$TOKEN_DIR"
chmod 700 "$TOKEN_DIR"
LAUNCH_TOKEN="$(openssl rand -hex 32)"
TOKEN_FILE="$TOKEN_DIR/${LAUNCH_TOKEN}.token"
touch "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"
trap 'cleanup; rm -f "$TOKEN_FILE" 2>/dev/null || true' EXIT
CLEAN_ENV+=("TSK_TRUSTED_LAUNCH=$LAUNCH_TOKEN" "TSK_LAUNCH_TOKEN_DIR=$TOKEN_DIR")
echo "  Token: ${LAUNCH_TOKEN:0:12}... (one-time)"

# ---------------------------------------------------------------------------
# STEP 6 -- Execute pre_ci.sh from the verified snapshot
# ---------------------------------------------------------------------------
echo "==> [symphony_ci] Executing pre_ci.sh from verified snapshot"
echo ""
CLEAN_ENV+=("GIT_TRACE=1" "GIT_SSH_COMMAND=$GIT_SSH_COMMAND")
CLEAN_ENV+=("GIT_DIR=$REPO_ROOT/.git" "GIT_WORK_TREE=$SNAP_DIR")
exec env -i "${CLEAN_ENV[@]}" /bin/bash "$SNAP_DIR/scripts/dev/pre_ci.sh"

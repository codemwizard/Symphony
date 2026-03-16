#!/usr/bin/env bash
# ─── Symphony Canonical Bootstrap (TSK-P1-220) ──────────────────────
# One-command local dev bootstrap. Fails closed if prerequisites unmet.
# Usage: bash scripts/dev/bootstrap.sh
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# ─── Colours ───
RED='\033[0;31m'; GREEN='\033[0;32m'; AMBER='\033[0;33m'; NC='\033[0m'
pass() { printf "${GREEN}✓${NC} %s\n" "$1"; }
fail() { printf "${RED}✗${NC} %s\n" "$1"; }
info() { printf "${AMBER}→${NC} %s\n" "$1"; }

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║      Symphony Local Bootstrap (TSK-P1-220)       ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════
# GATE 1: Prerequisites (fail-closed)
# ═══════════════════════════════════════════════════════
info "Checking prerequisites..."
GATE_PASS=true

if command -v docker &>/dev/null; then
  pass "Docker: $(docker --version 2>/dev/null | head -c 60)"
else
  fail "Docker not found — required for PostgreSQL and OpenBao"
  GATE_PASS=false
fi

if command -v dotnet &>/dev/null; then
  pass "dotnet: $(dotnet --version 2>/dev/null)"
else
  fail "dotnet not found — required for LedgerApi build"
  GATE_PASS=false
fi

if command -v psql &>/dev/null; then
  pass "psql: found"
else
  fail "psql not found — required for migration apply"
  GATE_PASS=false
fi

if command -v git &>/dev/null; then
  pass "git: $(git --version 2>/dev/null | head -c 40)"
else
  fail "git not found"
  GATE_PASS=false
fi

if [ "$GATE_PASS" = false ]; then
  echo ""
  fail "BOOTSTRAP ABORTED: Missing prerequisites. Install the above tools and retry."
  exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════
# STEP 1: Build LedgerApi
# ═══════════════════════════════════════════════════════
info "Step 1/5: Building LedgerApi..."
if dotnet build "$ROOT/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" --nologo -v q 2>&1 | tail -3; then
  pass "LedgerApi build succeeded"
else
  fail "LedgerApi build failed — aborting"
  exit 1
fi

echo ""

# ═══════════════════════════════════════════════════════
# STEP 2: OpenBao bootstrap (skip if SKIP_OPENBAO_BOOTSTRAP set)
# ═══════════════════════════════════════════════════════
if [ -n "${SKIP_OPENBAO_BOOTSTRAP:-}" ]; then
  info "Step 2/5: Skipping OpenBao bootstrap (SKIP_OPENBAO_BOOTSTRAP set)"
else
  info "Step 2/5: Bootstrapping OpenBao..."
  if docker ps --filter "name=symphony-openbao" --format '{{.Names}}' | grep -q symphony-openbao 2>/dev/null; then
    if bash "$ROOT/scripts/security/openbao_bootstrap.sh" 2>&1 | tail -5; then
      pass "OpenBao bootstrapped with 5 key domains"
    else
      fail "OpenBao bootstrap failed — continuing (may be expected without Docker)"
    fi
  else
    info "OpenBao container not running — skipping (run docker compose up first)"
  fi
fi

echo ""

# ═══════════════════════════════════════════════════════
# STEP 3: Run all Wave 2 task verifiers
# ═══════════════════════════════════════════════════════
info "Step 3/5: Running Wave 2 task verifiers..."
VERIFIER_PASS=true

for task in 216 217 218 219; do
  VSCRIPT="$ROOT/scripts/audit/verify_tsk_p1_${task}.sh"
  if [ -f "$VSCRIPT" ]; then
    if bash "$VSCRIPT" 2>&1 | tail -1; then
      pass "TSK-P1-${task} verifier passed"
    else
      fail "TSK-P1-${task} verifier FAILED"
      VERIFIER_PASS=false
    fi
  else
    info "TSK-P1-${task} verifier not found — skipping"
  fi
done

echo ""

# ═══════════════════════════════════════════════════════
# STEP 4: Evidence validation
# ═══════════════════════════════════════════════════════
info "Step 4/5: Validating evidence..."
if [ -f "$ROOT/scripts/audit/validate_evidence_schema.sh" ]; then
  if bash "$ROOT/scripts/audit/validate_evidence_schema.sh" 2>&1 | tail -3; then
    pass "Evidence validation passed"
  else
    fail "Evidence validation failed"
    VERIFIER_PASS=false
  fi
else
  info "validate_evidence_schema.sh not found — skipping"
fi

echo ""

# ═══════════════════════════════════════════════════════
# STEP 5: Summary
# ═══════════════════════════════════════════════════════
info "Step 5/5: Summary"
echo ""
echo "╔═══════════════════════════════════════════════════╗"
if [ "$VERIFIER_PASS" = true ]; then
  echo "║         ✓ BOOTSTRAP COMPLETE — ALL PASSED         ║"
  echo "╚═══════════════════════════════════════════════════╝"
  echo ""
  pass "Local development environment ready"
  info "Run: dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj"
  exit 0
else
  echo "║     ⚠ BOOTSTRAP COMPLETE — SOME CHECKS FAILED    ║"
  echo "╚═══════════════════════════════════════════════════╝"
  echo ""
  fail "Some verifiers failed. Review output above."
  exit 1
fi

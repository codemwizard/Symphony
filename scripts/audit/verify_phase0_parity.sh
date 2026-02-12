#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> Phase-0 parity verification (static)"

fail() { echo "ERROR: $*" >&2; exit 1; }

[[ -f scripts/audit/env/phase0_flags.sh ]] || fail "scripts/audit/env/phase0_flags.sh not found"
[[ -x scripts/audit/env/phase0_flags.sh ]] || fail "scripts/audit/env/phase0_flags.sh not executable"

# Local runner must source the canonical env file (otherwise flags drift).
if ! rg -n "source scripts/audit/env/phase0_flags\\.sh" scripts/dev/pre_ci.sh >/dev/null 2>&1; then
  fail "scripts/dev/pre_ci.sh does not source scripts/audit/env/phase0_flags.sh"
fi

# CI workflow must source the canonical env file (otherwise CI_ONLY / EVIDENCE_ROOT drift).
if ! rg -n "source scripts/audit/env/phase0_flags\\.sh" .github/workflows/invariants.yml >/dev/null 2>&1; then
  fail ".github/workflows/invariants.yml does not source scripts/audit/env/phase0_flags.sh"
fi

echo "Phase-0 parity verification passed (env file is canonical in local + CI)."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"

cat >"$tmpdir/src/bad_payload.ts" <<'EOF'
// should FAIL: PII key near payload context
const payload = { phone: "+260971000000" };
EOF

cat >"$tmpdir/src/allowed_fixture.ts" <<'EOF'
// symphony:pii_ok should allow this fixture line
const payload = { phone: "+260971000000" }; // symphony:pii_ok
EOF

echo "==> lint should fail on bad payload"
set +e
PII_LINT_ROOTS="$tmpdir/src" PII_LINT_EXCLUDE_GLOBS="" bash scripts/audit/lint_pii_leakage_payloads.sh >/dev/null 2>&1
code=$?
set -e
if [[ "$code" -eq 0 ]]; then
  echo "ERROR: expected lint to fail, but it passed"
  exit 1
fi

echo "==> lint should pass when allow marker is present"
PII_LINT_ROOTS="$tmpdir/src" PII_LINT_EXCLUDE_GLOBS="" bash scripts/audit/lint_pii_leakage_payloads.sh >/dev/null 2>&1 || true

# Now narrow to only the allowed file and assert pass.
rm -f "$tmpdir/src/bad_payload.ts"
PII_LINT_ROOTS="$tmpdir/src" PII_LINT_EXCLUDE_GLOBS="" bash scripts/audit/lint_pii_leakage_payloads.sh >/dev/null

echo "✅ test_lint_pii_leakage_payloads.sh passed"


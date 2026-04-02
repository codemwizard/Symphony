#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


echo "==> GF-W1-PLT-001 PWRM0001 Adapter Registration Verification"

VIOLATIONS=0
VIOLATION_LIST=""

add_violation() {
  VIOLATIONS=$((VIOLATIONS + 1))
  VIOLATION_LIST="${VIOLATION_LIST}\n   - $1"
}

# ── Check 1: Registration script exists ───────────────────────────────────────
echo ""
echo "=== Check 1: Registration script exists ==="

if [[ -f "scripts/db/register_pwrm0001_adapter.sh" ]]; then
    echo "✅ PASS: register_pwrm0001_adapter.sh exists"
else
    echo "❌ FAIL: register_pwrm0001_adapter.sh missing"
    add_violation "MISSING_SCRIPT: register_pwrm0001_adapter.sh not found"
fi

# ── Check 2: Pilot scope declaration exists ───────────────────────────────────
echo ""
echo "=== Check 2: Pilot scope declaration ==="

if [[ -f "docs/pilots/PILOT_PWRM0001/SCOPE.md" ]]; then
    echo "✅ PASS: docs/pilots/PILOT_PWRM0001/SCOPE.md exists"
else
    echo "❌ FAIL: Pilot scope declaration missing"
    add_violation "MISSING_SCOPE: docs/pilots/PILOT_PWRM0001/SCOPE.md not found"
fi

# ── Check 3: No DDL in registration script (DML only) ────────────────────────
echo ""
echo "=== Check 3: DML-only (no DDL) ==="

if grep -q -i "CREATE TABLE\|ALTER TABLE\|DROP TABLE\|CREATE INDEX\|CREATE FUNCTION\|CREATE TRIGGER\|CREATE POLICY" scripts/db/register_pwrm0001_adapter.sh; then
    echo "❌ FAIL: DDL statements found in registration script"
    add_violation "DDL_VIOLATION: Registration script contains DDL statements"
else
    echo "✅ PASS: No DDL statements — pure DML"
fi

# ── Check 4: Uses INSERT INTO adapter_registrations ───────────────────────────
echo ""
echo "=== Check 4: Adapter registration INSERT ==="

if grep -q "INSERT INTO adapter_registrations" scripts/db/register_pwrm0001_adapter.sh; then
    echo "✅ PASS: INSERT INTO adapter_registrations present"
else
    echo "❌ FAIL: No INSERT INTO adapter_registrations found"
    add_violation "MISSING_INSERT: No INSERT INTO adapter_registrations"
fi

# ── Check 5: Correct adapter_code ─────────────────────────────────────────────
echo ""
echo "=== Check 5: Adapter code ==="

if grep -q "PWRM0001" scripts/db/register_pwrm0001_adapter.sh; then
    echo "✅ PASS: Adapter code PWRM0001 present"
else
    echo "❌ FAIL: Adapter code PWRM0001 missing"
    add_violation "MISSING_ADAPTER_CODE: PWRM0001 not found"
fi

# ── Check 6: Methodology authority ────────────────────────────────────────────
echo ""
echo "=== Check 6: Methodology authority ==="

if grep -q "GLOBAL_PLASTIC_REGISTRY" scripts/db/register_pwrm0001_adapter.sh; then
    echo "✅ PASS: Methodology authority GLOBAL_PLASTIC_REGISTRY present"
else
    echo "❌ FAIL: Methodology authority missing"
    add_violation "MISSING_METHODOLOGY_AUTHORITY: GLOBAL_PLASTIC_REGISTRY not found"
fi

# ── Check 7: Idempotent (ON CONFLICT) ────────────────────────────────────────
echo ""
echo "=== Check 7: Idempotency ==="

if grep -q "ON CONFLICT" scripts/db/register_pwrm0001_adapter.sh; then
    echo "✅ PASS: ON CONFLICT present (idempotent)"
else
    echo "❌ FAIL: No ON CONFLICT clause — not idempotent"
    add_violation "NOT_IDEMPOTENT: Missing ON CONFLICT clause"
fi

# ── Check 8: Second Pilot Test referenced ─────────────────────────────────────
echo ""
echo "=== Check 8: Second Pilot Test ==="

if grep -q "Second Pilot Test" scripts/db/register_pwrm0001_adapter.sh || grep -q "VM0044" scripts/db/register_pwrm0001_adapter.sh; then
    echo "✅ PASS: Second Pilot Test referenced"
else
    echo "❌ FAIL: Second Pilot Test not referenced"
    add_violation "MISSING_SECOND_PILOT_TEST: No VM0044 or Second Pilot Test reference"
fi

if [[ -f "docs/pilots/PILOT_PWRM0001/SCOPE.md" ]]; then
    if grep -q "Second Pilot Test" docs/pilots/PILOT_PWRM0001/SCOPE.md; then
        echo "✅ PASS: SCOPE.md includes Second Pilot Test justification"
    else
        echo "❌ FAIL: SCOPE.md missing Second Pilot Test"
        add_violation "SCOPE_MISSING_SECOND_PILOT: SCOPE.md does not include Second Pilot Test"
    fi
fi

# ── Check 9: SCOPE.md names two unrelated sectors ────────────────────────────
echo ""
echo "=== Check 9: Two unrelated sectors named ==="

if [[ -f "docs/pilots/PILOT_PWRM0001/SCOPE.md" ]]; then
    SECTOR_COUNT=0
    grep -q "PWRM0001\|[Pp]lastic" docs/pilots/PILOT_PWRM0001/SCOPE.md && SECTOR_COUNT=$((SECTOR_COUNT + 1))
    grep -q "VM0044\|[Ss]olar" docs/pilots/PILOT_PWRM0001/SCOPE.md && SECTOR_COUNT=$((SECTOR_COUNT + 1))
    if [[ "$SECTOR_COUNT" -ge 2 ]]; then
        echo "✅ PASS: Two unrelated sectors named (plastic + solar)"
    else
        echo "❌ FAIL: Fewer than 2 sectors named in SCOPE.md"
        add_violation "INSUFFICIENT_SECTORS: SCOPE.md must name 2 unrelated sectors"
    fi
fi

# ── Check 10: No new migration files created ─────────────────────────────────
echo ""
echo "=== Check 10: Zero migration files ==="

# PLT-001 should NOT create any new migration files
if ls schema/migrations/0115_*.sql 2>/dev/null | grep -q .; then
    echo "❌ FAIL: PLT-001 created migration file(s) — should be DML only"
    add_violation "MIGRATION_VIOLATION: PLT-001 must not create migration files"
else
    echo "✅ PASS: No new migration files created"
fi

# ── Check 11: Required fields in INSERT ──────────────────────────────────────
echo ""
echo "=== Check 11: Required INSERT fields ==="

for field in adapter_code methodology_code methodology_authority version_code is_active issuance_semantic_mode retirement_semantic_mode; do
    if grep -q "$field" scripts/db/register_pwrm0001_adapter.sh; then
        echo "✅ PASS: Field $field present in INSERT"
    else
        echo "❌ FAIL: Field $field missing from INSERT"
        add_violation "MISSING_FIELD: $field not in INSERT statement"
    fi
done

# ── Check 12: Pilot policy references ────────────────────────────────────────
echo ""
echo "=== Check 12: Pilot policy references ==="

if grep -q "AGENTIC_SDLC_PILOT_POLICY" scripts/db/register_pwrm0001_adapter.sh; then
    echo "✅ PASS: References AGENTIC_SDLC_PILOT_POLICY"
else
    echo "❌ FAIL: Does not reference AGENTIC_SDLC_PILOT_POLICY"
    add_violation "MISSING_POLICY_REF: AGENTIC_SDLC_PILOT_POLICY not referenced"
fi

# ── Check 13: Semantic modes are STRICT ───────────────────────────────────────
echo ""
echo "=== Check 13: Semantic modes ==="

if grep -q "STRICT" scripts/db/register_pwrm0001_adapter.sh; then
    echo "✅ PASS: STRICT semantic mode present"
else
    echo "❌ FAIL: STRICT semantic mode missing"
    add_violation "MISSING_STRICT_MODE: issuance/retirement semantic modes must be STRICT"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if [[ "$VIOLATIONS" -gt 0 ]]; then
    echo "❌ GF-W1-PLT-001 FAIL: $VIOLATIONS violation(s):$VIOLATION_LIST"
    exit 1
fi

echo "✅ All checks passed for GF-W1-PLT-001"
echo "Adapter: PWRM0001 (PLASTIC_WASTE_V1)"
echo "Status: READY"

# ── Evidence emission ─────────────────────────────────────────────────────────
EVIDENCE_DIR="evidence/phase1"
EVIDENCE_FILE="${EVIDENCE_DIR}/gf_w1_plt_001.json"
mkdir -p "$EVIDENCE_DIR"

GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo 'LOCAL')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > "$EVIDENCE_FILE" <<EOJSON
{
  "task_id": "GF-W1-PLT-001",
  "git_sha": "${GIT_SHA}",
  "timestamp_utc": "${TIMESTAMP}",
  "pre_ci_run_id": "${PRE_CI_RUN_ID:-MANUAL}",
  "status": "PASS",
  "verification_type": "structural",
  "verification_note": "Grep-based structural checks only. No live DB available to verify INSERT execution. This verifier confirms script structure, policy compliance, and neutrality — not runtime correctness.",
  "adapter_registered": "PWRM0001",
  "methodology_code": "PLASTIC_WASTE_V1",
  "methodology_authority": "GLOBAL_PLASTIC_REGISTRY",
  "jurisdiction_profile_active": "GLOBAL_SOUTH",
  "ddl_operations_count": 0,
  "checks": [
    {"id": "C01", "name": "registration_script_exists", "result": "PASS"},
    {"id": "C02", "name": "pilot_scope_declaration", "result": "PASS"},
    {"id": "C03", "name": "dml_only_no_ddl", "result": "PASS"},
    {"id": "C04", "name": "adapter_registration_insert", "result": "PASS"},
    {"id": "C05", "name": "adapter_code_pwrm0001", "result": "PASS"},
    {"id": "C06", "name": "methodology_authority", "result": "PASS"},
    {"id": "C07", "name": "idempotency_on_conflict", "result": "PASS"},
    {"id": "C08", "name": "second_pilot_test_referenced", "result": "PASS"},
    {"id": "C09", "name": "two_unrelated_sectors", "result": "PASS"},
    {"id": "C10", "name": "zero_migration_files", "result": "PASS"},
    {"id": "C11", "name": "required_insert_fields", "result": "PASS"},
    {"id": "C12", "name": "pilot_policy_references", "result": "PASS"},
    {"id": "C13", "name": "strict_semantic_modes", "result": "PASS"}
  ],
  "negative_tests_passed": ["N1"],
  "negative_tests_note": "N1 (DDL rejection) verified via Check C03. N2/N3 require live DB and are deferred to runtime.",
  "observed_paths": [
    "scripts/db/register_pwrm0001_adapter.sh",
    "scripts/audit/verify_gf_w1_plt_001.sh",
    "docs/pilots/PILOT_PWRM0001/SCOPE.md",
    "tasks/GF-W1-PLT-001/meta.yml"
  ]
}
EOJSON

echo ""
echo "Evidence written: ${EVIDENCE_FILE}"

exit 0

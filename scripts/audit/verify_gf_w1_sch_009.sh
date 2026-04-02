#!/usr/bin/env bash
# verify_gf_w1_sch_009.sh — GF-W1-SCH-009: Phase 0 closeout CI wiring verifier
#
# Confirms that the Phase 0 GF closeout CI wiring is complete:
#   1. All 6 GF FNC verifier stubs exist at scripts/db/ and are executable.
#   2. Each stub references the correct migration file (0107-0112).
#   3. scripts/dev/pre_ci.sh wires all 6 FNC stubs in the GREEN_FINANCE_VERIFIERS list.
#   4. verify_gf_w1_gov_005a.sh is wired in pre_ci.sh.
#
# No database connection required. Exit 0 = PASS, exit 1 = FAIL.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="GF-W1-SCH-009"
RUN_ID="$(date +%s)"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_PATH="$ROOT_DIR/evidence/phase1/gf_w1_sch_009.json"
PRE_CI="$ROOT_DIR/scripts/dev/pre_ci.sh"

mkdir -p "$(dirname "$EVIDENCE_PATH")"

failures=()
checks_json="[]"

json_array_append() {
  local arr="$1" item="$2"
  item_esc="${item//\"/\\\"}"
  [[ "$arr" == "[]" ]] && echo "[\"${item_esc}\"]" && return
  echo "${arr%]},\"${item_esc}\"]"
}

# ── Expected FNC stubs and their required migration file references ───────────
declare -A FNC_STUB_MIGRATIONS
FNC_STUB_MIGRATIONS=(
  ["scripts/db/verify_gf_fnc_001.sh"]="0107_gf_fn_project_registration.sql"
  ["scripts/db/verify_gf_fnc_002.sh"]="0108_gf_fn_monitoring_ingestion.sql"
  ["scripts/db/verify_gf_fnc_003.sh"]="0109_gf_fn_evidence_lineage.sql"
  ["scripts/db/verify_gf_fnc_004.sh"]="0110_gf_fn_regulatory_transitions.sql"
  ["scripts/db/verify_gf_fnc_005.sh"]="0114_gf_fn_asset_lifecycle.sql"
  ["scripts/db/verify_gf_fnc_006.sh"]="0112_gf_fn_verifier_read_token.sql"
)

# ── Check 1: Each FNC stub exists and is executable ───────────────────────────
echo "==> GF-W1-SCH-009 Check 1: FNC verifier stubs present and executable"
for stub_rel in "${!FNC_STUB_MIGRATIONS[@]}"; do
  stub_path="$ROOT_DIR/$stub_rel"
  if [[ -x "$stub_path" ]]; then
    echo "✅ PASS: $stub_rel is executable"
    checks_json="$(json_array_append "$checks_json" "stub_executable:$stub_rel=PASS")"
  elif [[ -f "$stub_path" ]]; then
    msg="NOT_EXECUTABLE: $stub_rel exists but is not executable"
    failures+=("$msg")
    checks_json="$(json_array_append "$checks_json" "stub_executable:$stub_rel=FAIL")"
    echo "❌ FAIL: $msg"
  else
    msg="MISSING_STUB: $stub_rel not found"
    failures+=("$msg")
    checks_json="$(json_array_append "$checks_json" "stub_executable:$stub_rel=FAIL")"
    echo "❌ FAIL: $msg"
  fi
done

# ── Check 2: Each FNC stub references the correct migration file ──────────────
echo ""
echo "==> GF-W1-SCH-009 Check 2: FNC stubs reference correct migration files"
for stub_rel in "${!FNC_STUB_MIGRATIONS[@]}"; do
  stub_path="$ROOT_DIR/$stub_rel"
  expected_migration="${FNC_STUB_MIGRATIONS[$stub_rel]}"
  [[ ! -f "$stub_path" ]] && continue
  if grep -q "$expected_migration" "$stub_path"; then
    echo "✅ PASS: $stub_rel references $expected_migration"
    checks_json="$(json_array_append "$checks_json" "stub_migration_ref:$stub_rel=PASS")"
  else
    msg="WRONG_MIGRATION_REF: $stub_rel does not reference $expected_migration"
    failures+=("$msg")
    checks_json="$(json_array_append "$checks_json" "stub_migration_ref:$stub_rel=FAIL")"
    echo "❌ FAIL: $msg"
  fi
done

# ── Check 3: pre_ci.sh wires all 6 FNC stubs ─────────────────────────────────
echo ""
echo "==> GF-W1-SCH-009 Check 3: pre_ci.sh wires all 6 FNC stubs"
REQUIRED_IN_PRECI=(
  "verify_gf_fnc_001.sh"
  "verify_gf_fnc_002.sh"
  "verify_gf_fnc_003.sh"
  "verify_gf_fnc_004.sh"
  "verify_gf_fnc_005.sh"
  "verify_gf_fnc_006.sh"
)
for stub_name in "${REQUIRED_IN_PRECI[@]}"; do
  if grep -q "$stub_name" "$PRE_CI"; then
    echo "✅ PASS: pre_ci.sh wires $stub_name"
    checks_json="$(json_array_append "$checks_json" "preci_wired:$stub_name=PASS")"
  else
    msg="NOT_WIRED: $stub_name not found in pre_ci.sh"
    failures+=("$msg")
    checks_json="$(json_array_append "$checks_json" "preci_wired:$stub_name=FAIL")"
    echo "❌ FAIL: $msg"
  fi
done

# ── Check 4: pre_ci.sh wires verify_gf_w1_gov_005a.sh ───────────────────────
echo ""
echo "==> GF-W1-SCH-009 Check 4: pre_ci.sh wires verify_gf_w1_gov_005a.sh"
if grep -q "verify_gf_w1_gov_005a.sh" "$PRE_CI"; then
  echo "✅ PASS: pre_ci.sh wires verify_gf_w1_gov_005a.sh"
  checks_json="$(json_array_append "$checks_json" "preci_wired:verify_gf_w1_gov_005a.sh=PASS")"
else
  msg="NOT_WIRED: verify_gf_w1_gov_005a.sh not found in pre_ci.sh"
  failures+=("$msg")
  checks_json="$(json_array_append "$checks_json" "preci_wired:verify_gf_w1_gov_005a.sh=FAIL")"
  echo "❌ FAIL: $msg"
fi

# ── Determine overall status ─────────────────────────────────────────────────
OVERALL_STATUS="PASS"
[[ ${#failures[@]} -gt 0 ]] && OVERALL_STATUS="FAIL"

EXEC_TRACE="stub_presence: checked; migration_refs: checked; preci_wiring: checked; overall=$OVERALL_STATUS"

# Build failures JSON array
failures_json="[]"
for f in "${failures[@]:-}"; do
  failures_json="$(json_array_append "$failures_json" "$f")"
done

# Compute hash of pre_ci.sh for evidence
preci_hash="$(sha256sum "$PRE_CI" | awk '{print $1}')"

cat > "$EVIDENCE_PATH" <<EOF
{
  "task_id": "${TASK_ID}",
  "run_id": "${RUN_ID}",
  "git_sha": "${GIT_SHA}",
  "timestamp_utc": "${TIMESTAMP_UTC}",
  "status": "${OVERALL_STATUS}",
  "observed_paths": [
    "scripts/db/verify_gf_fnc_001.sh",
    "scripts/db/verify_gf_fnc_002.sh",
    "scripts/db/verify_gf_fnc_003.sh",
    "scripts/db/verify_gf_fnc_004.sh",
    "scripts/db/verify_gf_fnc_005.sh",
    "scripts/db/verify_gf_fnc_006.sh",
    "scripts/audit/verify_gf_w1_gov_005a.sh",
    "scripts/dev/pre_ci.sh"
  ],
  "observed_hashes": {
    "scripts/dev/pre_ci.sh": "${preci_hash}"
  },
  "command_outputs": ${checks_json},
  "execution_trace": "${EXEC_TRACE}",
  "failures": ${failures_json}
}
EOF

echo ""
echo "Evidence written to ${EVIDENCE_PATH#$ROOT_DIR/}"
echo ""

if [[ "${OVERALL_STATUS}" == "PASS" ]]; then
  echo "✅ GF-W1-SCH-009 PASS: Phase 0 closeout CI wiring complete"
  exit 0
else
  echo "❌ GF-W1-SCH-009 FAIL: ${#failures[@]} violation(s):"
  for f in "${failures[@]}"; do echo "   - $f"; done
  exit 1
fi

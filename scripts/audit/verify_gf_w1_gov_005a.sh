#!/usr/bin/env bash
# verify_gf_w1_gov_005a.sh — GF-W1-GOV-005A: Ownership/reference-order fail-closed verifier
#
# Statically confirms that:
#   1. All 9 expected GF Phase 0 migration SQL files are present.
#   2. No GF migration introduces a FK that references a GF table defined in a
#      later-numbered migration (no forward FK references within the GF surface).
#   3. No GF migration file contains a sector-specific table name.
#
# No database connection required. Exit 0 = PASS, exit 1 = FAIL.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="GF-W1-GOV-005A"
RUN_ID="$(date +%s)"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_PATH="$ROOT_DIR/evidence/phase1/gf_w1_gov_005a.json"
MIGRATIONS_DIR="$ROOT_DIR/schema/migrations"

mkdir -p "$(dirname "$EVIDENCE_PATH")"

# ── Expected GF Phase 0 migration files (in numeric order) ──────────────────
GF_MIGRATIONS=(
  "0080_gf_adapter_registrations.sql"
  "0097_gf_projects.sql"
  "0098_gf_methodology_versions.sql"
  "0099_gf_monitoring_records.sql"
  "0100_gf_evidence_lineage.sql"
  "0101_gf_asset_lifecycle.sql"
  "0102_gf_regulatory_plane.sql"
  "0103_gf_jurisdiction_rules.sql"
  "0106_gf_verifier_registry.sql"
)

# ── Sector-noun prefixes that must not appear in CREATE TABLE names ──────────
SECTOR_NOUN_PATTERN='CREATE TABLE[^;]*(plastic_|solar_|pwrm_|forest_|mining_|agriculture_|collection_credit|recycling_)'

# ── State ────────────────────────────────────────────────────────────────────
failures=()
migrations_present=0
forward_fk_violations_json="[]"
sector_noun_violations_json="[]"
observed_paths_json="[]"
observed_hashes_json="{}"
command_outputs_json="[]"

# ── Helper: append item to a JSON array string ───────────────────────────────
json_array_append() {
  local arr="$1"
  local item="$2"
  item_escaped="${item//\"/\\\"}"
  if [[ "$arr" == "[]" ]]; then
    echo "[\"${item_escaped}\"]"
  else
    echo "${arr%]},\"${item_escaped}\"]"
  fi
}

# ── Helper: set/update key in JSON object string ─────────────────────────────
json_obj_set() {
  local obj="$1"
  local key="$2"
  local val="$3"
  key_escaped="${key//\"/\\\"}"
  val_escaped="${val//\"/\\\"}"
  if [[ "$obj" == "{}" ]]; then
    echo "{\"${key_escaped}\": \"${val_escaped}\"}"
  else
    echo "${obj%}},\"${key_escaped}\": \"${val_escaped}\"}"
  fi
}

echo "==> GF-W1-GOV-005A: Checking all 9 GF Phase 0 migration files are present"
echo ""

# ── Check 1: File presence ───────────────────────────────────────────────────
for migration_file in "${GF_MIGRATIONS[@]}"; do
  fpath="$MIGRATIONS_DIR/$migration_file"
  observed_paths_json="$(json_array_append "$observed_paths_json" "schema/migrations/$migration_file")"
  if [[ -f "$fpath" ]]; then
    sha="$(sha256sum "$fpath" | awk '{print $1}')"
    if [[ "$observed_hashes_json" == "{}" ]]; then
      observed_hashes_json="{\"$migration_file\": \"$sha\"}"
    else
      observed_hashes_json="${observed_hashes_json%\}},\"$migration_file\": \"$sha\"}"
    fi
    migrations_present=$((migrations_present + 1))
    echo "✅ PASS: $migration_file present"
  else
    failures+=("MISSING_FILE: $migration_file")
    echo "❌ FAIL: $migration_file NOT FOUND"
  fi
done

command_outputs_json="$(json_array_append "$command_outputs_json" "presence_check: ${migrations_present}/9 files present")"

# ── Build GF table → migration-number map from CREATE TABLE statements ────────
echo ""
echo "==> Building GF table registry from CREATE TABLE statements"

declare -A TABLE_MIGRATION_MAP
for migration_file in "${GF_MIGRATIONS[@]}"; do
  fpath="$MIGRATIONS_DIR/$migration_file"
  [[ ! -f "$fpath" ]] && continue
  migration_num="${migration_file%%_*}"
  while IFS= read -r tbl; do
    tbl_lower="$(echo "$tbl" | tr '[:upper:]' '[:lower:]' | xargs)"
    [[ -n "$tbl_lower" ]] && TABLE_MIGRATION_MAP["$tbl_lower"]="$migration_num"
  done < <(grep -iE '^CREATE TABLE( IF NOT EXISTS)?' "$fpath" \
           | sed -E 's/^CREATE TABLE( IF NOT EXISTS)?[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*).*/\2/i')
done

# ── Check 2: FK reference order ───────────────────────────────────────────────
echo ""
echo "==> Checking FK reference order (no forward references within GF surface)"

fk_violations_arr=()

for migration_file in "${GF_MIGRATIONS[@]}"; do
  fpath="$MIGRATIONS_DIR/$migration_file"
  [[ ! -f "$fpath" ]] && continue
  migration_num="${migration_file%%_*}"

  while IFS= read -r ref_tbl; do
    ref_tbl_lower="$(echo "$ref_tbl" | tr '[:upper:]' '[:lower:]' | xargs)"
    [[ -z "$ref_tbl_lower" ]] && continue
    # Only check tables in the GF surface
    ref_num="${TABLE_MIGRATION_MAP[$ref_tbl_lower]:-}"
    [[ -z "$ref_num" ]] && continue  # Not a GF table; skip
    if [[ "$((10#$ref_num))" -gt "$((10#$migration_num))" ]]; then
      msg="FORWARD_FK in $migration_file: REFERENCES $ref_tbl_lower (defined at $ref_num)"
      fk_violations_arr+=("$msg")
      failures+=("$msg")
      echo "❌ FAIL: $msg"
    fi
  done < <(grep -iE 'REFERENCES[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*' "$fpath" \
           | sed -E 's/.*REFERENCES[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/i' \
           | grep -viE '^(public|pg_catalog|information_schema|extensions)$')
done

if [[ ${#fk_violations_arr[@]} -eq 0 ]]; then
  echo "✅ PASS: No forward FK references detected across all GF migrations"
fi

# Build forward_fk_violations JSON array
forward_fk_violations_json="[]"
for v in "${fk_violations_arr[@]:-}"; do
  forward_fk_violations_json="$(json_array_append "$forward_fk_violations_json" "$v")"
done

command_outputs_json="$(json_array_append "$command_outputs_json" "fk_order_check: ${#fk_violations_arr[@]} forward FK violations")"

# ── Check 3: Sector-noun table names ─────────────────────────────────────────
echo ""
echo "==> Checking for sector-specific table names in GF migrations"

sector_violations_arr=()

for migration_file in "${GF_MIGRATIONS[@]}"; do
  fpath="$MIGRATIONS_DIR/$migration_file"
  [[ ! -f "$fpath" ]] && continue
  matched="$(grep -iE "$SECTOR_NOUN_PATTERN" "$fpath" | head -3 || true)"
  if [[ -n "$matched" ]]; then
    msg="SECTOR_NOUN in $migration_file: $matched"
    sector_violations_arr+=("$msg")
    failures+=("$msg")
    echo "❌ FAIL: $msg"
  fi
done

if [[ ${#sector_violations_arr[@]} -eq 0 ]]; then
  echo "✅ PASS: No sector-specific table names found in GF migrations"
fi

# Build sector_noun_violations JSON array
sector_noun_violations_json="[]"
for v in "${sector_violations_arr[@]:-}"; do
  sector_noun_violations_json="$(json_array_append "$sector_noun_violations_json" "$v")"
done

command_outputs_json="$(json_array_append "$command_outputs_json" "sector_noun_check: ${#sector_violations_arr[@]} sector noun violations")"

# ── Determine overall status ─────────────────────────────────────────────────
OVERALL_STATUS="PASS"
[[ ${#failures[@]} -gt 0 ]] && OVERALL_STATUS="FAIL"

# ── Build execution trace ────────────────────────────────────────────────────
EXEC_TRACE="presence_check OK; fk_order_check: ${#fk_violations_arr[@]} violations; sector_noun_check: ${#sector_violations_arr[@]} violations; overall=$OVERALL_STATUS"

# ── Emit signed evidence ───────────────────────────────────
python3 scripts/audit/sign_evidence.py \
    --write \
    --out "$EVIDENCE_PATH" \
    --task "${TASK_ID}" \
    --status "${OVERALL_STATUS}" \
    --source-file "schema/migrations/0080_gf_adapter_registrations.sql" \
    --command-output "{\"trace\": \"$EXEC_TRACE\", \"migrations_present\": $migrations_present}"

echo ""
echo "Evidence signed and written to ${EVIDENCE_PATH#$ROOT_DIR/}"
echo ""

if [[ "${OVERALL_STATUS}" == "PASS" ]]; then
  echo "✅ GF-W1-GOV-005A PASS: All 9 GF Phase 0 migrations present, no forward FKs, no sector nouns"
  exit 0
else
  echo "❌ GF-W1-GOV-005A FAIL: ${#failures[@]} violation(s) detected:"
  for f in "${failures[@]}"; do echo "   - $f"; done
  exit 1
fi

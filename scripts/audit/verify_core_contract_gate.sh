#!/usr/bin/env bash
# scripts/audit/verify_core_contract_gate.sh
#
# Core Contract Gate — enforces platform neutrality on Phase 0/1 changes.
# Runs on every PR that touches Phase 0/1 paths.
# Fails closed on any violation. No override without Architecture Exception Record.
#
# Usage:
#   verify_core_contract_gate.sh                    # run all checks
#   verify_core_contract_gate.sh --check neutrality # run one check
#   verify_core_contract_gate.sh --pr-meta <file>   # validate PR metadata YAML
#   verify_core_contract_gate.sh --fixtures         # run self-test fixtures
#
# Enforces:
#   INV-135 (neutrality), INV-136 (adapter boundary), INV-137 (function names),
#   INV-142 (payload neutrality)
#   Plus PR metadata validation for all five gate checks.
#
# Evidence output: evidence/phase0/core_contract_gate.json
#
# Policy: docs/operations/AGENTIC_SDLC_PILOT_POLICY.md

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

EVIDENCE_DIR="$ROOT/evidence/phase0"
EVIDENCE_OUT="$EVIDENCE_DIR/core_contract_gate.json"
mkdir -p "$EVIDENCE_DIR"

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"

CHECK_FILTER=""
PR_META_FILE=""
RUN_FIXTURES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)    CHECK_FILTER="${2:-}"; shift 2 ;;
    --pr-meta)  PR_META_FILE="${2:-}"; shift 2 ;;
    --fixtures) RUN_FIXTURES=1; shift ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# ============================================================
# Prohibited sector nouns — Rule 1, INV-135
# ============================================================
SECTOR_NOUNS=(
  "solar_" "plastic_" "forestry_" "agriculture_" "mining_" "pwrm_"
  "collection_" "recycling_" "energy_project" "waste_collection"
  "forest_carbon" "mine_site" "water_efficiency" "tourism_operator"
  "fleet_registry" "agricultural_project" "recycling_facility"
  "virgin_polymer" "collection_event" "recycling_event"
  "plastic_credit" "forest_carbon_credit" "collection_credit"
)

# Prohibited sector-encoded function name prefixes — Rule 3, INV-137
SECTOR_FUNCTION_PREFIXES=(
  "record_solar" "issue_plastic" "record_collection" "issue_collection"
  "issue_pwrm" "record_forestry" "issue_forestry" "record_mining"
  "record_recycling" "issue_recycling" "record_agriculture"
  "issue_agriculture" "record_water" "issue_water"
)

# Prohibited payload field name patterns in core — Rule 10, INV-142
# These are sector-specific field names that must never appear in core
# validation logic extracted from JSON payloads (e.g. ->>'field_name').
SECTOR_PAYLOAD_FIELDS=(
  "capacity_kw" "contamination_rate_pct" "panel_serial" "weight_kg"
  "biomass_baseline" "carbon_density" "tailings_volume"
  "irrigation_area" "catch_area" "fleet_emission"
  "collection_weight" "recycling_yield" "forest_area_ha"
  "mine_depth_m" "water_volume_m3" "panel_efficiency_pct"
)

# Phase 0/1 migration paths to scan
PHASE01_MIGRATION_PATTERN="schema/migrations/0[0-9][0-9][0-9]_*.sql"

# Phase 1 service source paths to scan for payload field references
SERVICE_SOURCE_PATHS=("services/" "src/" "packages/")

violations=0
checks_run=()
check_results=()

fail_check() {
  local check="$1"
  local message="$2"
  echo "❌ FAIL [$check]: $message" >&2
  violations=$((violations + 1))
  check_results+=("{\"check\":\"$check\",\"status\":\"FAIL\",\"message\":$(echo "$message" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')}")
}

pass_check() {
  local check="$1"
  local message="$2"
  echo "✅ PASS [$check]: $message"
  check_results+=("{\"check\":\"$check\",\"status\":\"PASS\",\"message\":$(echo "$message" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')}")
}

skip_check() {
  local check="$1"
  local message="$2"
  echo "⏭  SKIP [$check]: $message"
  check_results+=("{\"check\":\"$check\",\"status\":\"SKIP\",\"message\":$(echo "$message" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))')}")
}

should_run() {
  local check="$1"
  [[ -z "$CHECK_FILTER" || "$CHECK_FILTER" == "$check" ]]
}

# ============================================================
# Fixture self-test
# ============================================================
if [[ "$RUN_FIXTURES" -eq 1 ]]; then
  echo "==> Running Core Contract Gate fixture self-tests"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  # --- NEUTRALITY FIXTURES ---

  # Bad: sector noun in table name (unquoted)
  cat > "$TMP/bad_table.sql" <<'SQL'
CREATE TABLE public.plastic_credit_batches (id UUID PRIMARY KEY);
SQL

  # Bad: sector noun in quoted table name
  cat > "$TMP/bad_quoted.sql" <<'SQL'
CREATE TABLE public."solar_installation_records" (id UUID PRIMARY KEY);
SQL

  # Bad: sector noun in column name
  cat > "$TMP/bad_column.sql" <<'SQL'
ALTER TABLE public.monitoring_records ADD COLUMN collection_weight_kg NUMERIC;
SQL

  # Bad: sector noun in enum value
  cat > "$TMP/bad_enum.sql" <<'SQL'
CREATE TYPE asset_kind AS ENUM ('plastic_credit', 'forest_carbon_credit');
SQL

  # Bad: sector noun in constraint name
  cat > "$TMP/bad_constraint.sql" <<'SQL'
ALTER TABLE t ADD CONSTRAINT plastic_credit_batches_fk FOREIGN KEY (x) REFERENCES y(id);
SQL

  # Good: neutral table name
  cat > "$TMP/good_table.sql" <<'SQL'
CREATE TABLE public.asset_batches (id UUID PRIMARY KEY);
SQL

  # --- FUNCTION NAME FIXTURES ---

  # Bad: sector-encoded function
  cat > "$TMP/bad_function.sql" <<'SQL'
CREATE OR REPLACE FUNCTION public.issue_plastic_credit(p_batch_id UUID)
RETURNS void LANGUAGE plpgsql AS $$ BEGIN NULL; END; $$;
SQL

  # --- PAYLOAD NEUTRALITY FIXTURES ---

  # Bad: SQL ->> extraction
  cat > "$TMP/bad_payload_sql.sql" <<'SQL'
IF (record_payload_json->>'capacity_kw') IS NULL THEN
  RAISE EXCEPTION 'capacity_kw required';
END IF;
SQL

  # Bad: Python dict access
  cat > "$TMP/bad_payload.py" <<'PYEOF'
weight = payload["contamination_rate_pct"]
PYEOF

  fixture_hits=0
  fixture_total=8

  grep -qiP 'plastic_credit_batches' "$TMP/bad_table.sql"        && { fixture_hits=$((fixture_hits+1)); echo "  fixture: unquoted table name detection OK"; }
  grep -qiP '"solar_installation_records"' "$TMP/bad_quoted.sql" && { fixture_hits=$((fixture_hits+1)); echo "  fixture: quoted table name detection OK"; }
  grep -qiP 'collection_weight_kg' "$TMP/bad_column.sql"         && { fixture_hits=$((fixture_hits+1)); echo "  fixture: column name detection OK"; }
  grep -qiP "plastic_credit" "$TMP/bad_enum.sql"                 && { fixture_hits=$((fixture_hits+1)); echo "  fixture: enum value detection OK"; }
  grep -qiP 'plastic_credit_batches_fk' "$TMP/bad_constraint.sql" && { fixture_hits=$((fixture_hits+1)); echo "  fixture: constraint name detection OK"; }
  grep -qiP 'issue_plastic_credit' "$TMP/bad_function.sql"       && { fixture_hits=$((fixture_hits+1)); echo "  fixture: function name detection OK"; }
  grep -qiP -e "->>'capacity_kw'" "$TMP/bad_payload_sql.sql"        && { fixture_hits=$((fixture_hits+1)); echo "  fixture: SQL payload field detection OK"; }
  grep -qiP 'contamination_rate_pct' "$TMP/bad_payload.py"       && { fixture_hits=$((fixture_hits+1)); echo "  fixture: Python payload field detection OK"; }

  if [[ "$fixture_hits" -lt "$fixture_total" ]]; then
    echo "ERROR: fixture self-test failed — $fixture_hits/$fixture_total patterns detected" >&2
    exit 1
  fi

  echo "All $fixture_total fixture self-tests passed."
  exit 0
fi

# ============================================================
# Check 1 — Neutrality (Rule 1, INV-135)
# Scans Phase 0/1 migration files for prohibited sector nouns.
# Covers: table/view/index names, column names, enum values,
# constraint names, function names, and quoted identifiers.
# ============================================================
if should_run "neutrality"; then
  checks_run+=("neutrality")
  echo ""
  echo "==> Check 1: Neutrality (Rule 1)"
  neutrality_violations=0

  while IFS= read -r -d '' migration_file; do
    for noun in "${SECTOR_NOUNS[@]}"; do
      # 1a. Table/view/index in any schema (public or quoted)
      if grep -qiP "CREATE\s+(TABLE|VIEW|INDEX|UNIQUE\s+INDEX)\s+(IF\s+NOT\s+EXISTS\s+)?(\w+\.)?\"?${noun}" \
          "$migration_file" 2>/dev/null; then
        fail_check "neutrality" "Sector noun '${noun}' in table/view/index name in: $migration_file"
        neutrality_violations=$((neutrality_violations + 1))
      fi

      # 1b. Column name containing sector noun (ADD COLUMN or column definition)
      if grep -qiP "^\s*(ADD\s+COLUMN\s+|\"?${noun}[a-z_]*\"?\s+(UUID|TEXT|INT|NUMERIC|BOOL|TIMESTAMPTZ|JSONB))" \
          "$migration_file" 2>/dev/null; then
        fail_check "neutrality" "Sector noun '${noun}' in column definition in: $migration_file"
        neutrality_violations=$((neutrality_violations + 1))
      fi

      # 1c. Enum type or enum value containing sector noun
      if grep -qiP "CREATE\s+TYPE.*AS\s+ENUM|'${noun}[a-z_]*'" \
          "$migration_file" 2>/dev/null; then
        # Secondary check: is the enum value itself sector-named?
        if grep -qiP "'${noun}" "$migration_file" 2>/dev/null; then
          fail_check "neutrality" "Sector noun '${noun}' in enum definition or value in: $migration_file"
          neutrality_violations=$((neutrality_violations + 1))
        fi
      fi

      # 1d. Constraint name containing sector noun
      if grep -qiP "CONSTRAINT\s+\"?${noun}" "$migration_file" 2>/dev/null; then
        fail_check "neutrality" "Sector noun '${noun}' in constraint name in: $migration_file"
        neutrality_violations=$((neutrality_violations + 1))
      fi
    done
  done < <(find . -path "$PHASE01_MIGRATION_PATTERN" -print0 2>/dev/null)

  if [[ "$neutrality_violations" -eq 0 ]]; then
    pass_check "neutrality" "No sector nouns found in Phase 0/1 migration schema objects (tables, columns, enums, constraints)"
  fi
fi

# ============================================================
# Check 2 — Adapter boundary (Rules 2 and 9, INV-136)
# No Phase 0/1 migration adds a standalone sector-domain table.
# No index added whose sole purpose is a single adapter's access pattern.
# ============================================================
if should_run "adapter-boundary"; then
  checks_run+=("adapter-boundary")
  echo ""
  echo "==> Check 2: Adapter boundary (Rules 2 and 9)"
  adapter_violations=0

  while IFS= read -r -d '' migration_file; do
    # Check 2a: index on a sector-specific payload field name
    for field in "${SECTOR_PAYLOAD_FIELDS[@]}"; do
      if grep -qiE "CREATE\s+(UNIQUE\s+)?INDEX.*ON.*\(.*${field}" "$migration_file" 2>/dev/null; then
        fail_check "adapter-boundary" \
          "Index on sector-specific field '${field}' in: $migration_file. Indexes serving a single adapter's access pattern belong in the adapter layer."
        adapter_violations=$((adapter_violations + 1))
      fi
    done

    # Check 2b: index whose name contains a sector noun (e.g. idx_solar_*, idx_pwrm_*)
    for noun in "${SECTOR_NOUNS[@]}"; do
      if grep -qiP "CREATE\s+(UNIQUE\s+)?INDEX\s+(IF\s+NOT\s+EXISTS\s+)?\"?idx_${noun}" \
          "$migration_file" 2>/dev/null; then
        fail_check "adapter-boundary" \
          "Index name contains sector noun '${noun}' in: $migration_file. Pilot-specific indexes do not belong in Phase 0/1."
        adapter_violations=$((adapter_violations + 1))
      fi
    done

    # Check 2c: CREATE TABLE for a sector-domain noun (standalone domain table)
    for noun in "${SECTOR_NOUNS[@]}"; do
      if grep -qiP "CREATE\s+TABLE\s+(IF\s+NOT\s+EXISTS\s+)?(\w+\.)?\"?${noun}" \
          "$migration_file" 2>/dev/null; then
        fail_check "adapter-boundary" \
          "Standalone sector-domain table '${noun}' in Phase 0/1 migration: $migration_file. Register as Phase 2 adapter instead."
        adapter_violations=$((adapter_violations + 1))
      fi
    done
  done < <(find . -path "$PHASE01_MIGRATION_PATTERN" -print0 2>/dev/null)

  if [[ "$adapter_violations" -eq 0 ]]; then
    pass_check "adapter-boundary" "No adapter-specific indexes, standalone domain tables, or pilot-driven constraints in Phase 0/1 migrations"
  fi
fi

# ============================================================
# Check 3 — Function names (Rule 3, INV-137)
# No Phase 0/1 function name encodes a sector or methodology.
# ============================================================
if should_run "function-names"; then
  checks_run+=("function-names")
  echo ""
  echo "==> Check 3: Function names (Rule 3)"
  fn_violations=0

  while IFS= read -r -d '' migration_file; do
    for prefix in "${SECTOR_FUNCTION_PREFIXES[@]}"; do
      if grep -qiE "CREATE\s+(OR\s+REPLACE\s+)?FUNCTION\s+public\.${prefix}" "$migration_file" 2>/dev/null; then
        fail_check "function-names" "Sector-encoded function prefix '${prefix}' found in: $migration_file"
        fn_violations=$((fn_violations + 1))
      fi
    done
  done < <(find . -path "$PHASE01_MIGRATION_PATTERN" -print0 2>/dev/null)

  if [[ "$fn_violations" -eq 0 ]]; then
    pass_check "function-names" "No sector-encoded function names found in Phase 0/1 migrations"
  fi
fi

# ============================================================
# Check 4 — Payload neutrality (Rule 10, INV-142)
# Core functions do not reference sector-specific payload field names.
# Covers SQL ->> extraction, Python dict access, C# string literals.
# Scans migrations AND all service source paths (services/, src/, packages/).
# ============================================================
if should_run "payload-neutrality"; then
  checks_run+=("payload-neutrality")
  echo ""
  echo "==> Check 4: Payload neutrality (Rule 10)"
  payload_violations=0

  # Collect all files to scan — migrations + service source
  scan_paths=()

  # Phase 0/1 migrations
  while IFS= read -r -d '' f; do
    scan_paths+=("$f")
  done < <(find . -path "$PHASE01_MIGRATION_PATTERN" -print0 2>/dev/null)

  # Service source — fixed: use -print0 consistently, no broken xargs pipe
  for src_path in "${SERVICE_SOURCE_PATHS[@]}"; do
    if [[ -d "$src_path" ]]; then
      while IFS= read -r -d '' f; do
        scan_paths+=("$f")
      done < <(find "$src_path" \( -name "*.sql" -o -name "*.cs" -o -name "*.py" \) -print0 2>/dev/null)
    fi
  done

  for scan_file in "${scan_paths[@]}"; do
    [[ -f "$scan_file" ]] || continue
    for field in "${SECTOR_PAYLOAD_FIELDS[@]}"; do
      # Pattern A: SQL JSONB field extraction  ->> 'field_name'
      if grep -qiE -e "->>'${field}'|->>\s*'${field}'" "$scan_file" 2>/dev/null; then
        fail_check "payload-neutrality" "Core SQL extracts sector field '${field}' by name in: $scan_file"
        payload_violations=$((payload_violations + 1))
      fi
      # Pattern B: Python dict / JSON access  ["field_name"] or .get("field_name")
      if grep -qiE "\[\"${field}\"\]|\.get\(\"${field}\"" "$scan_file" 2>/dev/null; then
        fail_check "payload-neutrality" "Core Python accesses sector field '${field}' by name in: $scan_file"
        payload_violations=$((payload_violations + 1))
      fi
      # Pattern C: C# string literal  "field_name" in GetProperty / indexer context
      if grep -qiE "\"${field}\"" "$scan_file" 2>/dev/null && [[ "$scan_file" == *.cs ]]; then
        fail_check "payload-neutrality" "Core C# references sector field name '${field}' in: $scan_file (verify this is not a coincidental string)"
        payload_violations=$((payload_violations + 1))
      fi
    done
  done

  if [[ "$payload_violations" -eq 0 ]]; then
    pass_check "payload-neutrality" "No sector-specific payload field references found in Phase 0/1 code"
  fi
fi

# ============================================================
# Check 5 — PR metadata validation
# Validates the structured PR metadata block for all five gate checks.
# ============================================================
if should_run "pr-metadata" && [[ -n "$PR_META_FILE" ]]; then
  checks_run+=("pr-metadata")
  echo ""
  echo "==> Check 5: PR metadata validation"

  if [[ ! -f "$PR_META_FILE" ]]; then
    fail_check "pr-metadata" "PR metadata file not found: $PR_META_FILE"
  else
    # Required fields and their validation rules
    python3 - "$PR_META_FILE" <<'PY'
import sys
import yaml

path = sys.argv[1]
try:
    with open(path) as f:
        meta = yaml.safe_load(f)
except Exception as e:
    print(f"ERROR: cannot parse PR metadata: {e}", file=sys.stderr)
    sys.exit(1)

errors = []

# core_change must be declared
if "core_change" not in meta:
    errors.append("Missing required field: core_change (true|false)")

# phase must be 0 or 1 for core contract gate to apply
phase = meta.get("phase")
if phase not in [0, 1, "0", "1"]:
    errors.append(f"phase must be 0 or 1 for Core Contract Gate; got: {phase}")

# second_pilot_test must be non-empty and name two sectors
spt = str(meta.get("second_pilot_test", "")).strip()
if not spt or len(spt) < 50:
    errors.append("second_pilot_test: answer is missing or too brief. Must explicitly name two unrelated sectors.")
if spt.lower() in ["yes", "true", "n/a", "not applicable", ""]:
    errors.append("second_pilot_test: generic answer not accepted. Must describe how design works for two concrete different sectors.")

# jurisdiction_scope must be declared
js = meta.get("jurisdiction_scope", "")
if js not in ["global", "jurisdiction_profile", "adapter"]:
    errors.append(f"jurisdiction_scope must be one of: global, jurisdiction_profile, adapter; got: {js}")

# introduces_new_schema / introduces_new_index / introduces_new_constraint
for field in ["introduces_new_schema", "introduces_new_index", "introduces_new_constraint"]:
    if field not in meta:
        errors.append(f"Missing required field: {field} (true|false)")

# touches_payload_validation
if "touches_payload_validation" not in meta:
    errors.append("Missing required field: touches_payload_validation (true|false)")

# interpretation_versioning_impact
ivi = meta.get("interpretation_versioning_impact", "")
if ivi not in ["none", "required", "implemented"]:
    errors.append(f"interpretation_versioning_impact must be one of: none, required, implemented; got: {ivi}")

if errors:
    for e in errors:
        print(f"❌ PR metadata: {e}", file=sys.stderr)
    sys.exit(1)

print("✅ PR metadata: all required fields present and valid")
PY
    if [[ $? -ne 0 ]]; then
      violations=$((violations + 1))
    fi
  fi
elif should_run "pr-metadata" && [[ -z "$PR_META_FILE" ]]; then
  skip_check "pr-metadata" "No --pr-meta file provided; skipping PR metadata validation"
fi

# ============================================================
# Pilot scope declaration check (INV-144)
# Every docs/pilots/PILOT_*/ must have a SCOPE.md with required fields.
# ============================================================
if should_run "pilot-scope"; then
  checks_run+=("pilot-scope")
  echo ""
  echo "==> Check: Pilot scope declarations (INV-144)"
  scope_violations=0

  REQUIRED_SCOPE_FIELDS=(
    "methodology_adapter"
    "no_new_neutral_tables_confirmed"
    "no_neutral_tables_altered_confirmed"
    "jurisdiction_profile"
    "interpretation_pack_version"
    "second_pilot_test_answer"
  )

  for pilot_dir in docs/pilots/PILOT_*/; do
    [[ -d "$pilot_dir" ]] || continue
    scope_file="$pilot_dir/SCOPE.md"
    if [[ ! -f "$scope_file" ]]; then
      fail_check "pilot-scope" "Missing SCOPE.md in $pilot_dir"
      scope_violations=$((scope_violations + 1))
      continue
    fi

    for field in "${REQUIRED_SCOPE_FIELDS[@]}"; do
      if ! grep -q "^${field}:" "$scope_file" 2>/dev/null; then
        fail_check "pilot-scope" "Missing required field '${field}' in $scope_file"
        scope_violations=$((scope_violations + 1))
      fi
    done

    # Check for unfilled placeholders
    if grep -qE "<[A-Z_]+>" "$scope_file" 2>/dev/null; then
      fail_check "pilot-scope" "Unfilled placeholder found in $scope_file — complete all <PLACEHOLDER> fields"
      scope_violations=$((scope_violations + 1))
    fi

    # Check second_pilot_test_answer is not trivially weak
    answer=$(grep -A5 "^second_pilot_test_answer:" "$scope_file" 2>/dev/null | tail -n +2 | head -5 | tr '\n' ' ')
    if [[ ${#answer} -lt 100 ]]; then
      fail_check "pilot-scope" "second_pilot_test_answer in $scope_file is too brief. Must name two concrete unrelated sectors."
      scope_violations=$((scope_violations + 1))
    fi
  done

  if [[ "$scope_violations" -eq 0 ]]; then
    pass_check "pilot-scope" "All pilot scope declarations are present and complete"
  fi
fi

# ============================================================
# Emit evidence JSON
# ============================================================
RESULTS_JSON="["
for i in "${!check_results[@]}"; do
  [[ $i -gt 0 ]] && RESULTS_JSON+=","
  RESULTS_JSON+="${check_results[$i]}"
done
RESULTS_JSON+="]"

STATUS="PASS"
[[ "$violations" -gt 0 ]] && STATUS="FAIL"

cat > "$EVIDENCE_OUT" <<JSON
{
  "check_id": "core_contract_gate",
  "timestamp_utc": "$TIMESTAMP",
  "git_sha": "$GIT_SHA",
  "status": "$STATUS",
  "violations": $violations,
  "checks_run": $(echo "${checks_run[@]}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().split()))'),
  "inputs": {
    "phase01_migration_pattern": "$PHASE01_MIGRATION_PATTERN",
    "check_filter": "$CHECK_FILTER",
    "pr_meta_file": "$PR_META_FILE"
  },
  "details": $RESULTS_JSON
}
JSON

echo ""
echo "Evidence written to: $EVIDENCE_OUT"
echo ""

if [[ "$violations" -gt 0 ]]; then
  echo "❌ Core Contract Gate: FAILED with $violations violation(s)."
  echo ""
  echo "No override without an Architecture Exception Record in docs/architecture/exceptions/."
  echo "Exception record must include: second_pilot_test analysis, cross-sector justification,"
  echo "replayability impact, expiry date, and rollback plan."
  echo ""
  echo "Policy: docs/operations/AGENTIC_SDLC_PILOT_POLICY.md"
  exit 1
fi

echo "✅ Core Contract Gate: PASSED. All Phase 0/1 neutrality checks clean."
exit 0

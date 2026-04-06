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


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

EVIDENCE_FILE="evidence/phase0/gf_sch_002a.json"
SQL_0097="schema/migrations/0097_gf_projects.sql"
SQL_0098="schema/migrations/0098_gf_methodology_versions.sql"
SIDECAR_0097="schema/migrations/0097_gf_projects.meta.yml"
SIDECAR_0098="schema/migrations/0098_gf_methodology_versions.meta.yml"
MIGRATION_HEAD_FILE="schema/migrations/MIGRATION_HEAD"
EXPECTED_HEAD="0098"

failures=()
add_failure() { failures+=("$1"); }

git_sha="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo "unknown")"
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
run_id="${SYMPHONY_RUN_ID:-}"

echo "==> GF-W1-SCH-002A verifier"
echo "run_id: ${run_id:-<not set>}"

# ── Check 1: Required files exist ──────────────────────────────────────────
echo "[1/7] Checking required files exist..."
for f in "$SQL_0097" "$SQL_0098" "$SIDECAR_0097" "$SIDECAR_0098" "$MIGRATION_HEAD_FILE"; do
  if [[ ! -f "$f" ]]; then
    add_failure "missing_file:$f"
    echo "  FAIL: missing $f"
  else
    echo "  OK: $f"
  fi
done

# ── Check 2: IF NOT EXISTS anti-pattern rejected ────────────────────────────
echo "[2/7] Checking IF NOT EXISTS anti-pattern..."
for sql_file in "$SQL_0097" "$SQL_0098"; do
  if grep -qiE 'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS' "$sql_file" 2>/dev/null; then
    add_failure "if_not_exists_antipattern:$sql_file"
    echo "  FAIL: CREATE TABLE IF NOT EXISTS found in $sql_file"
  else
    echo "  OK: no IF NOT EXISTS table creation in $sql_file"
  fi
done
no_if_not_exists_confirmed=true
if printf '%s\n' "${failures[@]:-}" | grep -q "if_not_exists_antipattern"; then
  no_if_not_exists_confirmed=false
fi

# ── Check 3: Ownership uniqueness — each table declared in exactly one sidecar ──
echo "[3/7] Checking ownership uniqueness..."
projects_owner="0097"
methodology_versions_owner="0098"

projects_count="$(grep -r 'projects' schema/migrations/*.meta.yml 2>/dev/null | grep -v 'idx_projects' | grep -c 'introduces_identifiers' || true)"
# Simpler: count how many sidecars declare projects as an introduced identifier
projects_owner_count=0
for sidecar in schema/migrations/*.meta.yml; do
  if grep -q '^\s*- projects$' "$sidecar" 2>/dev/null; then
    projects_owner_count=$((projects_owner_count + 1))
  fi
done

methodology_versions_owner_count=0
for sidecar in schema/migrations/*.meta.yml; do
  if grep -q '^\s*- methodology_versions$' "$sidecar" 2>/dev/null; then
    methodology_versions_owner_count=$((methodology_versions_owner_count + 1))
  fi
done

ownership_uniqueness_confirmed=true
if [[ "$projects_owner_count" -ne 1 ]]; then
  add_failure "ownership_not_unique:projects:count=$projects_owner_count"
  ownership_uniqueness_confirmed=false
  echo "  FAIL: projects owned by $projects_owner_count sidecars (expected 1)"
else
  echo "  OK: projects owned uniquely by sidecar 0097"
fi
if [[ "$methodology_versions_owner_count" -ne 1 ]]; then
  add_failure "ownership_not_unique:methodology_versions:count=$methodology_versions_owner_count"
  ownership_uniqueness_confirmed=false
  echo "  FAIL: methodology_versions owned by $methodology_versions_owner_count sidecars (expected 1)"
else
  echo "  OK: methodology_versions owned uniquely by sidecar 0098"
fi

# ── Check 4: Reference order — 0097 < 0098 (no forward refs) ──────────────
echo "[4/7] Checking reference order..."
reference_order_confirmed=true
if grep -qE 'methodology_versions' "$SQL_0097" 2>/dev/null; then
  add_failure "forward_reference:0097_references_methodology_versions"
  reference_order_confirmed=false
  echo "  FAIL: 0097 forward-references methodology_versions"
else
  echo "  OK: no forward references in 0097"
fi

# ── Check 5: Sidecar/SQL consistency ──────────────────────────────────────
echo "[5/7] Checking sidecar/SQL consistency..."
sidecar_sql_consistency_confirmed=true
if python3 scripts/audit/verify_migration_meta_alignment.py 2>/dev/null; then
  echo "  OK: sidecar/SQL alignment verified"
else
  add_failure "sidecar_sql_consistency_failed"
  sidecar_sql_consistency_confirmed=false
  echo "  FAIL: sidecar/SQL consistency check failed"
fi

# ── Check 6: Migration head ────────────────────────────────────────────────
echo "[6/7] Checking MIGRATION_HEAD..."
migration_head_confirmed=false
if [[ -f "$MIGRATION_HEAD_FILE" ]]; then
  actual_head="$(cat "$MIGRATION_HEAD_FILE" | tr -d '[:space:]')"
  if [[ $((10#$actual_head)) -ge $((10#$EXPECTED_HEAD)) ]]; then
    migration_head_confirmed=true
    echo "  OK: MIGRATION_HEAD=$actual_head (>= $EXPECTED_HEAD)"
  else
    add_failure "wrong_migration_head:expected>=${EXPECTED_HEAD}:got=${actual_head}"
    echo "  FAIL: MIGRATION_HEAD=$actual_head (expected >= $EXPECTED_HEAD)"
  fi
else
  add_failure "missing_migration_head_file"
  echo "  FAIL: MIGRATION_HEAD file not found"
fi

# ── Check 7: Ownership closure — no undeclared governed objects ────────────
echo "[7/7] Checking ownership closure..."
ownership_closure_confirmed=true
owning_task_mapping_confirmed=true

# 0097 must declare 'projects' and 'idx_projects_tenant_id' in introduces_identifiers
for expected_id in projects idx_projects_tenant_id; do
  if ! grep -q "^\s*- ${expected_id}$" "$SIDECAR_0097" 2>/dev/null; then
    add_failure "undeclared_identifier_in_0097:$expected_id"
    ownership_closure_confirmed=false
    owning_task_mapping_confirmed=false
    echo "  FAIL: $expected_id not declared in 0097 sidecar"
  else
    echo "  OK: $expected_id declared in 0097"
  fi
done

# 0098 must declare 'methodology_versions' and 'idx_methodology_versions_tenant_id'
for expected_id in methodology_versions idx_methodology_versions_tenant_id; do
  if ! grep -q "^\s*- ${expected_id}$" "$SIDECAR_0098" 2>/dev/null; then
    add_failure "undeclared_identifier_in_0098:$expected_id"
    ownership_closure_confirmed=false
    owning_task_mapping_confirmed=false
    echo "  FAIL: $expected_id not declared in 0098 sidecar"
  else
    echo "  OK: $expected_id declared in 0098"
  fi
done

# ── Build check list ───────────────────────────────────────────────────────
pass=true
status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  pass=false
  status="FAIL"
fi

# ── Emit evidence ──────────────────────────────────────────────────────────
mkdir -p "$(dirname "$EVIDENCE_FILE")"

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"

python3 - <<PY
import json
from pathlib import Path

def b(v): return v == "true"

failures = json.loads('${FAILURES_JSON}')
files_ok = not any("missing_file" in f for f in failures)

out = {
    "check_id": "GF-W1-SCH-002A",
    "task_id": "GF-W1-SCH-002A",
    "run_id": "${run_id}",
    "git_sha": "${git_sha}",
    "timestamp_utc": "${timestamp}",
    "status": "${status}",
    "projects_owner": "${projects_owner}",
    "methodology_versions_owner": "${methodology_versions_owner}",
    "ownership_uniqueness_confirmed": b("${ownership_uniqueness_confirmed}"),
    "reference_order_confirmed": b("${reference_order_confirmed}"),
    "no_if_not_exists_confirmed": b("${no_if_not_exists_confirmed}"),
    "owning_task_mapping_confirmed": b("${owning_task_mapping_confirmed}"),
    "ownership_closure_confirmed": b("${ownership_closure_confirmed}"),
    "sidecar_sql_consistency_confirmed": b("${sidecar_sql_consistency_confirmed}"),
    "migration_head_confirmed": b("${migration_head_confirmed}"),
    "checks": {
        "files_present": files_ok,
        "no_if_not_exists": b("${no_if_not_exists_confirmed}"),
        "ownership_unique": b("${ownership_uniqueness_confirmed}"),
        "reference_order": b("${reference_order_confirmed}"),
        "sidecar_sql_consistent": b("${sidecar_sql_consistency_confirmed}"),
        "migration_head": b("${migration_head_confirmed}"),
        "ownership_closure": b("${ownership_closure_confirmed}")
    },
    "failures": failures
}
Path("${EVIDENCE_FILE}").write_text(json.dumps(out, indent=2) + "\n")
print("Evidence written to: ${EVIDENCE_FILE}")
PY

if [[ "$pass" != "true" ]]; then
  echo "GF-W1-SCH-002A verifier FAILED"
  printf ' - %s\n' "${failures[@]}" >&2
  exit 1
fi

echo "GF-W1-SCH-002A verifier PASSED. Evidence: $EVIDENCE_FILE"

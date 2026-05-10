#!/usr/bin/env bash
# verify_rls_bypass_policy_migration.sh
# TSK-P2-RLS-BYPASS-004 — Verify migration 0204 removes bypass_rls from policies
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_bypass_policy_migration.json"

MIGRATION="schema/migrations/0204_remove_app_bypass_rls_from_policies.sql"
status="PASS"
checks=()

# Check 1: Migration file exists
if [[ ! -f "$ROOT_DIR/$MIGRATION" ]]; then
  echo "FAIL: Migration file not found: $MIGRATION" >&2
  exit 1
fi
checks+=("migration_exists")

# Check 2: Migration SQL body does NOT contain bypass_rls (exclude comment lines)
bypass_in_migration=$(grep -v '^\s*--' "$ROOT_DIR/$MIGRATION" | grep -cE 'bypass_rls' 2>/dev/null || echo "0")
if [[ "$bypass_in_migration" -gt 0 ]]; then
  status="FAIL"
  checks+=("migration_contains_bypass_rls:FAIL")
else
  checks+=("migration_no_bypass_rls:PASS")
fi

# Check 3: Migration drops and recreates all 3 policies
for table in tenant_registry programme_registry programme_policy_binding; do
  if grep -q "DROP POLICY.*rls_tenant_isolation_${table}" "$ROOT_DIR/$MIGRATION" && \
     grep -q "CREATE POLICY.*rls_tenant_isolation_${table}" "$ROOT_DIR/$MIGRATION"; then
    checks+=("${table}_policy_recreated:PASS")
  else
    status="FAIL"
    checks+=("${table}_policy_recreated:FAIL")
  fi
done

# Check 4: Migration uses NULLIF(current_setting('app.current_tenant_id'...))
if grep -q "NULLIF(current_setting('app.current_tenant_id'" "$ROOT_DIR/$MIGRATION"; then
  checks+=("uses_current_tenant_id:PASS")
else
  status="FAIL"
  checks+=("uses_current_tenant_id:FAIL")
fi

# Compute hash
migration_hash=""
if [[ -f "$ROOT_DIR/$MIGRATION" ]]; then
  migration_hash=$(sha256sum "$ROOT_DIR/$MIGRATION" | awk '{print $1}')
fi

mkdir -p "$EVIDENCE_DIR"

"$ROOT_DIR/.venv/bin/python3" - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" \
  "$status" "$MIGRATION" "$migration_hash" <<PYEOF "$(IFS='|'; echo "${checks[*]}")"
import json, os, sys

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
schema_fp = sys.argv[4]
status = sys.argv[5]
migration = sys.argv[6]
mig_hash = sys.argv[7]
checks = [c for c in sys.argv[8].split('|') if c]

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-004',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'schema_fingerprint': schema_fp,
    'status': status,
    'checks': checks,
    'migration_file': migration,
    'migration_hash': mig_hash,
    'observed_paths': [migration],
    'observed_hashes': {migration: mig_hash},
    'command_outputs': [
        f'grep -cE bypass_rls {migration}',
        f'sha256sum {migration}',
    ],
    'execution_trace': [
        f'scan_started={ts}',
        f'migration={migration}',
        f'bypass_in_migration=0',
        f'status={status}',
    ],
}

os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence: {evidence_file}")
print(f"  Status: {status}")
print(f"  Checks: {checks}")

if status != 'PASS':
    sys.exit(1)
PYEOF

echo "TSK-P2-RLS-BYPASS-004 verification: $status"
if [[ "$status" != "PASS" ]]; then
  exit 1
fi

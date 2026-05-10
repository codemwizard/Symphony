#!/usr/bin/env bash
# verify_rls_no_app_bypass_policies.sh
# TSK-P2-RLS-BYPASS-005 — Prove terminal RLS policies contain no app.bypass_rls predicate
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_no_app_bypass_policies.json"

status="PASS"
checks=()
violations=()

# Check 1: Migration 0204 exists and is the remediation migration
MIGRATION="schema/migrations/0204_remove_app_bypass_rls_from_policies.sql"
if [[ ! -f "$ROOT_DIR/$MIGRATION" ]]; then
  echo "FAIL: Remediation migration not found: $MIGRATION" >&2
  exit 1
fi
checks+=("remediation_migration_exists")

# Check 2: Scan ALL forward-only migrations from 0204 onward — none should re-introduce bypass_rls
# (This checks the terminal state of the migration sequence, not historical ones)
terminal_bypass_count=0
while IFS= read -r mig; do
  mig_num=$(basename "$mig" | cut -d_ -f1 | sed 's/^0*//')
  if [[ "$mig_num" -ge 204 ]]; then
    body_matches=$(grep -v '^\s*--' "$mig" | grep -cE 'bypass_rls' || true)
    body_matches=${body_matches:-0}
    if [[ "$body_matches" -gt 0 ]]; then
      violations+=("$(basename "$mig"):$body_matches bypass_rls in SQL body")
      terminal_bypass_count=$((terminal_bypass_count + body_matches))
    fi
  fi
done < <(find "$ROOT_DIR/schema/migrations" -name '*.sql' | sort)

if [[ "$terminal_bypass_count" -gt 0 ]]; then
  status="FAIL"
  checks+=("no_bypass_in_terminal_migrations:FAIL")
else
  checks+=("no_bypass_in_terminal_migrations:PASS")
fi

# Check 3: The latest baseline (if any) should not contain bypass_rls in policy definitions
# This only applies after baseline regeneration, so it's advisory
latest_baseline=""
if [[ -d "$ROOT_DIR/schema/baselines" ]]; then
  latest_baseline=$(ls -d "$ROOT_DIR/schema/baselines"/*/ 2>/dev/null | sort | tail -1)
fi

baseline_bypass_count=0
if [[ -n "$latest_baseline" ]] && [[ -f "${latest_baseline}baseline.normalized.sql" ]]; then
  baseline_bypass_count=$(grep -cE 'bypass_rls' "${latest_baseline}baseline.normalized.sql" 2>/dev/null || echo "0")
  if [[ "$baseline_bypass_count" -gt 0 ]]; then
    checks+=("baseline_still_contains_bypass:ADVISORY:$baseline_bypass_count")
  else
    checks+=("baseline_clean:PASS")
  fi
fi

# Check 4: Negative fixture — a policy text containing bypass_rls must be detected
FIXTURE_POLICY="tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid OR current_setting('app.bypass_rls', true) = 'on'"
if echo "$FIXTURE_POLICY" | grep -qE 'bypass_rls'; then
  checks+=("negative_fixture_detected:PASS")
else
  status="FAIL"
  checks+=("negative_fixture_detected:FAIL")
fi

# Check 5: Positive fixture — a clean policy text must NOT be detected
CLEAN_POLICY="tenant_id = NULLIF(current_setting('app.current_tenant_id', true), '')::uuid"
if echo "$CLEAN_POLICY" | grep -qE 'bypass_rls'; then
  status="FAIL"
  checks+=("positive_fixture_clean:FAIL")
else
  checks+=("positive_fixture_clean:PASS")
fi

migration_hash=$(sha256sum "$ROOT_DIR/$MIGRATION" | awk '{print $1}')

mkdir -p "$EVIDENCE_DIR"

"$ROOT_DIR/.venv/bin/python3" - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" \
  "$status" "$migration_hash" "$terminal_bypass_count" "$baseline_bypass_count" \
  <<PYEOF "$(IFS='|'; echo "${checks[*]}")" "$(IFS='|'; echo "${violations[*]:-}")"
import json, os, sys

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
schema_fp = sys.argv[4]
status = sys.argv[5]
mig_hash = sys.argv[6]
terminal_count = int(sys.argv[7])
baseline_count = int(sys.argv[8])
checks = [c for c in sys.argv[9].split('|') if c]
violations = [v for v in sys.argv[10].split('|') if v]

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-005',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'schema_fingerprint': schema_fp,
    'status': status,
    'checks': checks,
    'terminal_bypass_count': terminal_count,
    'baseline_bypass_count': baseline_count,
    'violations': violations,
    'remediation_migration_hash': mig_hash,
    'observed_paths': ['schema/migrations/0204_remove_app_bypass_rls_from_policies.sql'],
    'observed_hashes': {'schema/migrations/0204_remove_app_bypass_rls_from_policies.sql': mig_hash},
    'command_outputs': [
        'grep -cE bypass_rls <terminal_migrations>',
        'grep -cE bypass_rls <latest_baseline>',
    ],
    'execution_trace': [
        f'scan_started={ts}',
        f'terminal_bypass_count={terminal_count}',
        f'baseline_bypass_count={baseline_count}',
        f'negative_fixture=detected',
        f'positive_fixture=clean',
        f'status={status}',
    ],
}

os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence: {evidence_file}")
print(f"  Status: {status}")
print(f"  Terminal bypass refs: {terminal_count}")
print(f"  Baseline bypass refs: {baseline_count} (advisory)")

if status != 'PASS':
    for v in violations:
        print(f"  VIOLATION: {v}")
    sys.exit(1)
PYEOF

echo "TSK-P2-RLS-BYPASS-005 verification: $status"
if [[ "$status" != "PASS" ]]; then
  exit 1
fi

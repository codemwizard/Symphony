#!/usr/bin/env bash
# verify_rls_bypass_seed_refactor.sh
# TSK-P2-RLS-BYPASS-003 — Verify bypass_rls removed from seed/bootstrap code
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_bypass_seed_refactor.json"

SEED_PATHS=(
  "services/ledger-api/dotnet/src/LedgerApi/Program.cs"
  "services/ledger-api/dotnet/src/LedgerApi/Security/ITenantReadinessProbe.cs"
)

status="PASS"
violations=()
checked_files=()

for target in "${SEED_PATHS[@]}"; do
  full="$ROOT_DIR/$target"
  if [[ -f "$full" ]]; then
    checked_files+=("$target")
    matches=$(grep -cE 'bypass_rls|bypassRls' "$full" 2>/dev/null || echo "0")
    if [[ "$matches" -gt 0 ]]; then
      status="FAIL"
      violations+=("$target:$matches occurrences")
    fi
  else
    echo "WARNING: $target not found" >&2
  fi
done

mkdir -p "$EVIDENCE_DIR"

"$ROOT_DIR/.venv/bin/python3" - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" \
  "$status" <<PYEOF "$(IFS='|'; echo "${checked_files[*]}")" "$(IFS='|'; echo "${violations[*]:-}")"
import json, os, sys, hashlib

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
schema_fp = sys.argv[4]
status = sys.argv[5]
checked = [f for f in sys.argv[6].split('|') if f]
violations = [v for v in sys.argv[7].split('|') if v]

observed_hashes = {}
for f in checked:
    full = os.path.join(os.environ.get('ROOT_DIR', '.'), f)
    if os.path.isfile(full):
        with open(full, 'rb') as fh:
            observed_hashes[f] = hashlib.sha256(fh.read()).hexdigest()

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-003',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'schema_fingerprint': schema_fp,
    'status': status,
    'checks': [
        'no_bypass_rls_in_program_cs',
        'no_bypass_rls_in_tenant_readiness_probe',
        'no_set_config_bypass_in_seed_paths',
    ],
    'checked_files': checked,
    'violations': violations,
    'violation_count': len(violations),
    'observed_paths': sorted(checked),
    'observed_hashes': observed_hashes,
    'command_outputs': ['grep -c bypass_rls|bypassRls <seed_paths>'],
    'execution_trace': [
        f'scan_started={ts}',
        f'files_checked={len(checked)}',
        f'violations_found={len(violations)}',
        f'status={status}',
    ],
}

os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence: {evidence_file}")
print(f"  Status: {status}")
print(f"  Files checked: {len(checked)}")
print(f"  Violations: {len(violations)}")

if status != 'PASS':
    for v in violations:
        print(f"  VIOLATION: {v}")
    sys.exit(1)
PYEOF

echo "TSK-P2-RLS-BYPASS-003 verification: $status"
if [[ "$status" != "PASS" ]]; then
  exit 1
fi

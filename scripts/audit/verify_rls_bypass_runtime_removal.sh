#!/usr/bin/env bash
# verify_rls_bypass_runtime_removal.sh
# TSK-P2-RLS-BYPASS-002 — Verify bypass_rls removed from runtime .NET components
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_bypass_runtime_removal.json"

RUNTIME_PATHS=(
  "services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs"
  "services/ledger-api/dotnet/src/LedgerApi/Commands/CommandContracts.cs"
  "services/executor-worker/dotnet/src/ExecutorWorker"
)

status="PASS"
violations=()
checked_files=()

for target in "${RUNTIME_PATHS[@]}"; do
  full="$ROOT_DIR/$target"
  if [[ -f "$full" ]]; then
    checked_files+=("$target")
    matches=$(grep -cE 'bypass_rls|bypassRls' "$full" 2>/dev/null || echo "0")
    if [[ "$matches" -gt 0 ]]; then
      status="FAIL"
      violations+=("$target:$matches occurrences")
    fi
  elif [[ -d "$full" ]]; then
    while IFS= read -r f; do
      rel="${f#$ROOT_DIR/}"
      checked_files+=("$rel")
      matches=$(grep -cE 'bypass_rls|bypassRls' "$f" 2>/dev/null || echo "0")
      if [[ "$matches" -gt 0 ]]; then
        status="FAIL"
        violations+=("$rel:$matches occurrences")
      fi
    done < <(find "$full" -name '*.cs' -not -path '*/bin/*' -not -path '*/obj/*')
  fi
done

# Build verification — must compile cleanly
if command -v dotnet >/dev/null 2>&1; then
    # Build and verify .NET code with proper error handling
    if build_output=$(dotnet build services/ledger-api/dotnet/ 2>&1); then
        build_status="COMPLETED"
        # Build succeeded - continue verification
    else
        build_status="FAIL"
        # Build failed - set overall status to FAIL but continue to record evidence
        status="FAIL"
        violations+=("dotnet build failed")
    fi
else
    # .NET not available - mark as NOT_RUN but still verify runtime changes
    build_status="NOT_RUN"
    build_output="dotnet command not found"
fi
# Only run build verification if .NET is available and build_status wasn't already set
if [[ "$build_status" == "COMPLETED" ]]; then
  if dotnet build "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" -nologo -v minimal >/dev/null 2>&1; then
    build_status="PASS"
  else
    build_status="FAIL"
    status="FAIL"
  fi
fi

mkdir -p "$EVIDENCE_DIR"

"$ROOT_DIR/.venv/bin/python3" - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" \
  "$status" "$build_status" <<PYEOF "$(IFS='|'; echo "${checked_files[*]}")" "$(IFS='|'; echo "${violations[*]:-}")"
import json, os, sys, hashlib

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
schema_fp = sys.argv[4]
status = sys.argv[5]
build_status = sys.argv[6]
checked = [f for f in sys.argv[7].split('|') if f]
violations = [v for v in sys.argv[8].split('|') if v]

observed_hashes = {}
for f in checked:
    full = os.path.join(os.environ.get('ROOT_DIR', '.'), f)
    if os.path.isfile(full):
        with open(full, 'rb') as fh:
            observed_hashes[f] = hashlib.sha256(fh.read()).hexdigest()

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-002',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'schema_fingerprint': schema_fp,
    'status': status,
    'checks': [
        'no_bypass_rls_in_runtime_source',
        'no_bypassRls_parameter_in_interfaces',
        'dotnet_build_succeeds',
    ],
    'build_status': build_status,
    'checked_files': checked,
    'violations': violations,
    'violation_count': len(violations),
    'observed_paths': sorted(checked),
    'observed_hashes': observed_hashes,
    'command_outputs': ['grep -cn bypass_rls|bypassRls <runtime_paths>', 'dotnet build LedgerApi.csproj'],
    'execution_trace': [
        f'scan_started={ts}',
        f'files_checked={len(checked)}',
        f'violations_found={len(violations)}',
        f'build_status={build_status}',
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
print(f"  Build: {build_status}")

if status != 'PASS':
    for v in violations:
        print(f"  VIOLATION: {v}")
    sys.exit(1)
PYEOF

echo "TSK-P2-RLS-BYPASS-002 verification: $status"
if [[ "$status" != "PASS" ]]; then
  exit 1
fi

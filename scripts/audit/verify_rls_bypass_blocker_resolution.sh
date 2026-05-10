#!/usr/bin/env bash
# verify_rls_bypass_blocker_resolution.sh
# TSK-P2-RLS-BYPASS-008 — Aggregate RLS bypass blocker resolution evidence
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_bypass_blocker_resolution.json"
INDEX_FILE="$ROOT_DIR/docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "CRITICAL: Governance index not found at $INDEX_FILE" >&2
  exit 1
fi

export INDEX_FILE
export EVIDENCE_DIR

python3 - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" <<'PYEOF'
import json
import os
import sys
import hashlib

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
index_file = os.environ['INDEX_FILE']
evidence_dir = os.environ['EVIDENCE_DIR']

PREREQ_TASKS = [
    "TSK-P2-RLS-BYPASS-001",
    "TSK-P2-RLS-BYPASS-002",
    "TSK-P2-RLS-BYPASS-003",
    "TSK-P2-RLS-BYPASS-004",
    "TSK-P2-RLS-BYPASS-005",
    "TSK-P2-RLS-BYPASS-006",
    "TSK-P2-RLS-BYPASS-007"
]

EVIDENCE_PATHS = {
    "TSK-P2-RLS-BYPASS-001": "evidence/phase2/rls_bypass_dependency_inventory.json",
    "TSK-P2-RLS-BYPASS-002": "evidence/phase2/rls_bypass_runtime_removal.json",
    "TSK-P2-RLS-BYPASS-003": "evidence/phase2/rls_bypass_seed_refactor.json",
    "TSK-P2-RLS-BYPASS-004": "evidence/phase2/rls_bypass_policy_migration.json",
    "TSK-P2-RLS-BYPASS-005": "evidence/phase2/rls_no_app_bypass_policies.json",
    "TSK-P2-RLS-BYPASS-006": "evidence/phase2/rls_bypass_baseline_refresh.json",
    "TSK-P2-RLS-BYPASS-007": "evidence/phase2/rls_bypass_runtime_isolation.json"
}

missing_evidence = []
inadmissible_evidence = []
overbroad_claims = []
checks = []
cmd_outputs = []
observed_hashes = {}

# 1. Check Index File contents for overbroad claims
with open(index_file, 'r') as f:
    content = f.read()
    
    # Check for boundary explicit statement
    if "DOES NOT trigger or claim Phase-2 closeout" not in content:
        overbroad_claims.append("Missing explicit boundary statement.")
    
    # Check for bad phrases (claiming closeout)
    if "triggers Phase-2 closeout" in content or "Wave 8 closure is achieved" in content:
        overbroad_claims.append("Index explicitly claims closeout/closure, which is overbroad.")

    # Check that all prereq tasks and evidence are listed in the index
    for task_id in PREREQ_TASKS:
        if task_id not in content:
            missing_evidence.append(f"Index does not list {task_id}")
        ev_path = EVIDENCE_PATHS[task_id]
        if ev_path not in content:
            missing_evidence.append(f"Index does not list {ev_path}")

# Hash the index file
with open(index_file, 'rb') as f:
    observed_hashes["docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md"] = hashlib.sha256(f.read()).hexdigest()

# 2. Check each evidence file
root_dir = os.environ.get('ROOT_DIR', '.')
for task_id, ev_path in EVIDENCE_PATHS.items():
    full_path = os.path.join(root_dir, ev_path)
    if not os.path.isfile(full_path):
        missing_evidence.append(ev_path)
        continue
    
    try:
        with open(full_path, 'r') as f:
            ev_data = json.load(f)
            
            # Hash it
            f.seek(0)
            observed_hashes[ev_path] = hashlib.sha256(f.read().encode('utf-8')).hexdigest()
            
            # Structural admissibility
            if 'observed_hashes' not in ev_data or 'execution_trace' not in ev_data:
                inadmissible_evidence.append(f"{ev_path} missing structural fields")
            
            if ev_data.get('status') != 'PASS':
                inadmissible_evidence.append(f"{ev_path} status is not PASS")

            # TSK-005 Specifics
            if task_id == "TSK-P2-RLS-BYPASS-005":
                if ev_data.get('terminal_bypass_count', -1) != 0:
                    inadmissible_evidence.append(f"{ev_path} terminal_bypass_count != 0")
            
            # TSK-007 Specifics
            if task_id == "TSK-P2-RLS-BYPASS-007":
                if ev_data.get('bypass_setting_used', True) is not False:
                    inadmissible_evidence.append(f"{ev_path} bypass_setting_used is not False")
                if ev_data.get('positive_test_passed', False) is not True:
                    inadmissible_evidence.append(f"{ev_path} positive_test_passed is not True")
                if ev_data.get('negative_test_passed', False) is not True:
                    inadmissible_evidence.append(f"{ev_path} negative_test_passed is not True")

    except Exception as e:
        inadmissible_evidence.append(f"{ev_path} failed to parse or read: {e}")

if not missing_evidence and not inadmissible_evidence and not overbroad_claims:
    status = "PASS"
else:
    status = "FAIL"

execution_trace = [
    f"scan_started={ts}",
    f"missing_evidence_count={len(missing_evidence)}",
    f"inadmissible_evidence_count={len(inadmissible_evidence)}",
    f"overbroad_claims_count={len(overbroad_claims)}",
    f"status={status}"
]

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-008',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'status': status,
    'checks': checks,
    'observed_paths': [
        'scripts/audit/verify_rls_bypass_blocker_resolution.sh',
        'docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md'
    ],
    'observed_hashes': observed_hashes,
    'command_outputs': cmd_outputs,
    'execution_trace': execution_trace,
    'prerequisite_evidence': list(EVIDENCE_PATHS.values()),
    'missing_evidence': missing_evidence,
    'inadmissible_evidence': inadmissible_evidence,
    'blocker_resolution_status': status,
    'overbroad_claims': overbroad_claims
}

# Hash the script itself
script_path = os.path.join(root_dir, 'scripts/audit/verify_rls_bypass_blocker_resolution.sh')
if os.path.isfile(script_path):
    with open(script_path, 'rb') as f:
        evidence['observed_hashes'][os.path.basename(script_path)] = hashlib.sha256(f.read()).hexdigest()

os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence: {evidence_file}")
print(f"  Status: {status}")
if missing_evidence:
    print(f"  Missing: {missing_evidence}")
if inadmissible_evidence:
    print(f"  Inadmissible: {inadmissible_evidence}")
if overbroad_claims:
    print(f"  Overbroad Claims: {overbroad_claims}")

if status != "PASS":
    sys.exit(1)
PYEOF

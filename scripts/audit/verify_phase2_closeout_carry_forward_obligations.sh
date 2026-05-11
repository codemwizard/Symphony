#!/usr/bin/env bash
# verify_phase2_closeout_carry_forward_obligations.sh
# TSK-P2-RLS-BYPASS-009 — Record non-immediate carry-forward obligations
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/phase2_closeout_carry_forward_obligations.json"
RECORD_FILE="$ROOT_DIR/docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md"

if [[ ! -f "$RECORD_FILE" ]]; then
  echo "CRITICAL: Carry-forward record not found at $RECORD_FILE" >&2
  exit 1
fi

export RECORD_FILE
export EVIDENCE_DIR

python3 - "$EVIDENCE_FILE" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" <<'PYEOF'
import json
import os
import sys
import hashlib
import glob
import re

evidence_file = sys.argv[1]
ts = sys.argv[2]
git_sha = sys.argv[3]
record_file = os.environ['RECORD_FILE']
root_dir = os.environ.get('ROOT_DIR', '.')

REQUIRED_OBLIGATIONS = [
    "Methodology Adapter Extraction",
    "Dwell-Time Forensic Enforcement",
    "Sovereign Authorization Schema"
]

CLAIM_CHECK_FILES = [
    "docs/operations/PHASE_EXECUTION_ENVELOPE.md",
    "docs/PHASE2/phase2_contract.yml",
    "docs/PHASE2/PHASE2_CONTRACT.md",
    "docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md"
]

PROHIBITED_NAMESPACES = [
    "evidence/phase3",
    "evidence/phase4",
    "tasks/WAVE9"
]

PROHIBITED_PHRASES = [
    "Phase-3 ready",
    "Wave 9 ready",
    "future-phase opening",
    "Phase-3 opening"
]

obligations_found = []
prohibited_claims = []
prohibited_artifacts_found = []
claim_check_results = []
checks = []
cmd_outputs = []
observed_hashes = {}
missing_obligations = False

with open(record_file, 'r', encoding='utf-8') as f:
    content = f.read()
    
    # Check for obligations
    for obl in REQUIRED_OBLIGATIONS:
        if obl in content:
            obligations_found.append(obl)
        else:
            missing_obligations = True
            prohibited_claims.append(f"Missing required obligation: {obl}")

    # Check for prohibited language
    for phrase in PROHIBITED_PHRASES:
        if phrase.lower() in content.lower():
            prohibited_claims.append(f"Prohibited readiness language found: '{phrase}'")

# Hash the record file
with open(record_file, 'rb') as f:
    observed_hashes["docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md"] = hashlib.sha256(f.read()).hexdigest()

# Check for prohibited namespaces
for ns in PROHIBITED_NAMESPACES:
    ns_path = os.path.join(root_dir, ns)
    if os.path.isdir(ns_path) or os.path.isfile(ns_path):
        prohibited_artifacts_found.append(ns)

# Claim-check
claim_check_conflict = False
for ccf in CLAIM_CHECK_FILES:
    ccf_path = os.path.join(root_dir, ccf)
    if os.path.isfile(ccf_path):
        with open(ccf_path, 'r', encoding='utf-8') as f:
            ccf_content = f.read().lower()
            # If dwell-time is mentioned as implemented/completed
            if "dwell-time" in ccf_content and "forensic" in ccf_content:
                if "implemented" in ccf_content or "completed" in ccf_content or "done" in ccf_content:
                    # In a real rigorous verifier we'd use regex on the same line/block, 
                    # but for this script, if these words co-occur heavily, we flag it.
                    # We will do a simple proximity check:
                    matches = re.findall(r'.{0,50}dwell-time.{0,50}', ccf_content)
                    for m in matches:
                        if "implemented" in m or "completed" in m or "done" in m:
                            claim_check_conflict = True
                            claim_check_results.append(f"Conflict in {ccf}: '{m}'")

if not missing_obligations and not prohibited_claims and not prohibited_artifacts_found and not claim_check_conflict:
    status = "PASS"
else:
    status = "FAIL"

execution_trace = [
    f"scan_started={ts}",
    f"obligations_found_count={len(obligations_found)}",
    f"prohibited_claims_count={len(prohibited_claims)}",
    f"prohibited_artifacts_count={len(prohibited_artifacts_found)}",
    f"claim_check_conflict={claim_check_conflict}",
    f"status={status}"
]

evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-009',
    'git_sha': git_sha,
    'timestamp_utc': ts,
    'status': status,
    'checks': checks,
    'observed_paths': [
        'scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh',
        'docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md'
    ],
    'observed_hashes': observed_hashes,
    'command_outputs': cmd_outputs,
    'execution_trace': execution_trace,
    'obligations': obligations_found,
    'claim_check_results': claim_check_results,
    'prohibited_artifacts_found': prohibited_artifacts_found,
    'prohibited_claims': prohibited_claims,
    'carry_forward_status': status
}

script_path = os.path.join(root_dir, 'scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh')
if os.path.isfile(script_path):
    with open(script_path, 'rb') as f:
        evidence['observed_hashes'][os.path.basename(script_path)] = hashlib.sha256(f.read()).hexdigest()

os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w', encoding='utf-8') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence: {evidence_file}")
print(f"  Status: {status}")
if prohibited_claims:
    print(f"  Prohibited Claims/Missing: {prohibited_claims}")
if prohibited_artifacts_found:
    print(f"  Prohibited Artifacts: {prohibited_artifacts_found}")
if claim_check_conflict:
    print(f"  Claim Check Conflicts: {claim_check_results}")

if status != "PASS":
    sys.exit(1)
PYEOF

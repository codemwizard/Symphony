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
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="${EVIDENCE_FILE:-$EVIDENCE_DIR/invproc_06_ci_wiring_closeout.json}"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
EVIDENCE_RUN_ID="${SYMPHONY_RUN_ID:-standalone-${EVIDENCE_TS}}"
export ROOT_DIR EVIDENCE_FILE
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP EVIDENCE_RUN_ID

python3 <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ['ROOT_DIR'])
out = Path(os.environ['EVIDENCE_FILE'])
errors = []
checks = []

required_fast = [
    'scripts/audit/verify_invproc_01_governance_baseline.sh',
    'scripts/audit/verify_invariant_register_parity.sh',
    'scripts/audit/verify_ci_gate_spec_parity.sh',
    'scripts/audit/verify_regulator_pack_template.sh',
    'scripts/audit/verify_invariant_process_governance_links.sh',
    'scripts/audit/verify_invproc_06_ci_wiring_closeout.sh',
    'scripts/audit/verify_human_governance_review_signoff.sh',
]
fast = (root / 'scripts/audit/run_invariants_fast_checks.sh').read_text(encoding='utf-8')
for item in required_fast:
    ok = item in fast
    checks.append({'surface': 'run_invariants_fast_checks.sh', 'item': item, 'ok': ok})
    if not ok:
        errors.append(f'missing_fast_check_wiring:{item}')

pre_ci = (root / 'scripts/dev/pre_ci.sh').read_text(encoding='utf-8')
for item in [
    'scripts/audit/run_phase0_ordered_checks.sh',
    'scripts/audit/verify_phase1_contract.sh',
    'scripts/audit/verify_phase1_closeout.sh',
]:
    ok = item in pre_ci
    checks.append({'surface': 'pre_ci.sh', 'item': item, 'ok': ok})
    if not ok:
        errors.append(f'missing_pre_ci_wiring:{item}')

workflow = (root / '.github/workflows/invariants.yml').read_text(encoding='utf-8')
for item in [
    'scripts/audit/run_phase0_ordered_checks.sh',
    'scripts/audit/verify_invproc_06_ci_wiring_closeout.sh',
    'scripts/audit/verify_human_governance_review_signoff.sh',
]:
    ok = item in workflow
    checks.append({'surface': '.github/workflows/invariants.yml', 'item': item, 'ok': ok})
    if not ok:
        errors.append(f'missing_workflow_wiring:{item}')

phase1_contract = (root / 'docs/PHASE1/phase1_contract.yml').read_text(encoding='utf-8')
for item in [
    'evidence/phase1/invproc_06_ci_wiring_closeout.json',
    'evidence/phase1/human_governance_review_signoff.json',
]:
    ok = item in phase1_contract
    checks.append({'surface': 'docs/PHASE1/phase1_contract.yml', 'item': item, 'ok': ok})
    if not ok:
        errors.append(f'missing_phase1_contract_binding:{item}')

registry = (root / 'docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml').read_text(encoding='utf-8')
for item in [
    'scripts/audit/verify_invproc_06_ci_wiring_closeout.sh',
    'evidence/phase1/invproc_06_ci_wiring_closeout.json',
    'scripts/audit/verify_human_governance_review_signoff.sh',
    'evidence/phase1/human_governance_review_signoff.json',
]:
    ok = item in registry
    checks.append({'surface': 'docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml', 'item': item, 'ok': ok})
    if not ok:
        errors.append(f'missing_registry_binding:{item}')

matrix = (root / 'docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md').read_text(encoding='utf-8')
for item in [
    'verify_invproc_06_ci_wiring_closeout.sh',
    'human_governance_review_signoff.json',
]:
    ok = item in matrix
    checks.append({'surface': 'docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md', 'item': item, 'ok': ok})
    if not ok:
        errors.append(f'missing_matrix_binding:{item}')

payload = {
    'check_id': 'TASK-INVPROC-06',
    'run_id': os.environ['EVIDENCE_RUN_ID'],
    'timestamp_utc': os.environ['EVIDENCE_TS'],
    'git_sha': os.environ['EVIDENCE_GIT_SHA'],
    'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
    'status': 'PASS' if not errors else 'FAIL',
    'checks': checks,
    'errors': errors,
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
if errors:
    raise SystemExit(1)
print(f"Invariant process CI/closeout wiring verification passed. Evidence: {out}")
PY

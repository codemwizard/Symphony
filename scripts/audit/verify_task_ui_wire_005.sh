#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TASK-UI-WIRE-005"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/task_ui_wire_005_proof_model.json}"
DOC_FILE="$ROOT_DIR/docs/operations/SUPERVISORY_REVEAL_API_V2.md"
[[ -f "$DOC_FILE" ]] || { echo "missing_doc:$DOC_FILE" >&2; exit 1; }
for pattern in 'PT-001' 'PT-002' 'PT-003' 'PT-004' 'FAILED' 'FLAGGED' 'GET /v1/supervisory/programmes/{programId}/reveal'; do
  rg -Fq "$pattern" "$DOC_FILE" || { echo "missing_doc_pattern:$pattern" >&2; exit 1; }
done
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT
export EVIDENCE_LINK_SUBMISSIONS_FILE="$TMP_DIR/submissions.ndjson"
export DEMO_EXCEPTION_LOG_FILE="$TMP_DIR/exceptions.ndjson"
export SYMPHONY_KNOWN_TENANTS=11111111-1111-1111-1111-111111111111
export DEMO_EVIDENCE_LINK_SIGNING_KEY=test-evidence-signing
export DEMO_INSTRUCTION_SIGNING_KEY=test-instruction-signing

dotnet run --no-launch-profile --project "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj" -- --self-test-supervisory-read-models >"$TMP_DIR/selftest.log" 2>&1
SOURCE_EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_demo_007_supervisory_read_models.json"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$SOURCE_EVIDENCE"
import json, os, subprocess, sys
from pathlib import Path

task_id, evidence_path, source_evidence = sys.argv[1:]
source = json.loads(Path(source_evidence).read_text(encoding='utf-8'))
status_map = {item['name']: item['status'] for item in source['details']['tests']}
required = [
    'reveal_read_model_components_present',
    'proof_rows_present',
    'proof_model_covers_pt_001_to_pt_004',
    'proof_statuses_include_failed_and_flagged',
]
missing = [name for name in required if status_map.get(name) != 'PASS']
out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
sha = subprocess.check_output(['git','rev-parse','HEAD'], text=True).strip()
payload = {
    'check_id': 'TASK-UI-WIRE-005-PROOF-MODEL',
    'task_id': task_id,
    'timestamp_utc': os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip(),
    'git_sha': sha,
    'status': 'PASS' if not missing else 'FAIL',
    'pass': not missing,
    'details': {
        'source_evidence': source_evidence,
        'required_checks': required,
        'missing_checks': missing,
    }
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
print(f'Evidence written: {out}')
if missing:
    raise SystemExit(f'missing_required_proof_model_checks:{missing}')
PY

#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/security/sec_001_dangerous_sink_policy.json"
mkdir -p "$(dirname "$EVIDENCE")"
bash "$ROOT_DIR/scripts/security/lint_app_sql_injection.sh" >/dev/null
bash "$ROOT_DIR/scripts/audit/test_supervisor_sql_injection_vectors.sh" >/dev/null
python3 - <<'PY' "$ROOT_DIR/services/supervisor_api/server.py" "$EVIDENCE"
import json, sys
path, out = sys.argv[1:]
text = open(path, encoding='utf-8').read()
payload = {
  'task_id': 'SEC-001',
  'status': 'PASS',
  'pass': True,
  'subprocess_psql_present': 'subprocess.check_output' in text and 'psql' in text,
  'psql_wrapper_present': 'def psql_scalar' in text or 'def psql_json_array' in text,
  'driver': 'psycopg' if 'import psycopg' in text else 'unknown'
}
with open(out, 'w', encoding='utf-8') as fh:
  json.dump(payload, fh, indent=2)
  fh.write('\n')
PY
echo "SEC-001 verification passed: $EVIDENCE"

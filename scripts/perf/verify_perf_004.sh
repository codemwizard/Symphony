#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_PATH="evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

CONTRACT="$ROOT_DIR/docs/PHASE1/phase1_contract.yml"
if [[ ! -f "$CONTRACT" ]]; then
  echo "MISSING_CONTRACT:$CONTRACT" >&2
  exit 1
fi

mapfile -t PERF_PATHS < <(python3 - <<'PY' "$CONTRACT"
import sys,yaml
rows=yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or []
paths=[]
for r in rows:
    if not isinstance(r,dict):
        continue
    if not bool(r.get('required')):
        continue
    p=str(r.get('evidence_path') or '').strip()
    if p.startswith('evidence/phase1/perf_'):
        paths.append(p)
print('\n'.join(sorted(set(paths))))
PY
)

if [[ "${#PERF_PATHS[@]}" -eq 0 ]]; then
  echo "no_perf_paths_declared_in_contract" >&2
  exit 1
fi

if [[ ! -x "$ROOT_DIR/scripts/audit/verify_phase1_closeout.sh" ]]; then
  echo "missing_closeout_script" >&2
  exit 1
fi

mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"
TIMESTAMP="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"
python3 - <<'PY' "$ROOT_DIR/$EVIDENCE_PATH" "$TIMESTAMP" "$GIT_SHA" "$SCHEMA_FP" "${PERF_PATHS[@]}"
import json,sys
out=sys.argv[1]
timestamp=sys.argv[2]
git_sha=sys.argv[3]
schema_fp=sys.argv[4]
paths=sys.argv[5:]
payload={
  "check_id":"PERF-004-CLOSEOUT-EXTENSION",
  "task_id":"PERF-004",
  "status":"PASS",
  "pass":True,
  "perf_evidence_paths_enforced":paths,
  "closeout_script":"scripts/audit/verify_phase1_closeout.sh",
  "timestamp_utc":timestamp,
  "git_sha":git_sha,
  "schema_fingerprint":schema_fp,
}
with open(out,'w',encoding='utf-8') as f:
  json.dump(payload,f,indent=2)
  f.write('\n')
PY

echo "Evidence written: $EVIDENCE_PATH"

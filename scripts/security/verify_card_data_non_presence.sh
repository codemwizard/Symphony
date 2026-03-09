#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/card_data_non_presence.json"
mkdir -p "$(dirname "$EVIDENCE")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
if rg -n '\b(pan|primary account number|cvv|cvc|track2|card_number)\b' \
  "$ROOT_DIR/services" "$ROOT_DIR/schema" "$ROOT_DIR/docs" \
  -g '!docs/phase-1/Phase 2 Verification and Refinement.md' \
  -g '!docs/tasks/phase1_prompts.md' >/tmp/card_hits.txt; then
  cat /tmp/card_hits.txt >&2
  exit 1
fi
python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({
    'check_id':'INV-144',
    'timestamp_utc': os.environ['EVIDENCE_TS'],
    'git_sha': os.environ['EVIDENCE_GIT_SHA'],
    'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
    'status':'PASS',
    'pass':True
  }, fh, indent=2)
  fh.write('\n')
PY

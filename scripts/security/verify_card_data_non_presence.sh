#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/card_data_non_presence.json"
mkdir -p "$(dirname "$EVIDENCE")"
if rg -n '\b(pan|primary account number|cvv|cvc|track2|card_number)\b' \
  "$ROOT_DIR/services" "$ROOT_DIR/schema" "$ROOT_DIR/docs" \
  -g '!docs/phase-1/Phase 2 Verification and Refinement.md' \
  -g '!docs/tasks/phase1_prompts.md' >/tmp/card_hits.txt; then
  cat /tmp/card_hits.txt >&2
  exit 1
fi
python3 - <<'PY' "$EVIDENCE"
import json, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
  json.dump({'check_id':'INV-144','status':'PASS','pass':True}, fh, indent=2)
  fh.write('\n')
PY

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP_REPO="$(mktemp -d)"
FIRST_OUT="$(mktemp)"
SECOND_OUT="$(mktemp)"
trap 'rm -rf "$TMP_REPO" "$FIRST_OUT" "$SECOND_OUT"' EXIT

cp -a "$ROOT/." "$TMP_REPO/"

run_once() {
  local out_path="$1"
  (
    cd "$TMP_REPO"
    PRE_CI_CONTEXT=1 \
    SYMPHONY_ENV=development \
    SYMPHONY_EVIDENCE_DETERMINISTIC=1 \
    bash scripts/audit/verify_human_governance_review_signoff.sh >/dev/null
    cp evidence/phase1/human_governance_review_signoff.json "$out_path"
  )
}

run_once "$FIRST_OUT"

(
  cd "$TMP_REPO"
  git config user.name "Codex"
  git config user.email "codex@example.invalid"
  mkdir -p docs/operations
  printf '%s\n' 'adjacent review-scope noise' > docs/operations/tsk_p1_252_adjacent_note.md
  git add docs/operations/tsk_p1_252_adjacent_note.md
  git -c core.hooksPath=/dev/null commit -m "test: adjacent doc change for TSK-P1-252" >/dev/null
)

run_once "$SECOND_OUT"

cmp -s "$FIRST_OUT" "$SECOND_OUT"

python3 - <<'PY' "$FIRST_OUT"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
if payload.get("status") != "PASS":
    raise SystemExit("status mismatch")
for forbidden in ("reviewed_files", "changed_files", "coverage_source_files"):
    if forbidden in payload:
        raise SystemExit(f"forbidden field present: {forbidden}")
for required in ("review_scope_count", "review_scope_fingerprint", "coverage_source_kind", "coverage_source_count", "coverage_source_fingerprint"):
    if required not in payload:
        raise SystemExit(f"missing required field: {required}")
if payload.get("coverage_source_kind") != "approval_metadata_scope":
    raise SystemExit("coverage source kind mismatch")
print("ok")
PY

echo "test_verify_human_governance_review_signoff.sh passed"

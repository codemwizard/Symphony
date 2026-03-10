#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_061_git_containment_rule.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

failures=()
rule_doc="$ROOT/docs/operations/GIT_MUTATION_CONTAINMENT_RULE.md"
audit_doc="$ROOT/docs/audits/GIT_MUTATION_SURFACE_AUDIT_2026-03-10.md"
manual="$ROOT/docs/operations/AI_AGENT_OPERATION_MANUAL.md"
[[ -f "$rule_doc" ]] || failures+=("missing_rule_doc")
[[ -f "$audit_doc" ]] || failures+=("missing_audit_doc")
[[ -f "$manual" ]] || failures+=("missing_manual")
rg -q "GIT_DIR|GIT_WORK_TREE|git -C|repository identity" "$rule_doc" || failures+=("rule_doc_missing_required_controls")
rg -q "GIT_MUTATION_CONTAINMENT_RULE.md" "$manual" || failures+=("manual_missing_rule_link")
rg -q "test_diff_semantics_parity.sh|scripts/dev/pre_ci.sh" "$audit_doc" || failures+=("audit_doc_missing_core_inventory")

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s
' "${failures[@]}")"
import json, sys
out, ts, sha, fp = sys.argv[1:5]
failures = [x for x in sys.argv[5:] if x]
payload = {
  "check_id": "TSK-P1-061",
  "task_id": "TSK-P1-061",
  "timestamp_utc": ts,
  "git_sha": sha,
  "schema_fingerprint": fp,
  "status": "PASS" if not failures else "FAIL",
  "failures": failures,
}
open(out, 'w', encoding='utf-8').write(json.dumps(payload, indent=2) + "\n")
if failures:
    raise SystemExit(1)
print(f"TSK-P1-061 verification passed. Evidence: {out}")
PY

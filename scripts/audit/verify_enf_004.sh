#!/usr/bin/env bash
# verify_enf_004.sh — ENF-004 static verifier
# Checks AGENT_ENTRYPOINT.md and .agent/prompt_template.md contain required markers.
# Emits evidence/phase1/enf_004_agent_entrypoint_docs.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase1/enf_004_agent_entrypoint_docs.json"
ENTRYPOINT="$REPO_ROOT/AGENT_ENTRYPOINT.md"
PROMPT_TEMPLATE="$REPO_ROOT/.agent/prompt_template.md"
TASK_ID="ENF-004"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()
entrypoint_evidence_ack_confirmed="false"
entrypoint_clear_cmd_confirmed="false"
prompt_template_evidence_ack_confirmed="false"
prompt_template_clear_cmd_confirmed="false"

echo "[1/4] Checking AGENT_ENTRYPOINT.md markers..."
if grep -q "evidence_ack" "$ENTRYPOINT"; then
    echo "✅ PASS: 'evidence_ack' found in AGENT_ENTRYPOINT.md"
    checks+=("entrypoint_evidence_ack")
    entrypoint_evidence_ack_confirmed="true"
else
    echo "❌ FAIL: 'evidence_ack' missing from AGENT_ENTRYPOINT.md"
    failures+=("entrypoint_evidence_ack_missing")
fi

if grep -q "verify_drd_casefile.sh --clear" "$ENTRYPOINT"; then
    echo "✅ PASS: 'verify_drd_casefile.sh --clear' found in AGENT_ENTRYPOINT.md"
    checks+=("entrypoint_clear_cmd")
    entrypoint_clear_cmd_confirmed="true"
else
    echo "❌ FAIL: 'verify_drd_casefile.sh --clear' missing from AGENT_ENTRYPOINT.md"
    failures+=("entrypoint_clear_cmd_missing")
fi

echo ""
echo "[2/4] Checking .agent/prompt_template.md markers..."
if grep -q "exits 51\|evidence ack\|evidence_ack" "$PROMPT_TEMPLATE"; then
    echo "✅ PASS: evidence ack gate reference found in prompt_template.md"
    checks+=("prompt_template_evidence_ack")
    prompt_template_evidence_ack_confirmed="true"
else
    echo "❌ FAIL: evidence ack gate reference missing from prompt_template.md"
    failures+=("prompt_template_evidence_ack_missing")
fi

if grep -q "verify_drd_casefile.sh --clear" "$PROMPT_TEMPLATE"; then
    echo "✅ PASS: 'verify_drd_casefile.sh --clear' found in prompt_template.md"
    checks+=("prompt_template_clear_cmd")
    prompt_template_clear_cmd_confirmed="true"
else
    echo "❌ FAIL: 'verify_drd_casefile.sh --clear' missing from prompt_template.md"
    failures+=("prompt_template_clear_cmd_missing")
fi

echo ""
echo "[3/4] Negative test — check old raw rm instruction is absent..."
if grep -q "rm \$PRE_CI_DRD_LOCKOUT_FILE\|rm.*drd_lockout" "$ENTRYPOINT" 2>/dev/null; then
    echo "❌ FAIL: raw rm lockout instruction found in AGENT_ENTRYPOINT.md"
    failures+=("entrypoint_has_raw_rm")
else
    echo "✅ PASS: raw rm lockout instruction absent from AGENT_ENTRYPOINT.md"
    checks+=("entrypoint_no_raw_rm")
fi

if grep -q "rm \$PRE_CI_DRD_LOCKOUT_FILE\|rm.*drd_lockout" "$PROMPT_TEMPLATE" 2>/dev/null; then
    echo "❌ FAIL: raw rm lockout instruction found in prompt_template.md"
    failures+=("prompt_template_has_raw_rm")
else
    echo "✅ PASS: raw rm lockout instruction absent from prompt_template.md"
    checks+=("prompt_template_no_raw_rm")
fi

echo ""
echo "[4/4] Emitting evidence..."
mkdir -p "$(dirname "$EVIDENCE_FILE")"

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
CHECKS_JSON="$(printf '%s\n' "${checks[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"

STATUS="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then STATUS="FAIL"; fi

python3 - <<PY
import json
from pathlib import Path

def stob(s): return s.strip().lower() == "true"

evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "$STATUS",
    "checks": $CHECKS_JSON,
    "failures": $FAILURES_JSON,
    "entrypoint_evidence_ack_confirmed": stob("$entrypoint_evidence_ack_confirmed"),
    "entrypoint_clear_cmd_confirmed": stob("$entrypoint_clear_cmd_confirmed"),
    "prompt_template_evidence_ack_confirmed": stob("$prompt_template_evidence_ack_confirmed"),
    "prompt_template_clear_cmd_confirmed": stob("$prompt_template_clear_cmd_confirmed"),
}
Path("$EVIDENCE_FILE").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"Evidence written: $EVIDENCE_FILE")
PY

echo ""
if [[ "$STATUS" == "PASS" ]]; then
    echo "✅ ENF-004 PASS"
    exit 0
else
    echo "❌ ENF-004 FAIL — ${#failures[@]} failure(s): ${failures[*]}"
    exit 1
fi

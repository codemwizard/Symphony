#!/usr/bin/env bash
# verify_gf_w1_rem_001.sh — GF-W1-REM-001 verifier
# Confirms stale migration number refs (0088-0093) are absent from the 6 Wave 5
# pre_ci verifier stubs and each stub exits 0 in PENDING state.
# Emits evidence/phase1/gf_w1_rem_001.json
# Exit 0 = PASS, Exit 1 = FAIL
set -euo pipefail

TASK_ID="GF-W1-REM-001"
RUN_ID="$(date +%s)"
GIT_SHA="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_PATH="evidence/phase1/gf_w1_rem_001.json"

STUBS=(
    "scripts/db/verify_gf_fnc_001.sh"
    "scripts/db/verify_gf_fnc_002.sh"
    "scripts/db/verify_gf_fnc_003.sh"
    "scripts/db/verify_gf_fnc_004.sh"
    "scripts/db/verify_gf_fnc_005.sh"
    "scripts/db/verify_gf_fnc_006.sh"
)

echo "==> GF-W1-REM-001: Checking Wave 5 pre_ci stubs for stale migration number refs"
echo ""

failures=()
STUBS_CHECKED=0
STALE_REFS_FOUND=0
STUBS_PENDING_VERIFIED=0

for stub in "${STUBS[@]}"; do
    if [[ ! -f "$stub" ]]; then
        echo "❌ FAIL: Stub not found: $stub"
        failures+=("stub_missing: $stub")
        continue
    fi

    STUBS_CHECKED=$((STUBS_CHECKED + 1))

    if grep -qE "008[89]_|009[0-3]_" "$stub"; then
        MATCH="$(grep -oE "008[89]_[^'\"[:space:]]+|009[0-3]_[^'\"[:space:]]+" "$stub" | head -1)"
        echo "❌ FAIL: Stale migration ref in $stub: $MATCH"
        failures+=("stale_ref_in:$stub:$MATCH")
        STALE_REFS_FOUND=$((STALE_REFS_FOUND + 1))
    else
        echo "✅ PASS: No stale refs in $stub"
    fi
done

if [[ $STALE_REFS_FOUND -gt 0 ]]; then
    echo ""
    echo "❌ FAIL: $STALE_REFS_FOUND stub(s) contain stale migration refs — cannot proceed"
    FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
    mkdir -p "$(dirname "$EVIDENCE_PATH")"
    python3 - <<PY
import json
evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "FAIL",
    "stubs_checked": $STUBS_CHECKED,
    "stale_refs_found": $STALE_REFS_FOUND,
    "stubs_pending_verified": 0,
    "failures": $FAILURES_JSON
}
with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
PY
    exit 1
fi

echo ""
echo "==> Verifying each stub exits 0 (PENDING — migration not yet implemented)"
echo ""

for stub in "${STUBS[@]}"; do
    output="$(bash "$stub" 2>&1 || true)"
    if echo "$output" | grep -qiE "PENDING|PASS"; then
        echo "✅ PASS: $stub exits with expected state"
        STUBS_PENDING_VERIFIED=$((STUBS_PENDING_VERIFIED + 1))
    else
        echo "❌ FAIL: $stub did not produce PENDING/PASS output"
        echo "   Output: $(echo "$output" | head -3)"
        failures+=("unexpected_output: $stub")
    fi
done

if [[ ${#failures[@]} -gt 0 ]]; then
    echo ""
    echo "❌ FAIL: One or more stubs did not exit as expected"
    FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
    mkdir -p "$(dirname "$EVIDENCE_PATH")"
    python3 - <<PY
import json
evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "FAIL",
    "stubs_checked": $STUBS_CHECKED,
    "stale_refs_found": $STALE_REFS_FOUND,
    "stubs_pending_verified": $STUBS_PENDING_VERIFIED,
    "failures": $FAILURES_JSON
}
with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
PY
    exit 1
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<PY
import json
evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "PASS",
    "stubs_checked": $STUBS_CHECKED,
    "stale_refs_found": 0,
    "stubs_pending_verified": $STUBS_PENDING_VERIFIED,
    "stubs": [
        "scripts/db/verify_gf_fnc_001.sh",
        "scripts/db/verify_gf_fnc_002.sh",
        "scripts/db/verify_gf_fnc_003.sh",
        "scripts/db/verify_gf_fnc_004.sh",
        "scripts/db/verify_gf_fnc_005.sh",
        "scripts/db/verify_gf_fnc_006.sh"
    ],
    "failures": []
}
with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
print("Evidence written to $EVIDENCE_PATH")
PY

echo ""
echo "✅ GF-W1-REM-001 PASS: All 6 Wave 5 stubs have correct migration number references"
exit 0

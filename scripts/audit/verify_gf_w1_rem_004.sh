#!/usr/bin/env bash
# verify_gf_w1_rem_004.sh — GF-W1-REM-004 verifier
# Confirms rogue verify_gf_w1_fnc_007b refs are absent from tasks/GF-W1-FNC-007B/meta.yml.
# Emits evidence/phase1/gf_w1_rem_004.json
# Exit 0 = PASS, Exit 1 = FAIL
set -euo pipefail

TASK_ID="GF-W1-REM-004"
RUN_ID="$(date +%s)"
GIT_SHA="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_PATH="evidence/phase1/gf_w1_rem_004.json"
TARGET_FILE="tasks/GF-W1-FNC-007B/meta.yml"
ROGUE_PATTERN="verify_gf_w1_fnc_007b"

echo "==> GF-W1-REM-004: Checking tasks/GF-W1-FNC-007B/meta.yml for rogue verifier refs"
echo ""

failures=()
FILES_CHECKED=0
STALE_REFS_FOUND=0

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "❌ FAIL: Target file not found: $TARGET_FILE"
    mkdir -p "$(dirname "$EVIDENCE_PATH")"
    python3 - <<PY
import json
evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "FAIL",
    "files_checked": 0,
    "stale_refs_found": 0,
    "failures": ["file_missing: $TARGET_FILE"]
}
with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
PY
    exit 1
fi

FILES_CHECKED=1

if grep -q "$ROGUE_PATTERN" "$TARGET_FILE"; then
    COUNT="$(grep -c "$ROGUE_PATTERN" "$TARGET_FILE" || true)"
    echo "❌ FAIL: $COUNT rogue ref(s) found in $TARGET_FILE"
    grep -n "$ROGUE_PATTERN" "$TARGET_FILE" | while read -r line; do
        echo "   $line"
    done
    STALE_REFS_FOUND="$COUNT"
    failures+=("rogue_ref_in:$TARGET_FILE:count=$COUNT")
else
    echo "✅ PASS: No rogue refs in $TARGET_FILE"
fi

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"

STATUS="PASS"
if [[ $STALE_REFS_FOUND -gt 0 ]]; then
    STATUS="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<PY
import json
evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "$STATUS",
    "files_checked": $FILES_CHECKED,
    "stale_refs_found": $STALE_REFS_FOUND,
    "target_file": "$TARGET_FILE",
    "failures": $FAILURES_JSON
}
with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
print("Evidence written to $EVIDENCE_PATH")
PY

if [[ "$STATUS" == "FAIL" ]]; then
    echo ""
    echo "❌ GF-W1-REM-004 FAIL: tasks/GF-W1-FNC-007B/meta.yml still contains rogue refs"
    exit 1
fi

echo ""
echo "✅ GF-W1-REM-004 PASS: tasks/GF-W1-FNC-007B/meta.yml is free of rogue verifier refs"
exit 0

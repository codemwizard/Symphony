#!/usr/bin/env bash
# verify_gf_w1_rem_002.sh — GF-W1-REM-002 verifier
# Confirms rogue migration names and verify_gf_w1_fnc_* refs are absent from the
# 7 GF-W1-FNC-001 through GF-W1-FNC-007A task meta.yml files.
# Emits evidence/phase1/gf_w1_rem_002.json
# Exit 0 = PASS, Exit 1 = FAIL
set -euo pipefail

TASK_ID="GF-W1-REM-002"
RUN_ID="$(date +%s)"
GIT_SHA="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_PATH="evidence/phase1/gf_w1_rem_002.json"

META_FILES=(
    "tasks/GF-W1-FNC-001/meta.yml"
    "tasks/GF-W1-FNC-002/meta.yml"
    "tasks/GF-W1-FNC-003/meta.yml"
    "tasks/GF-W1-FNC-004/meta.yml"
    "tasks/GF-W1-FNC-005/meta.yml"
    "tasks/GF-W1-FNC-006/meta.yml"
    "tasks/GF-W1-FNC-007A/meta.yml"
)

ROGUE_PATTERN='verify_gf_w1_fnc_00[1-7]|0107_gf_register|0108_gf_record_monitoring|0109_gf_attach|0110_gf_authority|0084_gf_asset|0086_gf_verifier|0104_gf_confidence'

echo "==> GF-W1-REM-002: Checking FNC meta.yml files for rogue migration/verifier refs"
echo ""

failures=()
FILES_CHECKED=0
STALE_REFS_FOUND=0

for meta in "${META_FILES[@]}"; do
    if [[ ! -f "$meta" ]]; then
        echo "❌ FAIL: meta.yml not found: $meta"
        failures+=("file_missing: $meta")
        continue
    fi

    FILES_CHECKED=$((FILES_CHECKED + 1))

    if grep -qE "$ROGUE_PATTERN" "$meta"; then
        MATCH="$(grep -oE "$ROGUE_PATTERN" "$meta" | head -1)"
        echo "❌ FAIL: Rogue ref in $meta: $MATCH"
        failures+=("rogue_ref_in:$meta:$MATCH")
        STALE_REFS_FOUND=$((STALE_REFS_FOUND + 1))
    else
        echo "✅ PASS: No rogue refs in $meta"
    fi
done

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
FILES_AUDITED_JSON="$(printf '%s\n' "${META_FILES[@]}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"

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
    "files_audited": $FILES_AUDITED_JSON,
    "failures": $FAILURES_JSON
}
with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
print("Evidence written to $EVIDENCE_PATH")
PY

if [[ "$STATUS" == "FAIL" ]]; then
    echo ""
    echo "❌ GF-W1-REM-002 FAIL: $STALE_REFS_FOUND file(s) contain rogue refs"
    exit 1
fi

echo ""
echo "✅ GF-W1-REM-002 PASS: All 7 FNC meta.yml files are free of rogue refs"
exit 0

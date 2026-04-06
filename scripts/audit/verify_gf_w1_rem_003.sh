#!/usr/bin/env bash
# verify_gf_w1_rem_003.sh — GF-W1-REM-003 verifier
# Confirms rogue migration filename refs are absent from GF-W1-FNC-002/003/004 PLAN.md files.
# Emits evidence/phase1/gf_w1_rem_003.json
# Exit 0 = PASS, Exit 1 = FAIL
set -euo pipefail

TASK_ID="GF-W1-REM-003"
RUN_ID="$(date +%s)"
GIT_SHA="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EVIDENCE_PATH="evidence/phase1/gf_w1_rem_003.json"

PLAN_FILES=(
    "docs/plans/phase1/GF-W1-FNC-002/PLAN.md"
    "docs/plans/phase1/GF-W1-FNC-003/PLAN.md"
    "docs/plans/phase1/GF-W1-FNC-004/PLAN.md"
    "docs/plans/phase1/GF-W1-FNC-005/PLAN.md"
    "docs/plans/phase1/GF-W1-FNC-006/PLAN.md"
    "docs/plans/phase1/GF-W1-FNC-007A/PLAN.md"
)

ROGUE_PATTERN='0108_gf_record_monitoring|0109_gf_attach|0110_gf_authority|0084_gf_asset|0086_gf_verifier|0104_gf_confidence'

echo "==> GF-W1-REM-003: Checking FNC PLAN.md files for rogue migration filename refs"
echo ""

failures=()
FILES_CHECKED=0
STALE_REFS_FOUND=0

for plan in "${PLAN_FILES[@]}"; do
    if [[ ! -f "$plan" ]]; then
        echo "❌ FAIL: PLAN.md not found: $plan"
        failures+=("file_missing: $plan")
        continue
    fi

    FILES_CHECKED=$((FILES_CHECKED + 1))

    if grep -qE "$ROGUE_PATTERN" "$plan"; then
        MATCH="$(grep -oE "$ROGUE_PATTERN[^'\"[:space:]]*" "$plan" | head -1)"
        echo "❌ FAIL: Rogue ref in $plan: $MATCH"
        failures+=("rogue_ref_in:$plan:$MATCH")
        STALE_REFS_FOUND=$((STALE_REFS_FOUND + 1))
    else
        echo "✅ PASS: No rogue refs in $plan"
    fi
done

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
FILES_AUDITED_JSON="$(printf '%s\n' "${PLAN_FILES[@]}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"

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
    echo "❌ GF-W1-REM-003 FAIL: $STALE_REFS_FOUND PLAN.md file(s) contain rogue migration refs"
    exit 1
fi

echo ""
echo "✅ GF-W1-REM-003 PASS: All FNC PLAN.md files are free of rogue migration refs"
exit 0

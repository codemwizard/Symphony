#!/usr/bin/env bash
# verify_enf_000.sh — ENF-000 static verifier
# Checks .gitattributes has eol=lf for all required extensions.
# Emits evidence/phase1/enf_000_gitattributes_lf.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase1/enf_000_gitattributes_lf.json"
GITATTRIBUTES="$REPO_ROOT/.gitattributes"
TASK_ID="ENF-000"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()
observed_rules=()

echo "[1/3] Checking .gitattributes exists..."
if [[ ! -f "$GITATTRIBUTES" ]]; then
    echo "❌ FAIL: .gitattributes not found at repo root"
    failures+=("gitattributes_missing")
else
    echo "✅ PASS: .gitattributes exists"
    checks+=("gitattributes_exists")
fi

echo ""
echo "[2/3] Checking eol=lf rules for required extensions..."
REQUIRED_EXTENSIONS=("sh" "md" "yml" "yaml" "env" "json" "py" "toml")

for ext in "${REQUIRED_EXTENSIONS[@]}"; do
    if grep -q "\*\.${ext}.*eol=lf" "$GITATTRIBUTES" 2>/dev/null; then
        echo "✅ PASS: *.${ext} eol=lf rule present"
        checks+=("eol_lf_${ext}")
        observed_rules+=("*.${ext} eol=lf")
    else
        echo "❌ FAIL: *.${ext} eol=lf rule missing"
        failures+=("eol_lf_missing_${ext}")
    fi
done

echo ""
echo "[3/3] Emitting evidence..."
mkdir -p "$(dirname "$EVIDENCE_FILE")"

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
CHECKS_JSON="$(printf '%s\n' "${checks[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
RULES_JSON="$(printf '%s\n' "${observed_rules[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"

STATUS="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
    STATUS="FAIL"
fi

python3 - <<PY
import json
from pathlib import Path

evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "$STATUS",
    "checks": $CHECKS_JSON,
    "failures": $FAILURES_JSON,
    "observed_rules": $RULES_JSON,
}

Path("$EVIDENCE_FILE").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"Evidence written: $EVIDENCE_FILE")
PY

echo ""
if [[ "$STATUS" == "PASS" ]]; then
    echo "✅ ENF-000 PASS"
    exit 0
else
    echo "❌ ENF-000 FAIL — ${#failures[@]} failure(s): ${failures[*]}"
    exit 1
fi

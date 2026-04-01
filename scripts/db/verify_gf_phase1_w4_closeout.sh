#!/usr/bin/env bash
# verify_gf_phase1_w4_closeout.sh — GF-W1-SCH-009 aggregated closeout verifier
# Invokes all GF Phase 0 schema verifiers (SCH-002A through SCH-008) in DAG order.
# Emits evidence/phase0/gf_phase1_w4_closeout.json.
# Exit 0 = all pass, Exit 1 = any fail.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase0/gf_phase1_w4_closeout.json"
TASK_ID="GF-W1-SCH-009"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

VERIFIERS=(
    "scripts/db/verify_gf_sch_002a.sh"
    "scripts/db/verify_gf_monitoring_records.sh"
    "scripts/db/verify_gf_evidence_lineage.sh"
    "scripts/db/verify_gf_asset_lifecycle.sh"
    "scripts/db/verify_gf_regulatory_plane.sh"
    "scripts/db/verify_gf_verifier_registry.sh"
)

failures=()
verifier_results=()

echo "GF-W1-SCH-009: Phase 1 Wave 4 schema closeout verifier"
echo "Invoking ${#VERIFIERS[@]} GF schema verifiers in DAG order..."
echo ""

for verifier in "${VERIFIERS[@]}"; do
    script_path="$REPO_ROOT/$verifier"
    name="$(basename "$verifier")"
    echo "--- Running $name ---"
    if [[ ! -f "$script_path" ]]; then
        echo "  FAIL: verifier script not found: $script_path"
        failures+=("missing_verifier:$name")
        verifier_results+=("$name:MISSING")
    else
        # We run the subshell to prevent it exiting early from set -e
        if SYMPHONY_RUN_ID="$RUN_ID" bash "$script_path" 2>&1; then
            echo "  $name: PASS"
            verifier_results+=("$name:PASS")
        else
            echo "  $name: FAIL"
            failures+=("verifier_failed:$name")
            verifier_results+=("$name:FAIL")
        fi
    fi
    echo ""
done

ALL_PASS="true"
if [[ ${#failures[@]} -gt 0 ]]; then
    ALL_PASS="false"
fi

mkdir -p "$(dirname "$EVIDENCE_FILE")"

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c '
import json,sys
items = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(items))
')"

VERIFIER_RESULTS_JSON="$(printf '%s\n' "${verifier_results[@]}" | python3 -c '
import json,sys
items = [l.strip() for l in sys.stdin if l.strip()]
result = {}
for item in items:
    parts = item.split(":", 1)
    if len(parts) == 2:
        result[parts[0]] = parts[1]
print(json.dumps(result))
')"

python3 - <<PY
import json
import sys

def stob(s):
    return s.strip().lower() == "true"

failures = $FAILURES_JSON
verifier_results = $VERIFIER_RESULTS_JSON
status = "PASS" if not failures else "FAIL"

evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": status,
    "verifiers_invoked": [
        "verify_gf_sch_002a.sh",
        "verify_gf_monitoring_records.sh",
        "verify_gf_evidence_lineage.sh",
        "verify_gf_asset_lifecycle.sh",
        "verify_gf_regulatory_plane.sh",
        "verify_gf_verifier_registry.sh"
    ],
    "all_verifiers_pass": stob("$ALL_PASS"),
    "verifier_results": verifier_results,
    "observed_paths": [
        "scripts/db/verify_gf_sch_002a.sh",
        "scripts/db/verify_gf_monitoring_records.sh",
        "scripts/db/verify_gf_evidence_lineage.sh",
        "scripts/db/verify_gf_asset_lifecycle.sh",
        "scripts/db/verify_gf_regulatory_plane.sh",
        "scripts/db/verify_gf_verifier_registry.sh"
    ],
    "observed_hashes": {},
    "command_outputs": {"verifier": "verify_gf_phase1_w4_closeout.sh"},
    "execution_trace": [
        "verify_gf_sch_002a",
        "verify_gf_monitoring_records",
        "verify_gf_evidence_lineage",
        "verify_gf_asset_lifecycle",
        "verify_gf_regulatory_plane",
        "verify_gf_verifier_registry"
    ],
    "checks": {
        "all_verifiers_invoked": True,
        "all_verifiers_pass": stob("$ALL_PASS")
    },
    "failures": failures
}

with open("$EVIDENCE_FILE", "w") as f:
    json.dump(evidence, f, indent=2)

print(f"Evidence written to: $EVIDENCE_FILE")
PY

if [[ ${#failures[@]} -gt 0 ]]; then
    echo "GF-W1-SCH-009 closeout FAILED. Failures: ${failures[*]}"
    exit 1
fi

echo "GF-W1-SCH-009 closeout PASSED. All GF schema verifiers pass."
echo "Evidence: $EVIDENCE_FILE"

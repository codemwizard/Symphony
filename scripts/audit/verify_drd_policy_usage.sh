#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase0/drd_policy_usage.json}"
mkdir -p "$(dirname "$EVIDENCE_PATH")"

PR_TEMPLATE="$ROOT_DIR/.github/pull_request_template.md"
POLICY_FILE="$ROOT_DIR/.agent/policies/debug-remediation-policy.md"

status="PASS"
notes=()

if [[ ! -f "$POLICY_FILE" ]]; then
  status="FAIL"
  notes+=("missing_policy:.agent/policies/debug-remediation-policy.md")
fi

if [[ ! -f "$PR_TEMPLATE" ]]; then
  status="FAIL"
  notes+=("missing_pr_template:.github/pull_request_template.md")
else
  grep -q "Severity declaration" "$PR_TEMPLATE" || notes+=("missing_field:severity_declaration")
  grep -q "DRD links" "$PR_TEMPLATE" || notes+=("missing_field:drd_links")
  grep -q "L2/L3" "$PR_TEMPLATE" || notes+=("missing_guidance:l2_l3_requirement")
fi

if (( ${#notes[@]} > 0 )) && [[ "$status" == "PASS" ]]; then
  status="SKIPPED"
fi

NOTES_JOINED=""
if (( ${#notes[@]} > 0 )); then
  NOTES_JOINED="$(printf '%s\n' "${notes[@]}")"
fi

NOTES_JOINED="$NOTES_JOINED" python3 - <<PY
import json, os, subprocess, datetime
arr = [x for x in os.environ.get("NOTES_JOINED", "").splitlines() if x]
try:
    sha = subprocess.check_output(["git","-C", "$ROOT_DIR", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    sha = "UNKNOWN"
out = {
  "check_id": "DRD-POLICY-USAGE",
  "timestamp_utc": datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
  "git_sha": sha,
  "status": "$status",
  "details": {
    "mode": "advisory",
    "policy_present": os.path.isfile("$POLICY_FILE"),
    "pr_template_present": os.path.isfile("$PR_TEMPLATE"),
    "notes": arr,
    "no_hard_fail": True
  }
}
os.makedirs(os.path.dirname("$EVIDENCE_PATH"), exist_ok=True)
with open("$EVIDENCE_PATH", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
    f.write("\n")
print(f"DRD policy usage verifier {out['status']}. Evidence: $EVIDENCE_PATH")
PY

# Advisory-only by design.
exit 0

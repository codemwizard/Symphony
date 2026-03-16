#!/usr/bin/env bash
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_220_canonical_bootstrap.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$(date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-220: Canonical Bootstrap Script..."

BOOTSTRAP="$ROOT/scripts/dev/bootstrap.sh"

# ─── 1. Bootstrap script exists and is executable ───
if [ ! -f "$BOOTSTRAP" ]; then
  errors+=("bootstrap_missing")
fi

# ─── 2. Prerequisite gate (fail-closed) ───
if ! grep -q 'GATE_PASS=false' "$BOOTSTRAP" 2>/dev/null; then
  errors+=("no_fail_closed_gate")
fi

# ─── 3. Checks docker, dotnet, psql ───
for tool in docker dotnet psql; do
  if ! grep -q "command -v $tool" "$BOOTSTRAP" 2>/dev/null; then
    errors+=("missing_prereq_check_${tool}")
  fi
done

# ─── 4. Runs Wave 2 verifiers (216-219 via loop) ───
if ! grep -q 'for task in.*216.*217.*218.*219' "$BOOTSTRAP" 2>/dev/null; then
  errors+=("missing_verifier_loop")
fi
if ! grep -q 'verify_tsk_p1_' "$BOOTSTRAP" 2>/dev/null; then
  errors+=("missing_verifier_call_pattern")
fi

# ─── 5. Calls openbao_bootstrap.sh ───
if ! grep -q 'openbao_bootstrap.sh' "$BOOTSTRAP" 2>/dev/null; then
  errors+=("no_openbao_bootstrap")
fi

# ─── 6. Has evidence validation step ───
if ! grep -q 'validate_evidence_schema' "$BOOTSTRAP" 2>/dev/null; then
  errors+=("no_evidence_validation")
fi

# ─── 7. Has SKIP_OPENBAO_BOOTSTRAP check ───
if ! grep -q 'SKIP_OPENBAO_BOOTSTRAP' "$BOOTSTRAP" 2>/dev/null; then
  errors+=("no_skip_openbao_check")
fi

# ─── 8. Builds LedgerApi ───
if ! grep -q 'dotnet build' "$BOOTSTRAP" 2>/dev/null; then
  errors+=("no_dotnet_build")
fi

# ─── Emit evidence ───
if [[ ${#errors[@]} -eq 0 ]]; then status="PASS"; else status="FAIL"; fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
}

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$(evidence_now_utc)" "$(git_sha)" "$(schema_fingerprint)" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-220",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-220",
    "run_id": run_id,
    "checks": {
        "bootstrap_exists": "bootstrap_missing" not in errors,
        "fail_closed_gate": "no_fail_closed_gate" not in errors,
        "prereq_checks": all(f"missing_prereq_check_{t}" not in errors for t in ["docker","dotnet","psql"]),
        "wave2_verifiers": "missing_verifier_loop" not in errors and "missing_verifier_call_pattern" not in errors,
        "openbao_bootstrap": "no_openbao_bootstrap" not in errors,
        "evidence_validation": "no_evidence_validation" not in errors,
        "skip_openbao": "no_skip_openbao_check" not in errors,
        "dotnet_build": "no_dotnet_build" not in errors,
    },
    "errors": errors
}
os.makedirs(os.path.dirname(evidence_path), exist_ok=True)
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: TSK-P1-220 Canonical bootstrap script verified."
echo "Evidence: $EVIDENCE"

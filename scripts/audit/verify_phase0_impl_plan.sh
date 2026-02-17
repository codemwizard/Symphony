#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN="$ROOT_DIR/docs/Phase_0001-0005/implementation_plan.md"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/phase0_impl_plan.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$PLAN" ]]; then
  python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "PHASE0-IMPL-PLAN",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "FAIL",
  "reason": "missing plan"
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY
  echo "❌ Missing plan: $PLAN" >&2
  exit 1
fi

missing=()
have_rg() { command -v rg >/dev/null 2>&1; }
plan_has() {
  local needle="$1"
  if have_rg; then
    rg -q "$needle" "$PLAN"
  else
    grep -q -- "$needle" "$PLAN"
  fi
}
plan_has_i() {
  local needle="$1"
  if have_rg; then
    rg -qi "$needle" "$PLAN"
  else
    grep -qi -- "$needle" "$PLAN"
  fi
}

for token in 0014_tenants.sql 0015_tenant_clients.sql 0016_tenant_members.sql 0017_ingress_tenant_attribution.sql 0018_outbox_tenant_attribution.sql 0019_member_tenant_consistency_guard.sql; do
  if ! plan_has "$token"; then
    missing+=("$token")
  fi
done

if ! plan_has_i "tenant"; then
  missing+=("tenant keyword")
fi
if ! plan_has_i "member"; then
  missing+=("member keyword")
fi

status="PASS"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="FAIL"
fi

MISSING_JOINED="$(printf '%s\n' "${missing[@]}")" STATUS="$status" python3 - <<PY
import json
from pathlib import Path
import os
missing = [m for m in os.environ.get("MISSING_JOINED", "").split("\n") if m]
out = {
  "check_id": "PHASE0-IMPL-PLAN",
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": os.environ.get("STATUS", "PASS"),
  "missing": missing
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ "$status" == "FAIL" ]]; then
  echo "❌ Phase-0 implementation plan check failed" >&2
  exit 1
fi

echo "Phase-0 implementation plan check passed. Evidence: $EVIDENCE_FILE"

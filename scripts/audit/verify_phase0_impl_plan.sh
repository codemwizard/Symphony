#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN="$ROOT_DIR/docs/Phase_0001-0005/implementation_plan.md"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/phase0_impl_plan.json"

mkdir -p "$EVIDENCE_DIR"

if [[ ! -f "$PLAN" ]]; then
  python3 - <<PY
import json
from pathlib import Path
Path("$EVIDENCE_FILE").write_text(json.dumps({"status":"fail","reason":"missing plan"}, indent=2))
PY
  echo "❌ Missing plan: $PLAN" >&2
  exit 1
fi

missing=()
for token in 0014_tenants.sql 0015_tenant_clients.sql 0016_tenant_members.sql 0017_ingress_tenant_attribution.sql 0018_outbox_tenant_attribution.sql 0019_member_tenant_consistency_guard.sql; do
  if ! rg -q "$token" "$PLAN"; then
    missing+=("$token")
  fi
done

if ! rg -qi "tenant" "$PLAN"; then
  missing+=("tenant keyword")
fi
if ! rg -qi "member" "$PLAN"; then
  missing+=("member keyword")
fi

status="pass"
if [[ ${#missing[@]} -gt 0 ]]; then
  status="fail"
fi

MISSING_JOINED="$(printf '%s\n' "${missing[@]}")" STATUS="$status" python3 - <<PY
import json
from pathlib import Path
import os
missing = [m for m in os.environ.get("MISSING_JOINED", "").split("\n") if m]
out = {
  "status": os.environ.get("STATUS", "pass"),
  "missing": missing
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

if [[ "$status" == "fail" ]]; then
  echo "❌ Phase-0 implementation plan check failed" >&2
  exit 1
fi

echo "Phase-0 implementation plan check passed. Evidence: $EVIDENCE_FILE"

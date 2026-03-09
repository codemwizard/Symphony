#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/services/test_pilot_authz_tenant_boundary.sh"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-022 --evidence "$ROOT_DIR/evidence/phase1/authz_tenant_boundary.json"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-022 --evidence "$ROOT_DIR/evidence/phase1/boz_access_boundary_runtime.json"


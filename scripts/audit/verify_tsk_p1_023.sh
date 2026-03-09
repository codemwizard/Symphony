#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/security/verify_sandbox_deploy_manifest_posture.sh"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-023 --evidence "$ROOT_DIR/evidence/phase1/sandbox_deploy_manifest_posture.json"


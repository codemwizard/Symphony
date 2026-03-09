#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$ROOT_DIR/scripts/dev/run_phase1_pilot_harness.sh"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-019 --evidence "$ROOT_DIR/evidence/phase1/pilot_harness_replay.json"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-019 --evidence "$ROOT_DIR/evidence/phase1/pilot_onboarding_readiness.json"


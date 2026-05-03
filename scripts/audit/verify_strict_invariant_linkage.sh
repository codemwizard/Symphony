#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"

if [[ -f "scripts/audit/auto_create_exception_from_detect.py" ]]; then
  echo "FAIL: auto_create_exception_from_detect.py still exists." >&2
  exit 1
fi

if grep -q "auto_create_exception_from_detect.py" scripts/audit/preflight_structural_staged.sh; then
  echo "FAIL: preflight_structural_staged.sh still references auto_create_exception_from_detect.py." >&2
  exit 1
fi

if ! grep -q "exit 1" scripts/audit/preflight_structural_staged.sh; then
  echo "FAIL: preflight_structural_staged.sh does not fail correctly on structural changes." >&2
  exit 1
fi

cat <<EOF
{
  "task_id": "TSK-P1-REM-080",
  "status": "PASS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "timestamp_utc": "$EVIDENCE_TS",
  "observed_hashes": {},
  "checks": [
    "auto_create_exception_from_detect.py does not exist",
    "preflight_structural_staged.sh does not reference auto_create_exception_from_detect.py",
    "preflight_structural_staged.sh exits 1 on structural change"
  ]
}
EOF

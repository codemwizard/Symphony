#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANDIDATE_FILE="${CANDIDATE_FILE:-$ROOT_DIR/docs/operations/perf_smoke_baseline.candidate.json}"
APPROVAL_FILE="${APPROVAL_FILE:-$ROOT_DIR/docs/perf/perf_baseline_approval.yml}"

if [[ ! -f "$CANDIDATE_FILE" ]]; then
  echo "rebaseline_candidate_absent"
  exit 0
fi

if [[ ! -f "$APPROVAL_FILE" ]]; then
  echo "missing_rebaseline_approval_file:$APPROVAL_FILE" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  CANDIDATE_SHA="$(sha256sum "$CANDIDATE_FILE" | awk '{print $1}')"
else
  CANDIDATE_SHA="$(shasum -a 256 "$CANDIDATE_FILE" | awk '{print $1}')"
fi

python3 - <<PY
from pathlib import Path
import re
import sys

approval = Path(r"$APPROVAL_FILE").read_text(encoding="utf-8", errors="ignore")

def grab(field: str):
    m = re.search(rf"^{field}:\s*(.+)\s*$", approval, flags=re.MULTILINE)
    if not m:
        return None
    return m.group(1).strip().strip("'\"")

approved_by = grab("approved_by")
approved_at = grab("approved_at_utc")
candidate_sha = grab("candidate_baseline_sha256")
reason = grab("reason")

errors = []
if not approved_by:
    errors.append("missing_approved_by")
if not approved_at:
    errors.append("missing_approved_at_utc")
if not reason:
    errors.append("missing_reason")
if not candidate_sha:
    errors.append("missing_candidate_baseline_sha256")
if candidate_sha and candidate_sha != "$CANDIDATE_SHA":
    errors.append("candidate_sha_mismatch")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)

print("rebaseline_approval_sha_lock_ok")
PY

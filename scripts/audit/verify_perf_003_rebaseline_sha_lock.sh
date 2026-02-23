#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
OUT_FILE="$EVIDENCE_DIR/perf_003_rebaseline_sha_lock.json"
BASELINE_FILE="$ROOT_DIR/docs/operations/perf_smoke_baseline.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

"$ROOT_DIR/scripts/audit/run_perf_smoke.sh"

CANDIDATE_FILE="$TMPDIR/perf_smoke_baseline.candidate.json"
APPROVAL_GOOD="$TMPDIR/perf_baseline_approval_good.yml"
APPROVAL_BAD="$TMPDIR/perf_baseline_approval_bad.yml"

SOURCE_EVIDENCE="$ROOT_DIR/evidence/phase1/perf_smoke_profile.json" \
BASELINE_IN="$BASELINE_FILE" \
CANDIDATE_OUT="$CANDIDATE_FILE" \
  "$ROOT_DIR/scripts/perf/rebaseline.sh" >/tmp/symphony_perf003_rebaseline.log 2>&1

if command -v sha256sum >/dev/null 2>&1; then
  CANDIDATE_SHA="$(sha256sum "$CANDIDATE_FILE" | awk '{print $1}')"
else
  CANDIDATE_SHA="$(shasum -a 256 "$CANDIDATE_FILE" | awk '{print $1}')"
fi

cat > "$APPROVAL_GOOD" <<EOF
approved_by: "perf-governance-reviewer"
approved_at_utc: "$EVIDENCE_TS"
candidate_baseline_sha256: "$CANDIDATE_SHA"
reason: "PERF-003 verifier fixture: matching SHA lock"
EOF

CANDIDATE_FILE="$CANDIDATE_FILE" APPROVAL_FILE="$APPROVAL_GOOD" \
  "$ROOT_DIR/scripts/perf/verify_rebaseline_approval.sh" >/tmp/symphony_perf003_good.log 2>&1

cat > "$APPROVAL_BAD" <<EOF
approved_by: "perf-governance-reviewer"
approved_at_utc: "$EVIDENCE_TS"
candidate_baseline_sha256: "0000000000000000000000000000000000000000000000000000000000000000"
reason: "PERF-003 verifier fixture: mismatch must fail"
EOF

set +e
CANDIDATE_FILE="$CANDIDATE_FILE" APPROVAL_FILE="$APPROVAL_BAD" \
  "$ROOT_DIR/scripts/perf/verify_rebaseline_approval.sh" >/tmp/symphony_perf003_bad.log 2>&1
BAD_RC=$?
set -e

STATUS="PASS"
ERRORS=()
if [[ ! -f "$CANDIDATE_FILE" ]]; then
  STATUS="FAIL"
  ERRORS+=("candidate_not_generated")
fi
if [[ "$BAD_RC" -eq 0 ]]; then
  STATUS="FAIL"
  ERRORS+=("mismatch_case_did_not_fail")
fi

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  ERRORS_JSON="$(printf '%s\n' "${ERRORS[@]}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
else
  ERRORS_JSON="[]"
fi

python3 - <<PY
import json
from pathlib import Path

out = {
  "check_id": "PERF-003",
  "task_id": "PERF-003",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "$STATUS",
  "pass": "$STATUS" == "PASS",
  "details": {
    "baseline_file": "docs/operations/perf_smoke_baseline.json",
    "candidate_file_generated": True,
    "candidate_baseline_sha256": "$CANDIDATE_SHA",
    "approval_good_verified": True,
    "approval_bad_exit_code": int("$BAD_RC"),
    "sha_lock_enforced": int("$BAD_RC") != 0,
    "workflow_docs": [
      "docs/perf/REBASELINE.md",
      "docs/perf/perf_baseline_approval.yml"
    ]
  },
  "errors": json.loads('''$ERRORS_JSON''')
}
Path(r"$OUT_FILE").write_text(json.dumps(out, indent=2) + "\\n", encoding="utf-8")
PY

if [[ "$STATUS" != "PASS" ]]; then
  echo "PERF-003 rebaseline SHA-lock verification failed" >&2
  exit 1
fi

echo "PERF-003 rebaseline SHA-lock verification passed"

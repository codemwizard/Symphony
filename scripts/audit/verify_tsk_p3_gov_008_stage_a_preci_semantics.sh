#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P3-GOV-008"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
CHECKS_FILE="$TMPDIR/checks.tsv"
: > "$CHECKS_FILE"
PASS=true

record_check() {
  local id="$1" status="$2" detail="$3"
  printf '%s\t%s\t%s\n' "$id" "$status" "$detail" >> "$CHECKS_FILE"
  if [[ "$status" != "PASS" ]]; then
    PASS=false
  fi
}

make_fixture_root() {
  local fixture="$1"
  mkdir -p "$fixture/approvals/2026-05-18" "$fixture/evidence/phase1" "$fixture/scripts/lib"
  cp "$ROOT/scripts/lib/evidence.sh" "$fixture/scripts/lib/evidence.sh"
}

make_stage_a_fixture() {
  local fixture="$1"
  make_fixture_root "$fixture"
  cat >"$fixture/approvals/2026-05-18/BRANCH-feat-test.md" <<'EOF'
## 8. Cross-References (Machine-Readable)
Approval Sidecar JSON: approvals/2026-05-18/BRANCH-feat-test.approval.json
EOF
  cat >"$fixture/approvals/2026-05-18/BRANCH-feat-test.approval.json" <<'EOF'
{
  "schema_version": "1.0",
  "approval": {"status": "APPROVED", "approver_id": "qa_verifier", "change_reason": "stage-a test"},
  "ai": {"ai_used": true, "ai_prompt_hash": "11111111111111111111111111111111", "model_id": "test-model"},
  "scope": {"regulated_surfaces_touched": true, "paths_changed": ["docs/operations/AI_AGENT_OPERATION_MANUAL.md"]},
  "verification": {"commands": ["echo stage-a"], "pre_ci_passed": false}
}
EOF
  cat >"$fixture/evidence/phase1/approval_metadata.json" <<'EOF'
{
  "schema_version": "1.0",
  "generated_at_utc": "2026-05-18T10:00:00Z",
  "git_commit": "1111111",
  "change_scope": {"regulated_surfaces_touched": true, "paths_changed": ["docs/operations/AI_AGENT_OPERATION_MANUAL.md"]},
  "ai": {"ai_prompt_hash": "11111111111111111111111111111111", "model_id": "test-model"},
  "human_approval": {
    "approver_id": "qa_verifier",
    "approval_stage": "stage_a",
    "approval_artifact_ref": "approvals/2026-05-18/BRANCH-feat-test.md",
    "change_reason": "stage-a test"
  }
}
EOF
}

make_stage_b_fixture() {
  local fixture="$1"
  make_fixture_root "$fixture"
  cat >"$fixture/approvals/2026-05-18/PR-999.md" <<'EOF'
## 8. Cross-References (Machine-Readable)
Approval Sidecar JSON: approvals/2026-05-18/PR-999.approval.json
EOF
  cat >"$fixture/approvals/2026-05-18/PR-999.approval.json" <<'EOF'
{
  "schema_version": "1.0",
  "approval": {"status": "APPROVED", "approver_id": "qa_verifier", "change_reason": "stage-b test"},
  "ai": {"ai_used": true, "ai_prompt_hash": "11111111111111111111111111111111", "model_id": "test-model"},
  "scope": {"regulated_surfaces_touched": true, "paths_changed": ["docs/operations/AI_AGENT_OPERATION_MANUAL.md"]},
  "verification": {"commands": ["echo stage-b"], "pre_ci_passed": false}
}
EOF
  cat >"$fixture/evidence/phase1/approval_metadata.json" <<'EOF'
{
  "schema_version": "1.0",
  "generated_at_utc": "2026-05-18T10:00:00Z",
  "git_commit": "1111111",
  "change_scope": {"regulated_surfaces_touched": true, "paths_changed": ["docs/operations/AI_AGENT_OPERATION_MANUAL.md"]},
  "ai": {"ai_prompt_hash": "11111111111111111111111111111111", "model_id": "test-model"},
  "human_approval": {
    "approver_id": "qa_verifier",
    "approval_stage": "stage_b",
    "approval_artifact_ref": "approvals/2026-05-18/PR-999.md",
    "change_reason": "stage-b test"
  }
}
EOF
}

STAGE_A_FIXTURE="$TMPDIR/stage_a"
make_stage_a_fixture "$STAGE_A_FIXTURE"
if PRE_CI_CONTEXT=1 ROOT_DIR="$STAGE_A_FIXTURE" BRANCH_NAME="feat/test" EVIDENCE_FILE="$STAGE_A_FIXTURE/out.json" bash "$ROOT/scripts/audit/verify_human_governance_review_signoff.sh" >/dev/null 2>"$TMPDIR/stage_a.err"; then
  record_check "stage_a_accepts_false_preci" "PASS" "Stage A approval passes without pre_ci_passed=true"
else
  record_check "stage_a_accepts_false_preci" "FAIL" "Stage A approval still fails when pre_ci_passed=false"
fi

STAGE_B_FIXTURE="$TMPDIR/stage_b"
make_stage_b_fixture "$STAGE_B_FIXTURE"
if PRE_CI_CONTEXT=1 ROOT_DIR="$STAGE_B_FIXTURE" BRANCH_NAME="HEAD" EVIDENCE_FILE="$STAGE_B_FIXTURE/out.json" bash "$ROOT/scripts/audit/verify_human_governance_review_signoff.sh" >/dev/null 2>"$TMPDIR/stage_b.err"; then
  record_check "stage_b_requires_preci" "FAIL" "Stage B/final signoff unexpectedly passed with pre_ci_passed=false"
else
  if grep -q 'pre_ci_not_recorded_true' "$STAGE_B_FIXTURE/out.json"; then
    record_check "stage_b_requires_preci" "PASS" "Stage B/final signoff still fails closed when pre_ci truth is missing"
  else
    record_check "stage_b_requires_preci" "FAIL" "Stage B/final signoff failed without the expected pre_ci_not_recorded_true error"
  fi
fi

if rg -n 'approval_stage|Stage A attests reviewed scope|Stage B or final governance signoff' "$ROOT/docs/operations/AI_AGENT_OPERATION_MANUAL.md" "$ROOT/docs/operations/approval_metadata.schema.json" >/dev/null; then
  record_check "docs_and_schema_updated" "PASS" "manual and approval metadata schema distinguish Stage A from final signoff"
else
  record_check "docs_and_schema_updated" "FAIL" "manual/schema missing Stage A vs final signoff distinction"
fi

if [[ "$PASS" == "true" ]]; then STATUS="PASS"; else STATUS="FAIL"; fi
export ROOT TASK_ID TIMESTAMP_UTC GIT_SHA STATUS CHECKS_FILE
python3 - <<'PY'
import hashlib, json, os
from pathlib import Path

root = Path(os.environ["ROOT"])
checks = {}
for line in Path(os.environ["CHECKS_FILE"]).read_text(encoding="utf-8").splitlines():
    key, status, detail = line.split("\t", 2)
    checks[key] = {"status": status, "detail": detail}
paths = [
    "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
    "docs/operations/approval_metadata.schema.json",
    "scripts/audit/verify_human_governance_review_signoff.sh",
    "scripts/audit/verify_tsk_p3_gov_008_stage_a_preci_semantics.sh",
]
payload = {
    "task_id": os.environ["TASK_ID"],
    "git_sha": os.environ["GIT_SHA"],
    "timestamp_utc": os.environ["TIMESTAMP_UTC"],
    "status": os.environ["STATUS"],
    "checks": checks,
    "observed_paths": paths,
    "observed_hashes": {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in paths},
}
print(json.dumps(payload, indent=2))
PY

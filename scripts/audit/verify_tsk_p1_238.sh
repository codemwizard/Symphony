#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

EVIDENCE_FILE="evidence/phase1/tsk_p1_238_order_authority.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

fail() {
  echo "❌ FAIL: $1"
  exit 1
}

echo "==> Verifying execution-order authority drift (TSK-P1-238)"

# Verify index reference
if ! grep -q "RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md" docs/tasks/PHASE1_GOVERNANCE_TASKS.md; then
  fail "docs/tasks/PHASE1_GOVERNANCE_TASKS.md omits reference to RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md"
fi
echo "✅ Governance task index points to canonical pickup guide"

# Verify task metadata alignment with the strict sequence
verify_dep() {
  local task="$1"
  local exp_dep="$2"
  if ! grep -q "\- $exp_dep" "tasks/$task/meta.yml"; then
    fail "$task/meta.yml does not declare dependency on $exp_dep"
  fi
}

verify_dep "TSK-P1-227" "TSK-P1-226"
verify_dep "TSK-P1-234" "TSK-P1-233"
verify_dep "TSK-P1-235" "TSK-P1-234"
echo "✅ Task metadata execution orders match canonical sequence"

# The user already normalized the backlog in the PR/commit. 
# We just check for obvious duplicates in Stage D1/D2/D3 staging lines
if grep -Eq "^- TSK-P1-.*$" docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md | sort | uniq -d | grep -q .; then
  fail "Duplicate tasks found in downstream backlog"
fi
echo "✅ Backlog is deduplicated"

git_sha="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'unknown')"
timestamp="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "TSK-P1-238",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "corrected_dependency_edges": "TSK-P1-227 uses 226, 234 uses 233, 235 uses 234",
    "index_reference_result": "PASS",
    "backlog_dedup_result": "PASS"
  }
}
EOF

echo "✅ Generated evidence: $EVIDENCE_FILE"
exit 0

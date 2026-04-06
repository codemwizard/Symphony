#!/usr/bin/env bash
set -e

>&2 echo "=================================="
>&2 echo "TSK-P1-222: Verify TSK-RLS-ARCH-001 Scope Repair"
>&2 echo "=================================="

META_FILE="tasks/TSK-RLS-ARCH-001/meta.yml"
PLAN_FILE="docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md"

if ! grep "docs/reference/rls-remediation-first-five-tasks.md" "$PLAN_FILE" >/dev/null; then
    >&2 echo "❌ FAIL: Parent plan missing links to first-five wave."
    exit 1
fi

if ! grep "docs/reference/rls-remediation-remainder-plan.md" "$PLAN_FILE" >/dev/null; then
    >&2 echo "❌ FAIL: Parent plan missing links to remainder wave."
    exit 1
fi

# Extract the 'touches' list
TOUCHES=$(awk '/^touches:/{flag=1; next} /^invariants:/{flag=0} flag' "$META_FILE")
if echo "$TOUCHES" | grep -E 'scripts/db/|schema/|migration|psql|ALTER TABLE' >/dev/null; then
    >&2 echo "❌ FAIL: Parent meta.yml touches array contains executable or DB paths."
    exit 1
fi

if ! echo "$TOUCHES" | grep -q "docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md" || \
   ! echo "$TOUCHES" | grep -q "docs/plans/phase1/TSK-RLS-ARCH-001/EXEC_LOG.md" || \
   ! echo "$TOUCHES" | grep -q "evidence/phase1/rls_arch/tsk_rls_arch_001.json" || \
   ! echo "$TOUCHES" | grep -q "tasks/TSK-RLS-ARCH-001/meta.yml"; then
    >&2 echo "❌ FAIL: Parent meta.yml touches array missing required governance files."
    exit 1
fi

# Verify there aren't more than 4 items in touches
TOUCHES_COUNT=$(echo "$TOUCHES" | grep "^  -" | wc -l)
if [ "$TOUCHES_COUNT" -gt 4 ]; then
    >&2 echo "❌ FAIL: Touches array contains more than the 4 permissible governance artifacts."
    exit 1
fi

VERIFICATION=$(awk '/^verification:/{flag=1; next} /^evidence:/{flag=0} flag' "$META_FILE")
if echo "$VERIFICATION" | grep -E 'scripts/db/|schema/|migration|psql|ALTER TABLE' >/dev/null; then
    >&2 echo "❌ FAIL: Parent verification block contains executable DB-side statements."
    exit 1
fi

>&2 echo "✅ Parent Scope Successfully Assessed."

cat <<EOF
{
  "task_id": "TSK-P1-222",
  "git_sha": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'LOCAL')",
  "timestamp_utc": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "PASS",
  "checks": ["P1"],
  "parent_task_id": "TSK-RLS-ARCH-001",
  "repaired_paths": ["tasks/TSK-RLS-ARCH-001/meta.yml", "docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md", "docs/plans/phase1/TSK-RLS-ARCH-001/EXEC_LOG.md"],
  "contract_alignment": "verified_delegation_and_no_db_footprint",
  "observed_paths": ["tasks/TSK-RLS-ARCH-001/meta.yml", "docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md"],
  "observed_hashes": ["$(shasum tasks/TSK-RLS-ARCH-001/meta.yml | cut -d' ' -f1)", "$(shasum docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md | cut -d' ' -f1)"],
  "command_outputs": ["Parent contract touches strictly constrained."],
  "execution_trace": ["/tmp/tsk_p1_222_tests/*"]
}
EOF
exit 0

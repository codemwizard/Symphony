# TSK-P2-W5-FIX-11 PLAN — Correct migration references in Wave 5 task metadata

Task: TSK-P2-W5-FIX-11
Owner: QA_VERIFIER
Depends on: TSK-P2-W5-FIX-10
failure_signature: P2.W5-FIX.META-DRIFT.FALSE_AUDIT_TRAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Wave 5 meta.yml files (TSK-P2-PREAUTH-005-00 through 005-08) may reference migration
numbers that don't match actual files. This creates false audit trails. After this task,
all migration references in `touches:` arrays resolve to actual files on disk.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-10 status=completed.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `tasks/TSK-P2-PREAUTH-005-{00..08}/meta.yml` | MODIFY | Correct migration references |
| `scripts/audit/verify_meta_migration_refs.sh` | CREATE | Automated reference validator |
| `evidence/phase2/tsk_p2_w5_fix_11.json` | CREATE | Evidence |

---

## Implementation Steps

### Step 1: Audit All References
**What:** `[ID w5_fix_11_work_01]` For each of 9 meta.yml files, extract migration paths from `touches:` and verify each file exists.
```bash
for meta in tasks/TSK-P2-PREAUTH-005-*/meta.yml; do
    grep 'schema/migrations/' "$meta" | while read -r line; do
        path=$(echo "$line" | sed 's/.*- //')
        [ -f "$path" ] || echo "MISSING: $path in $meta"
    done
done
```

### Step 2: Correct References
**What:** `[ID w5_fix_11_work_02]` Update each meta.yml to reference actual migration files.

### Step 3: Write Verification Script
**What:** `[ID w5_fix_11_work_03]` Create `scripts/audit/verify_meta_migration_refs.sh`.

### Step 4-5: Run verification, update EXEC_LOG.

---

## Verification

```bash
bash scripts/audit/verify_meta_migration_refs.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_11.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_11.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, discrepancies_found, discrepancies_resolved

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| References still wrong | False audit trail | Automated validator |
| Validator too permissive | Misses broken refs | Fail-closed on missing file |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists

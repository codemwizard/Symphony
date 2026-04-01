# Troubleshooting: PRECI.GOVERNANCE.*

**Failure signatures:** `PRECI.GOVERNANCE.TASK_PLAN_LOG`, `PRECI.GOVERNANCE.TASK_META_SCHEMA`
**Gates:** `pre_ci.verify_task_plans_present`, `pre_ci.verify_task_meta_schema`
**Owner:** governance
**DRD level:** L1

---

## PRECI.GOVERNANCE.TASK_PLAN_LOG -- Task plan/log missing

### What this means

A task is referenced but its `PLAN.md` or `EXEC_LOG.md` is missing.

### Expected failure output

```
ERROR: PLAN.md missing for task GF-W1-SCH-002A
Expected at: tasks/GF-W1-SCH-002A/PLAN.md
```

### Diagnostic steps

1. **Run directly:**
   ```bash
   scripts/audit/verify_task_plans_present.sh
   ```

2. **Check the `plan_path` in meta.yml matches the actual file location:**
   ```bash
   grep plan_path tasks/*/meta.yml
   ```

3. **Create missing files** using the task creation process:
   ```bash
   cat docs/operations/TASK_CREATION_PROCESS.md
   ```

---

## PRECI.GOVERNANCE.TASK_META_SCHEMA -- Schema validation failed

### What this means

A changed `meta.yml` has missing required fields or invalid field values.

### Expected failure output

```
FAIL tasks/GF-W1-SCH-002A/meta.yml: missing field 'acceptance_criteria'
FAIL tasks/GF-W1-SCH-002A/meta.yml: schema_version must be "1"
```

### Diagnostic steps

1. **Run directly:**
   ```bash
   scripts/audit/verify_task_meta_schema.sh --mode strict --scope changed
   ```

2. **Common failures:**
   - `schema_version` not set to `"1"`
   - `status` not in allowed values: `planned`, `in_progress`, `completed`, `blocked`
   - Missing required fields: `acceptance_criteria`, `verification`, `evidence`
   - `domain: green_finance` tasks missing GF-specific required fields

3. **Reference the schema standard:**
   ```bash
   cat docs/operations/TASK_AUTHORING_STANDARD_v2.md
   ```

---

## Clearing the DRD lockout

```bash
scripts/audit/new_remediation_casefile.sh \
  --phase phase1 \
  --slug governance-task-meta \
  --failure-signature PRECI.GOVERNANCE.TASK_META_SCHEMA \
  --origin-gate-id pre_ci.verify_task_meta_schema \
  --repro-command "scripts/dev/pre_ci.sh"

rm .toolchain/pre_ci_debug/drd_lockout.env
scripts/dev/pre_ci.sh
```

# Troubleshooting: PRECI.STRUCTURAL.CHANGE_RULE

**Failure signature:** `PRECI.STRUCTURAL.CHANGE_RULE`
**Gate:** `pre_ci.enforce_change_rule`
**Owner:** governance
**DRD level:** L2

## What this means

A change touches a regulated surface without the required approval metadata
or exception record.

## Expected failure output

```
ERROR: regulated surface change detected without approval metadata
Changed regulated paths: scripts/audit/verify_agent_conformance.sh
FAILURE_SIGNATURE=PRECI.STRUCTURAL.CHANGE_RULE
```

## Diagnostic steps

1. **Run the change-rule gate directly:**
   ```bash
   BASE_REF="refs/remotes/origin/main" HEAD_REF="HEAD" scripts/audit/enforce_change_rule.sh
   ```

2. **Check which regulated surfaces are defined:**
   ```bash
   cat docs/operations/REGULATED_SURFACE_PATHS.yml
   ```

3. **Check whether approval metadata exists:**
   ```bash
   cat evidence/phase1/approval_metadata.json
   ```
   If it does not exist, a human approver must create it before implementation continues.
   The file must contain valid `ai.ai_prompt_hash` (64-char SHA256), `ai.model_id`,
   and `human_approval.*` fields.

4. **For DDL/migration changes:** Ensure the migration file is listed in the
   task's `meta.yml` `touches` field and that `MIGRATION_HEAD` is updated.

## Clearing the DRD lockout

```bash
scripts/audit/new_remediation_casefile.sh \
  --phase phase1 \
  --slug change-rule \
  --failure-signature PRECI.STRUCTURAL.CHANGE_RULE \
  --origin-gate-id pre_ci.enforce_change_rule \
  --repro-command "scripts/dev/pre_ci.sh"

rm .toolchain/pre_ci_debug/drd_lockout.env
scripts/dev/pre_ci.sh
```

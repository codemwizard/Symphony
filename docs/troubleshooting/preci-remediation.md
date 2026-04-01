# Troubleshooting: PRECI.REMEDIATION.*

**Failure signatures:** `PRECI.REMEDIATION.TRACE`, `PRECI.REMEDIATION.FRESHNESS`
**Gates:** `pre_ci.verify_remediation_trace`, `pre_ci.verify_remediation_artifact_freshness`
**Owner:** governance
**DRD level:** L2

---

## PRECI.REMEDIATION.TRACE — Remediation trace missing

### What this means

A production-affecting file was changed without a corresponding remediation
trace casefile.

### Expected failure output

```
ERROR: production-affecting change to scripts/dev/pre_ci.sh has no remediation trace
No REM-* or TSK-* casefile found covering this change
FAILURE_SIGNATURE=PRECI.REMEDIATION.TRACE
```

### Diagnostic steps

1. **Run directly:**
   ```bash
   REMEDIATION_TRACE_DIFF_MODE=range bash scripts/audit/verify_remediation_trace.sh
   ```
   The output names the changed file that lacks a casefile.

2. **Create a casefile for the change:**
   ```bash
   scripts/audit/new_remediation_casefile.sh \
     --phase phase1 \
     --slug <descriptive-slug> \
     --failure-signature PRECI.REMEDIATION.TRACE \
     --origin-gate-id pre_ci.verify_remediation_trace \
     --repro-command "scripts/dev/pre_ci.sh"
   ```

3. **Reference the full workflow:**
   ```bash
   cat docs/operations/REMEDIATION_TRACE_WORKFLOW.md
   ```

---

## PRECI.REMEDIATION.FRESHNESS — Artifact stale or missing

### What this means

A guarded execution surface was changed but its associated evidence artifact
is stale or missing.

### Expected failure output

```
ERROR: scripts/agent/run_task.sh modified but evidence artifact is stale
Expected fresh artifact at: evidence/security_remediation/run_task_freshness.json
FAILURE_SIGNATURE=PRECI.REMEDIATION.FRESHNESS
```

### Diagnostic steps

1. **Run directly:**
   ```bash
   BASE_REF="refs/remotes/origin/main" HEAD_REF="HEAD" \
     bash scripts/audit/verify_remediation_artifact_freshness.sh
   ```
   The output names the guarded surface file and the expected evidence artifact path.

2. **Re-generate the evidence artifact** by running the verifier associated
   with that surface. Check `scripts/audit/runtime_guarded_execution_core.sh`
   to identify which script produces the artifact for the changed file.

---

## Clearing the DRD lockout

```bash
# Step 1 — create the casefile
scripts/audit/new_remediation_casefile.sh \
  --phase phase1 \
  --slug remediation-trace \
  --failure-signature PRECI.REMEDIATION.TRACE \
  --origin-gate-id pre_ci.verify_remediation_trace \
  --repro-command "scripts/dev/pre_ci.sh"

# Step 2 — document root cause in PLAN.md

# Step 3 — remove lockout
rm .toolchain/pre_ci_debug/drd_lockout.env

# Step 4 — re-run
scripts/dev/pre_ci.sh
```

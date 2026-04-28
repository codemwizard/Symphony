# TSK-P2-PREAUTH-007-19 PLAN — CI Provenance & Identity Binding

Task: TSK-P2-PREAUTH-007-19
Owner: SECURITY_GUARDIAN
Gap Source: G-05 part 2 (W7_GAP_ANALYSIS.md line 163)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-19.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any regulated file without prior approval metadata.

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only.
- Mandatory markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

Implement the hash-chaining logic and executor identity binding for CI execution proof. This is part 2 of the CI execution proof — it builds on the `PRECI_STEP` sequence logging from TSK-P2-PREAUTH-007-18.

**Why This Matters (from G-05, line 163):**
Command digest alone proves a file with that hash was invoked, not that it executed successfully against the expected substrate. Log-only trace without command-digest binding is log theater. Full provenance chain is required.

**Required Provenance Chain:**
```
trace step name
  → command digest (SHA-256 of verifier script)
    → evidence artifact digest (SHA-256 of evidence JSON output)
      → environment fingerprint (DATABASE_URL hash, migration head, schema checksum)
        → executor identity (principal, DB role, effective grants, search_path)
```

Without provenance binding, CI execution proof is stronger theater but still theater.

---

## Pre-conditions

- [ ] TSK-P2-PREAUTH-007-18 completed (PRECI_STEP sequence logging operational).
- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p2_preauth_007_19.sh` | CREATE | Verifier for provenance binding |
| `evidence/phase2/tsk_p2_preauth_007_19.json` | CREATE | Output artifact |
| `scripts/dev/pre_ci.sh` | MODIFY | Add provenance emission to PRECI_STEP wrapper |

---

## Stop Conditions

- **If provenance only includes command digest without evidence digest** → STOP
- **If environment fingerprint is missing DATABASE_URL hash or migration head** → STOP
- **If executor identity is not captured** → STOP
- **If provenance can be generated under an overprivileged role** → STOP

---

## Implementation Steps

### Step 1: Environment Fingerprint

Capture the substrate state at execution time:

```bash
capture_env_fingerprint() {
  local db_url_hash=$(echo -n "$DATABASE_URL" | sha256sum | awk '{print $1}')
  local migration_head=$(ls -1 schema/migrations/*.sql | sort | tail -1 | grep -oP '\d+')
  local schema_checksum=$(psql "$DATABASE_URL" -t -c \
    "SELECT md5(string_agg(table_name || column_name || data_type, ',' ORDER BY table_name, column_name))
     FROM information_schema.columns
     WHERE table_schema = 'public'" | tr -d ' ')

  echo "${db_url_hash}:${migration_head}:${schema_checksum}"
}
```

### Step 2: Executor Identity Binding

Prove the verifier ran under the correct authority context:

```bash
capture_executor_identity() {
  local principal=$(whoami)
  local db_role=$(psql "$DATABASE_URL" -t -c "SELECT current_user" | tr -d ' ')
  local effective_grants=$(psql "$DATABASE_URL" -t -c \
    "SELECT string_agg(privilege_type, ',' ORDER BY privilege_type)
     FROM information_schema.role_table_grants
     WHERE grantee = current_user AND table_schema = 'public'
     LIMIT 100" | tr -d ' ')
  local search_path=$(psql "$DATABASE_URL" -t -c "SHOW search_path" | tr -d ' ')

  echo "${principal}:${db_role}:${effective_grants}:${search_path}"
}
```

**Executor identity binding must prove the verifier ran under the authority context the invariant assumes, not under an overprivileged context.** Evidence generated under wrong role/grants is invalid regardless of correctness.

### Step 3: Hash-Chaining

Extend the `PRECI_STEP` emission to include the full provenance chain:

```bash
emit_preci_step_with_provenance() {
  local step_name="$1"
  local verifier_script="$2"
  local evidence_file="$3"

  PRECI_STEP_COUNTER=$((PRECI_STEP_COUNTER + 1))

  local command_digest=$(sha256sum "$verifier_script" | awk '{print $1}')
  local evidence_digest=""
  if [ -f "$evidence_file" ]; then
    evidence_digest=$(sha256sum "$evidence_file" | awk '{print $1}')
  fi
  local env_fingerprint=$(capture_env_fingerprint)
  local executor_id=$(capture_executor_identity)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Full provenance line
  echo "PRECI_STEP:${PRECI_STEP_COUNTER}:${step_name}:${command_digest}:${evidence_digest}:${env_fingerprint}:${executor_id}:${timestamp}" >> "$PRECI_TRACE_LOG"
}
```

### Step 4: Provenance Validation

The provenance validator must check:
1. Each `PRECI_STEP` line contains all 7 fields.
2. Command digest matches the SHA-256 of the verifier script file on disk.
3. Evidence digest matches the SHA-256 of the evidence JSON file on disk.
4. Environment fingerprint is non-empty and contains a valid migration head.
5. Executor identity contains a non-root DB role.
6. Timestamps are in UTC ISO 8601 format.

### Step 5: Build Verifier

The verifier for this task:
1. Triggers a controlled `pre_ci.sh` run (or reads the latest trace log).
2. Validates the full provenance chain for each step.
3. Verifies no step has an empty evidence digest.
4. Verifies executor identity is not `postgres` superuser.

### Step 6: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19.json
```

### Step 7: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.

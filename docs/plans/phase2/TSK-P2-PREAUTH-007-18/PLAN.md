# TSK-P2-PREAUTH-007-18 PLAN — CI Sequence & Execution Trace

Task: TSK-P2-PREAUTH-007-18
Owner: SECURITY_GUARDIAN
Gap Source: G-05 part 1 (W7_GAP_ANALYSIS.md line 163)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-18.PROOF_FAIL
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

Rewrite the `pre_ci.sh` verifier wiring to emit `PRECI_STEP:` execution traces and assert ordered execution. This is part 1 of the CI execution proof — it covers sequence logging and step assertion. Part 2 (provenance hashing and identity binding) is in TSK-P2-PREAUTH-007-19.

**Risk Assessment (EXTREME RISK):**
This deliverable was flagged as the highest-risk task in the wave. An agent will attempt to write a script that greps for `PRECI_STEP:` strings in a log and call it "provenance." That is not acceptable. This task is deliberately scoped to ONLY the sequence and step logging — the harder provenance binding is isolated in 007-19.

**What Exists Today (from G-05, line 163):**
- Three verifier scripts are wired into `pre_ci.sh` via raw script paths in conditional `if [[ -x ... ]]` blocks.
- No execution trace is emitted.
- No order verification exists.
- The wiring uses Wave 6 upstream verifier paths, not the ordered function-call model the spec demands.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.
- [ ] `pre_ci.sh` is accessible and modifiable.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p2_preauth_007_18.sh` | CREATE | Verifier for CI sequence |
| `evidence/phase2/tsk_p2_preauth_007_18.json` | CREATE | Output artifact |
| `scripts/dev/pre_ci.sh` | MODIFY | Add PRECI_STEP emission and sequence assertion |

---

## Stop Conditions

- **If sequence verification uses grep** → STOP (must use structured assertion)
- **If `PRECI_STEP` emissions can be faked by writing to the log file** → STOP
- **If ordered execution is not actually enforced** → STOP

---

## Implementation Steps

### Step 1: Define Execution Trace Format

Each step in `pre_ci.sh` must emit a structured trace line:

```
PRECI_STEP:<step_number>:<step_name>:<command_digest>:<timestamp>
```

Where:
- `step_number`: Sequential integer (1, 2, 3, ...)
- `step_name`: Declared function name (e.g., `run_schema_checks`, `run_inv_175`)
- `command_digest`: SHA-256 of the verifier script file that was executed
- `timestamp`: ISO 8601 UTC timestamp of execution

### Step 2: Modify `pre_ci.sh`

**Execution Wrapper Function:**
```bash
PRECI_TRACE_LOG="/tmp/preci_trace_$(date +%s).log"
PRECI_STEP_COUNTER=0

emit_preci_step() {
  local step_name="$1"
  local verifier_script="$2"

  PRECI_STEP_COUNTER=$((PRECI_STEP_COUNTER + 1))
  local command_digest=$(sha256sum "$verifier_script" | awk '{print $1}')
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "PRECI_STEP:${PRECI_STEP_COUNTER}:${step_name}:${command_digest}:${timestamp}" >> "$PRECI_TRACE_LOG"
}
```

**Step Execution Pattern:**
```bash
# Instead of:
if [[ -x scripts/audit/verify_foo.sh ]]; then
  bash scripts/audit/verify_foo.sh
fi

# Use:
emit_preci_step "run_schema_checks" "scripts/audit/verify_foo.sh"
bash scripts/audit/verify_foo.sh || exit 1
```

### Step 3: Sequence Assertion

After all steps execute, a separate assertion pass verifies:
1. The trace log exists and is non-empty.
2. Step numbers are sequential (1, 2, 3, ...) with no gaps.
3. The declared step names match the expected ordered list.
4. Each command digest corresponds to a real file on disk.

**This assertion CANNOT run during the same execution pass** — it must be a post-execution check (to prevent self-verification).

```bash
assert_preci_sequence() {
  local trace_log="$1"
  local expected_steps=("run_schema_checks" "run_trigger_checks" "run_inv_175" "run_inv_176" "run_inv_177")

  local line_num=0
  while IFS=: read -r prefix step_num step_name cmd_digest timestamp; do
    line_num=$((line_num + 1))
    if [ "$step_num" != "$line_num" ]; then
      echo "FAIL: Expected step $line_num, got $step_num"
      return 1
    fi
    if [ "$step_name" != "${expected_steps[$((line_num-1))]}" ]; then
      echo "FAIL: Expected step name '${expected_steps[$((line_num-1))]}', got '$step_name'"
      return 1
    fi
  done < "$trace_log"
}
```

### Step 4: Build Verifier

The verifier for this task confirms:
1. `PRECI_TRACE_LOG` is generated during a `pre_ci.sh` run.
2. Steps are sequential.
3. No steps are missing.
4. Command digests match actual file hashes.

### Step 5: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_18.sh > evidence/phase2/tsk_p2_preauth_007_18.json
```

### Step 6: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.

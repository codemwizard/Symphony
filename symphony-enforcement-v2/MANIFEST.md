# Symphony Enforcement Package v2 -- MANIFEST
# Staging directory -- DO NOT apply to repo without reading this file first.
# Apply tasks in order: ENF-001 then ENF-002 then ENF-003 then ENF-004.
# Each task is independent at the file level but logically depends on the prior.
#
# SOURCE OF TRUTH: Everything in this staging directory is the canonical version.
# All files are plain UTF-8, no BOM. Safe to apply directly on Ubuntu.
#
# PREREQUISITE: Symphony Enforcement Package v1 must already be applied.
#   (docs/operations/failure_signatures.yml must exist)

## Task summary

| Task | Name | Deliverables | Status |
|---|---|---|---|
| ENF-000 | .gitattributes LF enforcement | .gitattributes (repo root) | Pending apply |
| ENF-001 | DRD gate in run_task.sh | Patch to run_task.sh | Pending apply |
| ENF-002 | verify_drd_casefile.sh | New script + patch to pre_ci_debug_contract.sh | Pending apply |
| ENF-003 | Evidence ack gate + retry counter | Patch to run_task.sh + new reset_evidence_gate.sh | Pending apply |
| ENF-004 | Agent entrypoint docs | Patch to AGENT_ENTRYPOINT.md + prompt_template.md | Pending apply |

---

## ENF-001 -- DRD gate in run_task.sh

### What it does
Adds a DRD lockout check as the very first action in run_task.sh, before meta
parse, pack readiness, bootstrap, and OUTDIR creation. If drd_lockout.env
exists, run_task.sh exits 99 immediately with a clear message referencing
verify_drd_casefile.sh --clear instead of raw rm.

### Files
- enf-001-run-task-drd-gate/run_task.PATCH.sh  -- patch instructions + snippet

### Apply
```bash
# The patch is a function insertion. See enf-001-run-task-drd-gate/run_task.PATCH.sh
# for the exact oldText/newText to apply with your editor or patch tool.
bash _staging/symphony-enforcement-v2/enf-001-run-task-drd-gate/apply.sh
```

### Verification
```bash
# With no lockout active: should proceed normally
bash scripts/agent/run_task.sh GF-W1-SCH-002A 2>&1 | head -5

# Simulate lockout active:
echo "DRD_LOCKED_SIGNATURE='PRECI.DB.ENVIRONMENT'" \
  > .toolchain/pre_ci_debug/drd_lockout.env
bash scripts/agent/run_task.sh GF-W1-SCH-002A 2>&1 | grep "DRD LOCKOUT"
echo $?   # must be 99
rm .toolchain/pre_ci_debug/drd_lockout.env
```

---

## ENF-002 -- verify_drd_casefile.sh

### What it does
Creates scripts/audit/verify_drd_casefile.sh. This script:
  - With no args: verifies that an active lockout has a matching casefile with
    documented root cause. Used by CI and agents to check gate status.
  - With --clear: performs a controlled lockout reset with audit logging to
    .toolchain/pre_ci_debug/clear_log.jsonl. Replaces raw rm instructions.
  - Uses yaml.safe_load for casefile matching. Falls back to regex for legacy
    casefiles that are not valid YAML, with a warning.

Also patches pre_ci_debug_contract.sh lockout message to reference
verify_drd_casefile.sh --clear instead of raw rm.

### Files
- enf-002-verify-drd-casefile/verify_drd_casefile.sh  -- new script (full file)
- enf-002-verify-drd-casefile/lockout_message.PATCH.md -- patch for pre_ci_debug_contract.sh

### Apply
```bash
# Copy new script
cp _staging/symphony-enforcement-v2/enf-002-verify-drd-casefile/verify_drd_casefile.sh \
   scripts/audit/verify_drd_casefile.sh
chmod +x scripts/audit/verify_drd_casefile.sh

# Apply lockout message patch to pre_ci_debug_contract.sh
# See enf-002-verify-drd-casefile/lockout_message.PATCH.md for exact edit location
bash _staging/symphony-enforcement-v2/enf-002-verify-drd-casefile/apply_patch.sh
```

### Verification
```bash
# No lockout: should exit 0
bash scripts/audit/verify_drd_casefile.sh
echo $?   # 0

# With lockout, no casefile: should exit 1
mkdir -p .toolchain/pre_ci_debug
echo "DRD_LOCKED_SIGNATURE='PRECI.DB.ENVIRONMENT'
DRD_LOCKED_GATE_ID='pre_ci.phase1_db_verifiers'
DRD_LOCKED_COUNT=2
DRD_LOCKED_AT='2026-03-29T00:00:00Z'
DRD_SCAFFOLD_CMD='scripts/audit/new_remediation_casefile.sh ...'" \
  > .toolchain/pre_ci_debug/drd_lockout.env
bash scripts/audit/verify_drd_casefile.sh 2>&1
echo $?   # 1
rm .toolchain/pre_ci_debug/drd_lockout.env
```

---

## ENF-003 -- Evidence ack gate + retry counter

### What it does
Adds two mechanisms to run_task.sh after the DRD gate (ENF-001) and before
the pack readiness gate:

1. RETRY COUNTER: On failure, increments .toolchain/evidence_ack/${TASK_ID}.retries.
   At run start, if retries >= 3, exits 50 (hard block) and directs to
   reset_evidence_gate.sh.

2. EVIDENCE ACK GATE: On failure, writes .toolchain/evidence_ack/${TASK_ID}.required.
   At run start, if .required exists, checks for .ack.attempt_N file with:
     task_id: matching
     evidence_read: true
     root_cause: non-empty, not "pending"
     acknowledged_at: ISO timestamp
   If no valid ack found, exits 51 with instructions for how to write the ack file.

3. ON SUCCESS: cleans up .required and .retries. Keeps .ack.attempt_* for audit.

Also creates scripts/audit/reset_evidence_gate.sh which logs the reset to
.toolchain/evidence_ack/reset_log.jsonl before deleting state files.

### Files
- enf-003-evidence-ack-gate/run_task_evidence.PATCH.md  -- patch instructions
- enf-003-evidence-ack-gate/reset_evidence_gate.sh      -- new script (full file)

### Apply
```bash
# Apply evidence gate patch to run_task.sh
bash _staging/symphony-enforcement-v2/enf-003-evidence-ack-gate/apply_patch.sh

# Copy reset script
cp _staging/symphony-enforcement-v2/enf-003-evidence-ack-gate/reset_evidence_gate.sh \
   scripts/audit/reset_evidence_gate.sh
chmod +x scripts/audit/reset_evidence_gate.sh
```

### Verification
```bash
# Confirm reset_evidence_gate.sh exists and is executable
bash scripts/audit/reset_evidence_gate.sh --help 2>&1 | head -3
```

---

## ENF-004 -- Agent entrypoint docs

### What it does
Updates AGENT_ENTRYPOINT.md Pre-Step to add evidence ack check as item 2 in
the ordered list (between rejection context check and mode classification).
Updates .agent/prompt_template.md EXECUTION RULES to add two new rules for
evidence ack and retry escalation.

Both are direct file replacements -- no surgical patching needed.

### Files
- enf-004-agent-entrypoint-docs/AGENT_ENTRYPOINT.md   -- full replacement
- enf-004-agent-entrypoint-docs/prompt_template.md    -- full replacement

### Apply
```bash
cp _staging/symphony-enforcement-v2/enf-004-agent-entrypoint-docs/AGENT_ENTRYPOINT.md \
   AGENT_ENTRYPOINT.md

cp _staging/symphony-enforcement-v2/enf-004-agent-entrypoint-docs/prompt_template.md \
   .agent/prompt_template.md
```

### Verification
```bash
grep "evidence_ack" AGENT_ENTRYPOINT.md
grep "evidence_ack" .agent/prompt_template.md
```

---

---

## ENF-000 -- .gitattributes LF enforcement

### What it does
Adds per-extension `eol=lf` rules to .gitattributes so that all .sh, .md,
.yml, .env, .json, .py, and .toml files are stored and checked out with LF
line endings regardless of the authoring OS. Prevents the BOM/CRLF problem
that required fix_encoding.sh after Windows MCP writes.

### Files
- gitattributes/.gitattributes  -- full file (copy to repo root as .gitattributes)

### Apply
```bash
cp _staging/symphony-enforcement-v2/gitattributes/.gitattributes .gitattributes
```

### Verification
```bash
grep 'eol=lf' .gitattributes
```

---

## Full apply sequence

Run from repo root on Ubuntu server:

```bash
# ENF-000
cp _staging/symphony-enforcement-v2/gitattributes/.gitattributes .gitattributes

# ENF-001
bash _staging/symphony-enforcement-v2/enf-001-run-task-drd-gate/apply.sh

# ENF-002
cp _staging/symphony-enforcement-v2/enf-002-verify-drd-casefile/verify_drd_casefile.sh \
   scripts/audit/verify_drd_casefile.sh
chmod +x scripts/audit/verify_drd_casefile.sh
bash _staging/symphony-enforcement-v2/enf-002-verify-drd-casefile/apply_patch.sh

# ENF-003
bash _staging/symphony-enforcement-v2/enf-003-evidence-ack-gate/apply_patch.sh
cp _staging/symphony-enforcement-v2/enf-003-evidence-ack-gate/reset_evidence_gate.sh \
   scripts/audit/reset_evidence_gate.sh
chmod +x scripts/audit/reset_evidence_gate.sh

# ENF-004
cp _staging/symphony-enforcement-v2/enf-004-agent-entrypoint-docs/AGENT_ENTRYPOINT.md \
   AGENT_ENTRYPOINT.md
cp _staging/symphony-enforcement-v2/enf-004-agent-entrypoint-docs/prompt_template.md \
   .agent/prompt_template.md

# Verify
grep "DRD LOCKOUT" scripts/agent/run_task.sh
ls scripts/audit/verify_drd_casefile.sh
grep "evidence_ack" scripts/agent/run_task.sh
ls scripts/audit/reset_evidence_gate.sh
grep "evidence_ack" AGENT_ENTRYPOINT.md
grep "evidence_ack" .agent/prompt_template.md
echo "All ENF tasks applied."
```

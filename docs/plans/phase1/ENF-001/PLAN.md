# PLAN: ENF-001 — DRD lockout gate in run_task.sh

Status: planned
Phase: 1
Task: ENF-001
Agent: ARCHITECT

---

## Mission

Insert a DRD lockout check as the first substantive action in
`scripts/agent/run_task.sh` — before meta parse, OUTDIR creation,
bootstrap, and pack readiness — so no task execution can proceed
while a DRD lockout is active. Exit code 99 matches pre_ci.sh.

---

## Constraints

- `scripts/agent/run_task.sh` is a governance file. **Explicit human approval required before implementation.**
- Use the provided `apply.sh` script — do not edit run_task.sh manually.
- ENF-000 must be done first (encoding hygiene).
- Do not touch `pre_ci.sh`, `pre_ci_debug_contract.sh`, or any other file.

---

## Prerequisites

- ENF-000 evidence shows PASS.
- Human approval recorded for modifying `scripts/agent/run_task.sh`.

---

## Step 1 — Confirm anchor is present

```bash
grep -n 'export TASK_ID' scripts/agent/run_task.sh
```

Expected: exactly one match on a line that starts with `export TASK_ID`.
If not found, do not proceed — report to human.

---

## Step 2 — Apply

```bash
bash symphony-enforcement-v2/enf-001-run-task-drd-gate/apply.sh
```

Expected output: `ENF-001: gate inserted into scripts/agent/run_task.sh after line N`
or `ENF-001: already applied to scripts/agent/run_task.sh -- skipping.`

---

## Step 3 — Verify marker

```bash
grep 'ENF-001: DRD lockout gate' scripts/agent/run_task.sh
```

---

## Step 4 — Negative test (exit 99)

```bash
mkdir -p .toolchain/pre_ci_debug
echo "DRD_LOCKED_SIGNATURE='TEST'" > .toolchain/pre_ci_debug/drd_lockout.env
bash scripts/agent/run_task.sh DUMMY_TASK 2>&1 | head -5
echo "Exit: $?"
rm .toolchain/pre_ci_debug/drd_lockout.env
```

Expected: output includes `DRD LOCKOUT ACTIVE`, exit code is 99.

---

## Step 5 — Create verifier and emit evidence

Create `scripts/audit/verify_enf_001.sh` that:
1. Greps for the ENF-001 marker in `run_task.sh`.
2. Simulates a lockout file, runs `run_task.sh`, asserts exit 99.
3. Confirms no false positive: without lockout, run_task.sh exits non-99.
4. Cleans up the temp lockout file.
5. Emits `evidence/phase1/enf_001_run_task_drd_gate.json`.

```bash
bash scripts/audit/verify_enf_001.sh
```

---

## Verification commands

```bash
bash scripts/audit/verify_enf_001.sh
python3 scripts/audit/validate_evidence.py --task ENF-001 --evidence evidence/phase1/enf_001_run_task_drd_gate.json
bash scripts/dev/pre_ci.sh
```

---

## Evidence paths

- `evidence/phase1/enf_001_run_task_drd_gate.json`

---

## Approval references

`scripts/agent/run_task.sh` is a governance file per SYSTEM INVARIANTS.
Human approval must be on record before this plan moves to `in-progress`.

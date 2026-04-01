# PLAN: ENF-003A — Evidence ack gate + retry counter in run_task.sh

Status: planned
Phase: 1
Task: ENF-003A
Agent: ARCHITECT

---

## Mission

Patch `scripts/agent/run_task.sh` to add three blocks:
1. **Startup gate**: checks `.toolchain/evidence_ack/<TASK_ID>.required` and
   validates a YAML ack file before allowing retry. Exits 51 if ack is missing.
   Exits 50 if retry count >= 3.
2. **Failure increment**: writes `.retries` and `.required` files after a failure.
3. **Success cleanup**: removes `.required` and `.retries` on clean run.

---

## Constraints

- `scripts/agent/run_task.sh` is a governance file. **Explicit human approval required before implementation.**
- ENF-001 must already be applied — `apply_patch.sh` checks for the ENF-001 marker and will exit 1 if absent.
- Do not touch any file outside `scripts/agent/run_task.sh`.

---

## Prerequisites

- ENF-001 evidence shows PASS.
- Human approval recorded for modifying `scripts/agent/run_task.sh`.

---

## Step 1 — Confirm ENF-001 is applied

```bash
grep 'ENF-001: DRD lockout gate' scripts/agent/run_task.sh
```

Must return a match. If not, stop — apply ENF-001 first.

---

## Step 2 — Confirm startup anchor is present

```bash
grep -n 'Pack readiness gate' scripts/agent/run_task.sh
```

Expected: one match. The evidence ack gate is inserted immediately before this line.

---

## Step 3 — Apply

```bash
bash symphony-enforcement-v2/enf-003-evidence-ack-gate/apply_patch.sh
```

Expected: `ENF-003: evidence ack gate applied to scripts/agent/run_task.sh`
or `ENF-003: already applied`.

---

## Step 4 — Verify all three markers

```bash
grep 'ENF-003: evidence ack gate' scripts/agent/run_task.sh
grep 'ENF-003: retry counter increment on failure' scripts/agent/run_task.sh
grep 'ENF-003: cleanup on success' scripts/agent/run_task.sh
```

All three must return matches.

---

## Step 5 — Negative test: exit 51

```bash
mkdir -p .toolchain/evidence_ack
touch .toolchain/evidence_ack/TEST-TASK-ENF003.required
bash scripts/agent/run_task.sh TEST-TASK-ENF003 2>&1 | head -6
echo "Exit: $?"
rm .toolchain/evidence_ack/TEST-TASK-ENF003.required
```

Expected: output includes `EVIDENCE ACK REQUIRED`, exit code is 51.

---

## Step 6 — Negative test: exit 50

```bash
mkdir -p .toolchain/evidence_ack
echo "3" > .toolchain/evidence_ack/TEST-TASK-ENF003.retries
bash scripts/agent/run_task.sh TEST-TASK-ENF003 2>&1 | head -6
echo "Exit: $?"
rm .toolchain/evidence_ack/TEST-TASK-ENF003.retries
```

Expected: output includes `HARD BLOCK`, exit code is 50.

---

## Step 7 — Create verifier and emit evidence

Create `scripts/audit/verify_enf_003a.sh` that automates Steps 4–6 and
emits `evidence/phase1/enf_003a_run_task_evidence_ack_gate.json`.

```bash
bash scripts/audit/verify_enf_003a.sh
```

---

## Verification commands

```bash
bash scripts/audit/verify_enf_003a.sh
python3 scripts/audit/validate_evidence.py --task ENF-003A --evidence evidence/phase1/enf_003a_run_task_evidence_ack_gate.json
bash scripts/dev/pre_ci.sh
```

---

## Evidence paths

- `evidence/phase1/enf_003a_run_task_evidence_ack_gate.json`

---

## Approval references

`scripts/agent/run_task.sh` is a governance file per SYSTEM INVARIANTS.
Human approval must be on record before this plan moves to `in-progress`.

# PLAN: ENF-003B — reset_evidence_gate.sh

Status: planned
Phase: 1
Task: ENF-003B
Agent: SECURITY_GUARDIAN

---

## Mission

Install `scripts/audit/reset_evidence_gate.sh` from the staging package.
This script is the only governed path for a human to clear the ENF-003A
retry hard-block. It logs every reset to an audit trail before deleting
state files.

---

## Constraints

- `scripts/audit/` is the Security Guardian allowed path.
- This script must only be called by humans — it is not invoked by `run_task.sh`.
- Do not touch `scripts/agent/run_task.sh` or any other file.

---

## Prerequisites

- ENF-000 evidence shows PASS.
- No active DRD lockout.

---

## Step 1 — Install reset_evidence_gate.sh

```bash
cp symphony-enforcement-v2/enf-003-evidence-ack-gate/reset_evidence_gate.sh \
   scripts/audit/reset_evidence_gate.sh
chmod +x scripts/audit/reset_evidence_gate.sh
```

Confirm:

```bash
ls -la scripts/audit/reset_evidence_gate.sh
```

---

## Step 2 — Verify --help

```bash
bash scripts/audit/reset_evidence_gate.sh --help 2>&1
echo "Exit: $?"
```

Expected: prints usage with TASK_ID parameter, exits 0.

---

## Step 3 — Negative test: no arguments

```bash
bash scripts/audit/reset_evidence_gate.sh 2>&1
echo "Exit: $?"
```

Expected: exits non-zero with usage message. Must not silently succeed.

---

## Step 4 — Functional test

```bash
mkdir -p .toolchain/evidence_ack
echo "2" > .toolchain/evidence_ack/TEST-ENF003B.retries
touch .toolchain/evidence_ack/TEST-ENF003B.required

bash scripts/audit/reset_evidence_gate.sh TEST-ENF003B

ls .toolchain/evidence_ack/TEST-ENF003B.retries 2>/dev/null && echo "FAIL: retries still exists" || echo "PASS: retries removed"
ls .toolchain/evidence_ack/TEST-ENF003B.required 2>/dev/null && echo "FAIL: required still exists" || echo "PASS: required removed"
grep 'TEST-ENF003B' .toolchain/evidence_ack/reset_log.jsonl && echo "PASS: audit log written"
```

---

## Step 5 — Create verifier and emit evidence

Create `scripts/audit/verify_enf_003b.sh` that automates Steps 2–4 and
emits `evidence/phase1/enf_003b_reset_evidence_gate.json`.

```bash
bash scripts/audit/verify_enf_003b.sh
```

---

## Verification commands

```bash
bash scripts/audit/verify_enf_003b.sh
python3 scripts/audit/validate_evidence.py --task ENF-003B --evidence evidence/phase1/enf_003b_reset_evidence_gate.json
bash scripts/dev/pre_ci.sh
```

---

## Evidence paths

- `evidence/phase1/enf_003b_reset_evidence_gate.json`

---

## Approval references

`scripts/audit/reset_evidence_gate.sh` is in `scripts/audit/` (Security Guardian
allowed path). Standard Security Guardian approval applies.

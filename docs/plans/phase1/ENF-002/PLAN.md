# PLAN: ENF-002 — verify_drd_casefile.sh + pre_ci_debug_contract.sh patch

Status: planned
Phase: 1
Task: ENF-002
Agent: SECURITY_GUARDIAN

---

## Mission

1. Install `scripts/audit/verify_drd_casefile.sh` from the staging package.
2. Patch `scripts/audit/pre_ci_debug_contract.sh` to replace the raw `rm`
   lockout-clear instruction with `bash scripts/audit/verify_drd_casefile.sh --clear`.

---

## Constraints

- Both files are in `scripts/audit/` — Security Guardian allowed path.
- Do not touch `scripts/agent/run_task.sh` or any other file.
- `apply_patch.sh` uses exact Python string replacement — it will error if the anchor is not found.

---

## Prerequisites

- ENF-000 evidence shows PASS.
- No active DRD lockout.

---

## Step 1 — Install verify_drd_casefile.sh

```bash
cp symphony-enforcement-v2/enf-002-verify-drd-casefile/verify_drd_casefile.sh \
   scripts/audit/verify_drd_casefile.sh
chmod +x scripts/audit/verify_drd_casefile.sh
```

Confirm the file is executable:

```bash
ls -la scripts/audit/verify_drd_casefile.sh
```

---

## Step 2 — Verify script behaviour (no lockout)

```bash
bash scripts/audit/verify_drd_casefile.sh
echo "Exit: $?"
```

Expected: exits 0 with a message indicating no lockout is active.

---

## Step 3 — Apply lockout message patch

```bash
bash symphony-enforcement-v2/enf-002-verify-drd-casefile/apply_patch.sh
```

Expected: `ENF-002: lockout message patched in scripts/audit/pre_ci_debug_contract.sh`
or `ENF-002: lockout message patch already applied`.

---

## Step 4 — Confirm patch

```bash
grep 'verify_drd_casefile.sh --clear' scripts/audit/pre_ci_debug_contract.sh
grep 'rm \$PRE_CI_DRD_LOCKOUT_FILE' scripts/audit/pre_ci_debug_contract.sh
```

First grep must return a match. Second grep must return no match.

---

## Step 5 — Negative test (lockout with no casefile)

```bash
mkdir -p .toolchain/pre_ci_debug
echo "DRD_LOCKED_SIGNATURE='TEST'
DRD_LOCKED_GATE_ID='test.gate'
DRD_LOCKED_COUNT=1
DRD_LOCKED_AT='2026-03-29T00:00:00Z'
DRD_SCAFFOLD_CMD='echo test'" > .toolchain/pre_ci_debug/drd_lockout.env
bash scripts/audit/verify_drd_casefile.sh 2>&1
echo "Exit: $?"
rm .toolchain/pre_ci_debug/drd_lockout.env
```

Expected: exits 1 with a message about missing casefile.

---

## Step 6 — Create verifier and emit evidence

Create `scripts/audit/verify_enf_002.sh` that runs all the above checks
and emits `evidence/phase1/enf_002_verify_drd_casefile.json`.

```bash
bash scripts/audit/verify_enf_002.sh
```

---

## Verification commands

```bash
bash scripts/audit/verify_enf_002.sh
python3 scripts/audit/validate_evidence.py --task ENF-002 --evidence evidence/phase1/enf_002_verify_drd_casefile.json
bash scripts/dev/pre_ci.sh
```

---

## Evidence paths

- `evidence/phase1/enf_002_verify_drd_casefile.json`

---

## Approval references

`scripts/audit/pre_ci_debug_contract.sh` is in `scripts/audit/` (Security Guardian
allowed path). Standard Security Guardian approval applies.

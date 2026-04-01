# PLAN: ENF-005 — OS-level sudo gate for drd_lockout.env deletion

Status: planned
Phase: 1
Task: ENF-005
Agent: SECURITY_GUARDIAN

---

## Mission

Replace the direct `rm "$DRD_LOCKOUT_FILE"` inside `verify_drd_casefile.sh --clear`
with a call to a privileged wrapper script (`clear_drd_lockout_privileged.sh`) that
the agent OS user may only invoke via `sudo`. This closes the bypass where any process
that can execute `verify_drd_casefile.sh` could also delete the lockout file directly.

---

## Constraints

- ENF-002 must be complete — `scripts/audit/verify_drd_casefile.sh` must already exist.
- `clear_drd_lockout_privileged.sh` must be owned by root or a supervisor OS user — not the agent process user.
- Do not touch `run_task.sh`, `pre_ci.sh`, `pre_ci_debug_contract.sh`, or any file outside `scripts/audit/`.
- The sudoers entry is a **human-only step** — document it in EXEC_LOG.md; do not attempt to automate it.

---

## Prerequisites

```bash
test -f evidence/phase1/enf_002_verify_drd_casefile.json && \
  python3 -c "import json; d=json.load(open('evidence/phase1/enf_002_verify_drd_casefile.json')); assert d['status']=='PASS'" && \
  echo "ENF-002 PASS confirmed"
```

---

## Step 1 — Create clear_drd_lockout_privileged.sh

Create `scripts/audit/clear_drd_lockout_privileged.sh` with the following behaviour:

1. Hardcode the lockout file path: `ROOT/.toolchain/pre_ci_debug/drd_lockout.env`
2. If the file does not exist: print a message and exit non-zero (no silent success on missing file).
3. Log the deletion to `.toolchain/pre_ci_debug/clear_log.jsonl` with:
   - `timestamp_utc`
   - `action: "lockout_cleared"`
   - `cleared_by: $SUDO_USER` (the agent username that called sudo)
   - `cleared_as: $USER` (the privileged user executing the rm)
4. Delete the lockout file.
5. Exit 0.

Set permissions after creation:

```bash
chmod 750 scripts/audit/clear_drd_lockout_privileged.sh
# Then a human with root must run:
# sudo chown root:root scripts/audit/clear_drd_lockout_privileged.sh
```

The agent must not be in the owning group for write, so the agent cannot rewrite the wrapper.

---

## Step 2 — Patch verify_drd_casefile.sh

Find the `rm` line inside the `--clear` branch of `scripts/audit/verify_drd_casefile.sh`.

Replace:
```bash
rm "$DRD_LOCKOUT_FILE"
```

With:
```bash
sudo "$(dirname "${BASH_SOURCE[0]}")/clear_drd_lockout_privileged.sh"
```

Confirm no other direct `rm` of the lockout path remains:

```bash
grep -n 'rm.*drd_lockout\|rm.*PRE_CI_DRD_LOCKOUT' scripts/audit/verify_drd_casefile.sh
```

Must return no matches.

---

## Step 3 — Document required sudoers entry (human step)

The agent OS user needs a sudoers entry. Record the exact entry in EXEC_LOG.md:

```
# /etc/sudoers.d/symphony-agent
<agent-username> ALL=(root) NOPASSWD: /absolute/path/to/scripts/audit/clear_drd_lockout_privileged.sh
```

Replace `<agent-username>` with the actual OS username under which `run_task.sh` executes.
Replace `/absolute/path/to/` with the actual repo root path.

**A human with root must apply this.** The verifier will warn if it cannot confirm the
entry, but does not hard-block to avoid a chicken-and-egg dependency on external infrastructure.

---

## Step 4 — Create verifier and emit evidence

Create `scripts/audit/verify_enf_005.sh` that:

1. Checks `clear_drd_lockout_privileged.sh` exists and is executable.
2. Greps `verify_drd_casefile.sh` for absence of direct `rm.*drd_lockout`.
3. Greps `verify_drd_casefile.sh` for presence of `sudo.*clear_drd_lockout_privileged`.
4. Greps `clear_drd_lockout_privileged.sh` for presence of `clear_log.jsonl` write and file-existence check.
5. Emits `evidence/phase1/enf_005_drd_lockout_sudo_gate.json` with `sudoers_entry_note` field
   set to `"human_step_required"` (verifier cannot confirm the OS entry).

```bash
bash scripts/audit/verify_enf_005.sh
```

---

## Verification commands

```bash
bash scripts/audit/verify_enf_005.sh
python3 scripts/audit/validate_evidence.py --task ENF-005 --evidence evidence/phase1/enf_005_drd_lockout_sudo_gate.json
bash scripts/dev/pre_ci.sh
```

---

## Evidence paths

- `evidence/phase1/enf_005_drd_lockout_sudo_gate.json`

---

## Sudoers entry (for human to apply)

```
<agent-username> ALL=(root) NOPASSWD: <repo-root>/scripts/audit/clear_drd_lockout_privileged.sh
```

Record in EXEC_LOG.md: who applied it, when, on which host.

---

## Approval references

All changed files are in `scripts/audit/` (Security Guardian allowed path). Standard
Security Guardian approval applies. The sudoers step requires separate sysadmin action.

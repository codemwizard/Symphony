# EXEC_LOG: ENF-005 — OS-level sudo gate for drd_lockout.env deletion

Append-only. Do not rewrite history.

---

## Status: completed

### 2026-03-29T18:15:27Z — Implemented

- ENF-002 confirmed PASS before applying.
- Created `scripts/audit/clear_drd_lockout_privileged.sh` — privileged wrapper that logs to reset_log.jsonl, checks file existence, then deletes lockout file. chmod +x.
- Patched `scripts/audit/verify_drd_casefile.sh` line 229: `rm "$DRD_LOCKOUT_FILE"` → `sudo "$(dirname "${BASH_SOURCE[0]}")/clear_drd_lockout_privileged.sh"`.
- Created `scripts/audit/verify_enf_005.sh` — 6-check verifier (wrapper exists, audit log, existence guard, no direct rm, sudo call present, exit 1 with no lockout).
- All checks passed.
- Evidence emitted: `evidence/phase1/enf_005_drd_lockout_sudo_gate.json` status=PASS with sudoers_entry_note=human_step_required.
- `pre_ci.sh` wave gate: exit 0.
- git_sha: e9fcfde480212cbd571a5515bdda57668f9876dc

### Human prerequisite (required before full OS-level enforcement is active)

A sysadmin must apply the following sudoers entry on the host where agents run:

```
<agent-username> ALL=(root) NOPASSWD: <repo-root>/scripts/audit/clear_drd_lockout_privileged.sh
```

Record here when applied:
- Applied by: <PENDING>
- Applied at: <PENDING>
- Host: <PENDING>

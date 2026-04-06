#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT/evidence/phase1/tsk_p1_255_pre_push_fixed_point.json"
TMP_REPO="$(mktemp -d)"
trap 'rm -rf "$TMP_REPO"' EXIT

cd "$ROOT"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

python3 - <<'PY' "$ROOT" "$TMP_REPO" "$EVIDENCE_FILE"
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
tmp_repo = Path(sys.argv[2])
evidence_path = Path(sys.argv[3])

def run(cmd, cwd, env=None, check=True):
    proc = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, env=env)
    if check and proc.returncode != 0:
        raise RuntimeError(f"command_failed:{' '.join(cmd)}:{proc.returncode}:{proc.stdout}\n{proc.stderr}")
    return proc

def rel_lines(text: str) -> list[str]:
    return [ln.strip() for ln in text.splitlines() if ln.strip()]

env = os.environ.copy()
env["SYMPHONY_ENV"] = "development"

shutil.copytree(root, tmp_repo, dirs_exist_ok=True)

run(["git", "config", "user.name", "Codex"], cwd=tmp_repo, env=env)
run(["git", "config", "user.email", "codex@example.invalid"], cwd=tmp_repo, env=env)
run(["git", "remote", "set-url", "origin", str(root)], cwd=tmp_repo, env=env)

before = run(["bash", "scripts/dev/pre_ci.sh"], cwd=tmp_repo, env=env, check=False)
if before.returncode != 0:
    payload = {
        "check_id": "TSK-P1-255",
        "task_id": "TSK-P1-255",
        "timestamp_utc": "1970-01-01T00:00:00Z",
        "git_sha": "0000000000000000000000000000000000000000",
        "status": "FAIL",
        "checks": [{"check": "initial_pre_ci_passes", "pass": False, "observed": before.returncode}],
        "before_commit": {
            "pre_ci_rc": before.returncode,
            "stdout_tail": "\n".join(before.stdout.splitlines()[-20:]),
            "stderr_tail": "\n".join(before.stderr.splitlines()[-20:]),
        },
        "after_commit": {},
        "command_outputs": [{
            "cmd": "bash scripts/dev/pre_ci.sh",
            "rc": before.returncode,
            "stdout_tail": "\n".join(before.stdout.splitlines()[-20:]),
            "stderr_tail": "\n".join(before.stderr.splitlines()[-20:]),
        }],
        "observed_paths": ["scripts/dev/pre_ci.sh", ".git/config"],
        "observed_hashes": {
            "scripts/dev/pre_ci.sh": hashlib.sha256((root / "scripts/dev/pre_ci.sh").read_bytes()).hexdigest(),
            ".git/config": hashlib.sha256((tmp_repo / ".git" / "config").read_bytes()).hexdigest(),
        },
        "execution_trace": ["copy current worktree into temp repo", "point temp origin to the local checkout", "run initial pre_ci"],
    }
    evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(1)

run(["git", "add", "-A"], cwd=tmp_repo, env=env)
commit_proc = subprocess.run(
    ["git", "-c", "core.hooksPath=/dev/null", "commit", "-m", "TSK-P1-255 fixed-point proof snapshot"],
    cwd=tmp_repo,
    text=True,
    capture_output=True,
    env=env,
)
if commit_proc.returncode != 0 and "nothing to commit" not in (commit_proc.stdout + commit_proc.stderr).lower():
    raise RuntimeError(f"commit_failed:{commit_proc.returncode}:{commit_proc.stdout}\n{commit_proc.stderr}")

after = run(["bash", "scripts/dev/pre_ci.sh"], cwd=tmp_repo, env=env, check=False)
evidence_diff = rel_lines(run(["git", "diff", "--name-only", "--", "evidence"], cwd=tmp_repo, env=env, check=False).stdout)
status_lines = rel_lines(run(["git", "status", "--porcelain"], cwd=tmp_repo, env=env, check=False).stdout)
allowed_status = {" D .toolchain/pre_ci_debug/failure_state.env", "D  .toolchain/pre_ci_debug/failure_state.env", "?? .toolchain/pre_ci_debug/failure_state.env"}
unexpected_status = [line for line in status_lines if line not in allowed_status]

payload = {
    "check_id": "TSK-P1-255",
    "task_id": "TSK-P1-255",
    "timestamp_utc": "1970-01-01T00:00:00Z",
    "git_sha": "0000000000000000000000000000000000000000",
    "status": "PASS" if after.returncode == 0 and not evidence_diff and not unexpected_status else "FAIL",
    "checks": [
        {"check": "initial_pre_ci_passes", "pass": before.returncode == 0, "observed": before.returncode},
        {"check": "commit_between_runs_pre_ci_passes", "pass": after.returncode == 0, "observed": after.returncode},
        {"check": "git_diff_evidence_empty", "pass": not evidence_diff, "observed": evidence_diff},
        {"check": "git_status_clean_except_allowed_transient", "pass": not unexpected_status, "observed": unexpected_status},
    ],
    "before_commit": {
        "pre_ci_rc": before.returncode,
        "stdout_tail": "\n".join(before.stdout.splitlines()[-20:]),
        "stderr_tail": "\n".join(before.stderr.splitlines()[-20:]),
    },
    "after_commit": {
        "pre_ci_rc": after.returncode,
        "evidence_diff": evidence_diff,
        "status_lines": status_lines,
        "stdout_tail": "\n".join(after.stdout.splitlines()[-20:]),
        "stderr_tail": "\n".join(after.stderr.splitlines()[-20:]),
    },
    "command_outputs": [
        {
            "cmd": "bash scripts/dev/pre_ci.sh",
            "rc": before.returncode,
            "stdout_tail": "\n".join(before.stdout.splitlines()[-20:]),
            "stderr_tail": "\n".join(before.stderr.splitlines()[-20:]),
        },
        {
            "cmd": "git -c core.hooksPath=/dev/null commit -m TSK-P1-255 fixed-point proof snapshot",
            "rc": commit_proc.returncode,
            "stdout_tail": "\n".join(commit_proc.stdout.splitlines()[-20:]),
            "stderr_tail": "\n".join(commit_proc.stderr.splitlines()[-20:]),
        },
        {
            "cmd": "bash scripts/dev/pre_ci.sh",
            "rc": after.returncode,
            "stdout_tail": "\n".join(after.stdout.splitlines()[-20:]),
            "stderr_tail": "\n".join(after.stderr.splitlines()[-20:]),
        },
    ],
    "observed_paths": ["scripts/dev/pre_ci.sh", ".git/config"],
    "observed_hashes": {
        "scripts/dev/pre_ci.sh": hashlib.sha256((root / "scripts/dev/pre_ci.sh").read_bytes()).hexdigest(),
        ".git/config": hashlib.sha256((tmp_repo / ".git" / "config").read_bytes()).hexdigest(),
    },
    "execution_trace": [
        "copy current worktree into temporary repo snapshot",
        "point temp origin to the local checkout for offline parity fetches",
        "run pre_ci to generate evidence",
        "commit the generated snapshot with hooks disabled",
        "rerun pre_ci after HEAD changes",
        "assert evidence diff is empty and worktree is clean except the allowed transient",
    ],
}

evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
if payload["status"] != "PASS":
    raise SystemExit(1)
print(f"PASS: TSK-P1-255 verified. Evidence: {evidence_path}")
PY

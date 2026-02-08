#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/remediation_trace.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

# Default range for local usage if not provided. Mirrors enforce_change_rule.sh conventions.
BASE_REF="${BASE_REF:-origin/main}"
HEAD_REF="${HEAD_REF:-HEAD}"

ROOT_DIR="$ROOT_DIR" EVIDENCE_FILE="$EVIDENCE_FILE" BASE_REF="$BASE_REF" HEAD_REF="$HEAD_REF" python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path

from scripts.audit.remediation_trace_lib import RemediationTracePolicy, read_text_best_effort

root = Path(os.environ["ROOT_DIR"])
evidence_out = Path(os.environ["EVIDENCE_FILE"])
base_ref = os.environ.get("BASE_REF", "origin/main")
head_ref = os.environ.get("HEAD_REF", "HEAD")

policy = RemediationTracePolicy()
check_id = "REMEDIATION-TRACE"

def run(cmd: list[str]) -> str:
    p = subprocess.run(cmd, cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"cmd_failed:{' '.join(cmd)}:{p.stderr.strip()}")
    return p.stdout

def staged_changed_files() -> list[str]:
    out = run(["git", "diff", "--name-only", "--cached"])
    files = [ln.strip() for ln in out.splitlines() if ln.strip()]
    return files

def worktree_changed_files() -> list[str]:
    out = run(["git", "diff", "--name-only"])
    files = [ln.strip() for ln in out.splitlines() if ln.strip()]
    return files

def untracked_files() -> list[str]:
    out = run(["git", "ls-files", "--others", "--exclude-standard"])
    files = [ln.strip() for ln in out.splitlines() if ln.strip()]
    return files

def range_changed_files() -> list[str]:
    # If BASE_REF is missing locally (no remote yet), skip instead of failing closed.
    p = subprocess.run(["git", "rev-parse", base_ref], cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        return []
    out = run(["git", "diff", "--name-only", f"{base_ref}...{head_ref}"])
    files = [ln.strip() for ln in out.splitlines() if ln.strip()]
    return files

errors: list[str] = []

try:
    diff_changed = staged_changed_files()
    if diff_changed:
        diff_mode = "staged"
    else:
        diff_changed = worktree_changed_files()
        if diff_changed:
            diff_mode = "worktree"
        else:
            diff_mode = "range"
            diff_changed = range_changed_files()

    # For local workflows, remediation docs are commonly created as new files first.
    # We include untracked docs/plans casefiles as candidates, but we do not let untracked files
    # influence trigger detection (only the diff does).
    untracked = untracked_files() if diff_mode in ("staged", "worktree") else []
except Exception as e:
    out = {
        "check_id": check_id,
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "errors": [f"git_diff_failed:{e}"],
    }
    evidence_out.write_text(json.dumps(out, indent=2) + "\n")
    raise SystemExit(1)

changed_for_trigger = diff_changed
triggered_files = [p for p in changed_for_trigger if policy.is_trigger_file(p)]

if not triggered_files:
    out = {
        "check_id": check_id,
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "SKIPPED",
        "reason": "no_production_affecting_changes",
        "diff_mode": diff_mode,
        "base_ref": base_ref,
        "head_ref": head_ref,
        "changed_files": diff_changed,
        "triggered_files": triggered_files,
    }
    evidence_out.write_text(json.dumps(out, indent=2) + "\n")
    raise SystemExit(0)

trace_candidates = diff_changed + [p for p in untracked if p.startswith("docs/plans/")]
trace_docs = policy.remediation_docs_in_diff(trace_candidates)

rem_docs = [p for p in trace_docs if policy.remediation_casefile_re.match(p)]
tsk_docs = [p for p in trace_docs if policy.fix_task_plan_re.match(p)]

def doc_has_markers(rel: str) -> tuple[bool, list[str]]:
    p = root / rel
    if not p.exists():
        return False, ["missing_on_disk"]
    txt = read_text_best_effort(root, rel)
    mm = policy.missing_markers(txt)
    return (len(mm) == 0), mm

def pair_has_markers(plan_rel: str, log_rel: str) -> tuple[bool, list[str]]:
    """Allow required markers to be satisfied across the PLAN+EXEC_LOG pair."""
    plan_path = root / plan_rel
    log_path = root / log_rel
    missing: list[str] = []
    if not plan_path.exists():
        missing.append(f"missing_on_disk:{plan_rel}")
    if not log_path.exists():
        missing.append(f"missing_on_disk:{log_rel}")
    if missing:
        return False, missing
    combined = read_text_best_effort(root, plan_rel) + "\n\n" + read_text_best_effort(root, log_rel)
    mm = policy.missing_markers(combined)
    return (len(mm) == 0), mm

satisfying_docs: list[str] = []
missing_markers: dict[str, list[str]] = {}

if rem_docs:
    # If any REM casefile doc is present in the diff, treat its parent folder as the remediation casefile
    # and read BOTH files from disk. (Only one file might change in the PR; requiring both to be in-diff
    # would create false failures even when a complete casefile exists in the checkout.)
    # Markers may be satisfied across the pair (folder-level), matching the intent of casefiles.
    by_dir: dict[str, set[str]] = {}
    for rel in rem_docs:
        by_dir.setdefault(str(Path(rel).parent), set()).add(Path(rel).name)

    diag_missing: dict[str, list[str]] = {}
    for d, names in sorted(by_dir.items()):
        plan = f"{d}/PLAN.md"
        log = f"{d}/EXEC_LOG.md"
        ok, mm = pair_has_markers(plan, log)
        if ok:
            satisfying_docs = [plan, log]
            break
        if len(diag_missing) < 12:
            diag_missing[plan] = mm
            diag_missing[log] = mm

    if not satisfying_docs:
        missing_markers = diag_missing
else:
    # Otherwise, allow a normal task plan/log to satisfy the gate iff it contains remediation markers.
    # If either PLAN.md or EXEC_LOG.md is present in the diff, treat its parent folder as the task casefile
    # and read BOTH files from disk.
    by_dir: dict[str, set[str]] = {}
    for rel in tsk_docs:
        by_dir.setdefault(str(Path(rel).parent), set()).add(Path(rel).name)

    diag_missing: dict[str, list[str]] = {}
    for d, names in sorted(by_dir.items()):
        plan = f"{d}/PLAN.md"
        log = f"{d}/EXEC_LOG.md"
        ok, mm = pair_has_markers(plan, log)
        if ok:
            satisfying_docs = [plan, log]
            break
        # Only keep diagnostics; do not fail because unrelated historical TSK plan/log folders exist.
        # If we ultimately fail to find any satisfying casefile, we'll surface these.
        if len(diag_missing) < 12:
            diag_missing[plan] = mm
            diag_missing[log] = mm

    if not satisfying_docs:
        missing_markers = diag_missing

if not satisfying_docs:
    if trace_docs:
        # We found candidate remediation docs in the diff, but none satisfied required markers.
        errors.append(f"remediation_doc_missing_required_markers:{missing_markers}")
    else:
        errors.append("missing_remediation_trace_doc: expected docs/plans/**/REM-*/(PLAN.md|EXEC_LOG.md) or a docs/plans/**/TSK-*/ casefile with required remediation markers")

out = {
    "check_id": check_id,
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "diff_mode": diff_mode,
    "base_ref": base_ref,
    "head_ref": head_ref,
    "changed_files": diff_changed,
    "triggered_files": triggered_files,
    "trace_docs": trace_docs,
    "satisfying_docs": satisfying_docs,
    "errors": errors,
}

evidence_out.parent.mkdir(parents=True, exist_ok=True)
evidence_out.write_text(json.dumps(out, indent=2) + "\n")

if errors:
    print("Remediation trace verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)

print("Remediation trace verification passed")
PY

echo "Remediation trace evidence: $EVIDENCE_FILE"

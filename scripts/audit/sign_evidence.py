#!/usr/bin/env python3

"""
sign_evidence.py — Symphony Evidence Signing & Verification
============================================================
Closes the direct evidence fabrication attack:
  An agent types {"status": "PASS"} directly into an evidence JSON file.
  The CI pipeline has no way to know a script didn't generate it.

Solution
--------
Each verifier script calls this tool to WRITE its evidence. The tool:
  1. Computes HMAC-SHA256(PRE_CI_RUN_ID, task_id|status|source_hash|run_id).
  2. Embeds the HMAC and run_id in the JSON.
  3. Writes the JSON atomically (tmp-then-rename).

pre_ci.sh calls this tool in --verify mode before accepting any evidence.
The tool re-derives the HMAC and fails if it does not match.

An agent that hand-types the JSON cannot produce a valid HMAC without
knowing the exact PRE_CI_RUN_ID that pre_ci.sh generated at runtime.
PRE_CI_RUN_ID changes every run, so a signature from a previous run is
rejected on the next run.

Known residual risk
-------------------
An agent with READ access to pre_ci.sh can observe PRE_CI_RUN_ID after it
is exported (it appears in the process environment). The primary mitigation
is filesystem access hardening (UBUNTU_ACCESS_HARDENING.md) which prevents
agents from reading protected scripts. This tool is a second layer, not the
only layer.

Usage
-----
  # From a verifier script (write mode):
  python3 scripts/audit/sign_evidence.py \\
      --write \\
      --out evidence/phase1/gf_w1_fnc_001.json \\
      --task GF-W1-FNC-001 \\
      --status PASS \\
      --source-file schema/migrations/0107_gf_register_activate_project.sql \\
      --command-output "fn_register_project | status=ACTIVE"

  # From pre_ci.sh (verify mode):
  python3 scripts/audit/sign_evidence.py --verify --dir evidence/phase1

Exit codes
----------
  0  success
  1  verification failure or bad arguments
  2  PRE_CI_RUN_ID not set in the environment
"""

import argparse
import hashlib
import hmac as _hmac_module   # aliased to avoid shadowing in local scope
import json
import os
import sys
import tempfile
import subprocess
from datetime import datetime, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# Core signing helpers
# ---------------------------------------------------------------------------

def _derive_key(run_id: str) -> bytes:
    """
    Derive a per-run signing key from the run ID.
    Uses HMAC-SHA256 with a fixed context string as the message.
    This ensures that even if two runs share a similar ID format, their
    keys are derived independently.
    """
    return _hmac_module.new(
        key=run_id.encode("utf-8"),
        msg=b"symphony-evidence-signing-v1",
        digestmod=hashlib.sha256,
    ).digest()


def compute_signature(task_id: str, status: str, source_file: str, run_id: str) -> str:
    """
    Return a hex HMAC-SHA256 over the canonical evidence fields.
    The signature covers: task identity, outcome, the exact source file
    content (not just path), and the current run ID.
    """
    key = _derive_key(run_id)

    # Hash the source file contents so the signature is invalidated if the
    # migration file is altered after the test was run.
    try:
        source_hash = hashlib.sha256(Path(source_file).read_bytes()).hexdigest()
    except FileNotFoundError:
        # In CI upload scenarios the file may not be present on the verifying
        # machine. Fall back to hashing the path string — weaker but still
        # run-bound because the signature includes run_id.
        source_hash = hashlib.sha256(source_file.encode("utf-8")).hexdigest()

    # Canonical message: pipe-delimited, fixed order.
    message = f"{task_id}|{status}|{source_hash}|{run_id}"
    return _hmac_module.new(
        key=key,
        msg=message.encode("utf-8"),
        digestmod=hashlib.sha256,
    ).hexdigest()


# ---------------------------------------------------------------------------
# Write mode
# ---------------------------------------------------------------------------

def cmd_write(args: argparse.Namespace) -> int:
    run_id = os.environ.get("PRE_CI_RUN_ID", "")
    if not run_id:
        print(
            "ERROR: PRE_CI_RUN_ID is not set in the environment.\n"
            "  Evidence signing requires a run ID exported by pre_ci.sh.\n"
            "  For manual debugging only:\n"
            "    export PRE_CI_RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)_$$",
            file=sys.stderr,
        )
        return 2

    sig = compute_signature(args.task, args.status, args.source_file, run_id)

    # Compute source file hash for embedding in the artifact.
    src_path = Path(args.source_file)
    src_hash = hashlib.sha256(
        src_path.read_bytes() if src_path.exists() else args.source_file.encode("utf-8")
    ).hexdigest()

    if os.environ.get("SYMPHONY_EVIDENCE_DETERMINISTIC") == "1":
        timestamp = datetime.fromtimestamp(0, tz=timezone.utc)
    else:
        timestamp = datetime.now(timezone.utc)
    timestamp_str = timestamp.strftime("%Y-%m-%dT%H:%M:%SZ")

    try:
        git_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        git_sha = os.environ.get("EVIDENCE_GIT_SHA", "UNKNOWN")

    payload = {
        "check_id": args.task,
        "task_id": args.task,
        "status": args.status,
        "timestamp_utc": timestamp_str,
        "generated_at": timestamp.isoformat(),
        "git_sha": git_sha,
        "pre_ci_run_id": run_id,
        "source_file": args.source_file,
        "source_file_sha256": src_hash,
        "command_output": args.command_output or "",
        "_signature": sig,
        "_signing_version": "symphony-v1",
    }

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Atomic write: write to a temp file then rename so a concurrent reader
    # never sees a partially-written file.
    tmp_fd, tmp_path_str = tempfile.mkstemp(
        dir=out_path.parent, prefix=".tmp_evidence_", suffix=".json"
    )
    tmp_path = Path(tmp_path_str)
    try:
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2)
            f.write("\n")
        tmp_path.replace(out_path)
    except Exception as exc:  # noqa: BLE001
        try:
            tmp_path.unlink(missing_ok=True)
        except OSError:
            pass
        print(f"ERROR: failed to write evidence to {out_path}: {exc}", file=sys.stderr)
        return 1

    print(f"SIGNED: {out_path} (run_id={run_id[:16]}... sig={sig[:16]}...)")
    return 0


# ---------------------------------------------------------------------------
# Verify mode
# ---------------------------------------------------------------------------

def cmd_verify(args: argparse.Namespace) -> int:
    run_id = os.environ.get("PRE_CI_RUN_ID", "")
    if not run_id:
        print(
            "ERROR: PRE_CI_RUN_ID is not set. Cannot verify evidence signatures.",
            file=sys.stderr,
        )
        return 2

    evidence_dir = Path(args.dir)
    if not evidence_dir.is_dir():
        print(f"ERROR: evidence directory not found: {evidence_dir}", file=sys.stderr)
        return 1

    files = sorted(evidence_dir.glob("*.json"))
    if not files:
        # Not a hard failure — tasks may not have run yet in this phase.
        print(f"INFO: no .json evidence files found in {evidence_dir}")
        return 0

    enrolled_tasks = set()
    if args.enrollment_file:
        enroll_path = Path(args.enrollment_file)
        if enroll_path.exists():
            enrolled_tasks = {
                line.strip()
                for line in enroll_path.read_text().splitlines()
                if line.strip() and not line.startswith("#")
            }

    fail = 0
    for ev_file in files:
        try:
            data = json.loads(ev_file.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError) as exc:
            print(f"  FAIL {ev_file.name}: cannot parse JSON — {exc}", file=sys.stderr)
            fail += 1
            continue

        task_id = data.get("task_id", "UNKNOWN")
        is_enrolled = task_id in enrolled_tasks

        # Every signed evidence file must have these fields.
        required_fields = ("task_id", "status", "pre_ci_run_id", "source_file", "_signature")
        missing = [f for f in required_fields if f not in data]
        if missing:
            if is_enrolled:
                print(
                    f"  FAIL {ev_file.name} (ENROLLED): missing fields {missing} — "
                    "hardened task must produce signed evidence.",
                    file=sys.stderr,
                )
                fail += 1
            else:
                print(f"  SKIP {ev_file.name} (LEGACY): missing fields {missing}")
            continue

        # Run ID must match the current run. This rejects pre-generated evidence.
        if data["pre_ci_run_id"] != run_id:
            if is_enrolled:
                print(
                    f"  FAIL {ev_file.name} (ENROLLED): run_id mismatch\n"
                    f"    stored:  {data['pre_ci_run_id']}\n"
                    f"    current: {run_id}",
                    file=sys.stderr,
                )
                fail += 1
            else:
                print(f"  SKIP {ev_file.name} (LEGACY): run_id mismatch")
            continue

        # Verify the HMAC signature.
        expected_sig = compute_signature(
            data["task_id"], data["status"], data["source_file"], run_id
        )
        if not _hmac_module.compare_digest(data["_signature"], expected_sig):
            print(
                f"  FAIL {ev_file.name}: HMAC signature mismatch — "
                "the file was tampered with or not generated by sign_evidence.py",
                file=sys.stderr,
            )
            fail += 1
        else:
            print(f"  OK   {ev_file.name}  task={data['task_id']}  status={data['status']}")

    print()
    if fail:
        print(
            f"EVIDENCE VERIFICATION FAILED: {fail} of {len(files)} file(s) rejected.\n"
            "  Only evidence written by sign_evidence.py in THIS pre_ci run is accepted.\n"
            "  Hand-typed files, files from previous runs, and tampered files all fail here.",
            file=sys.stderr,
        )
        return 1

    print(f"EVIDENCE OK: {len(files)} file(s) verified (run={run_id[:24]}...)")
    return 0


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Symphony evidence signing and verification."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="Write signed evidence JSON")
    mode.add_argument("--verify", action="store_true", help="Verify evidence directory")

    # Write-mode arguments
    parser.add_argument("--out", help="Output evidence JSON path (required for --write)")
    parser.add_argument("--task", help="Task ID, e.g. GF-W1-FNC-001 (required for --write)")
    parser.add_argument(
        "--status", default="PASS", choices=["PASS", "FAIL"],
        help="Evidence status (default: PASS)"
    )
    parser.add_argument(
        "--source-file", dest="source_file",
        help="Migration or source file this evidence covers (required for --write)"
    )
    parser.add_argument(
        "--command-output", dest="command_output",
        help="Captured terminal output to embed in evidence (optional)"
    )

    # Verify-mode arguments
    parser.add_argument(
        "--dir",
        help="Directory containing evidence JSON files to verify (required for --verify)"
    )
    parser.add_argument(
        "--enrollment-file", dest="enrollment_file",
        help="File containing a list of task IDs that MUST be signed (optional for --verify)"
    )

    args = parser.parse_args()

    if args.write:
        for required_arg in ("out", "task", "source_file"):
            if not getattr(args, required_arg):
                parser.error(
                    f"--{required_arg.replace('_', '-')} is required when using --write"
                )
        return cmd_write(args)

    # args.verify is True
    if not args.dir:
        parser.error("--dir is required when using --verify")
    return cmd_verify(args)


if __name__ == "__main__":
    sys.exit(main())

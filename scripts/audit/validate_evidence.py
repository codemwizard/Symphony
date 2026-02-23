#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def fail(msg: str) -> int:
    print(msg, file=sys.stderr)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Task evidence validator")
    parser.add_argument("--task", required=True, help="Expected task ID")
    parser.add_argument("--evidence", required=True, help="Evidence JSON path")
    args = parser.parse_args()

    evidence_path = Path(args.evidence)
    if not evidence_path.exists():
        return fail(f"missing_evidence:{evidence_path}")

    try:
        payload = json.loads(evidence_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return fail(f"invalid_json:{evidence_path}:{exc}")

    got_task = str(payload.get("task_id", "")).strip()
    if got_task != args.task:
        return fail(f"task_id_mismatch:expected={args.task}:actual={got_task}")

    status = str(payload.get("status", "")).upper()
    pass_flag = payload.get("pass")
    if status != "PASS" and pass_flag is not True:
        return fail("evidence_not_pass")

    print(f"evidence_ok:{evidence_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

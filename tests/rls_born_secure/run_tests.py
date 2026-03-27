#!/usr/bin/env python3
"""
Adversarial test runner for born-secure RLS lint.

Tests policy expression correctness and table-policy binding.
These tests target lint_rls_born_secure.sh, NOT the scope lint.

Exit 0 = all tests pass. Exit 1 = at least one failure. Exit 2 = setup error.
"""

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
LINT_SCRIPT = REPO_ROOT / "scripts" / "db" / "lint_rls_born_secure.py"
CASES_DIR = Path(__file__).resolve().parent / "cases"
EXPECTED_DIR = Path(__file__).resolve().parent / "expected"

# Use venv python if available
VENV_PYTHON = REPO_ROOT / ".venv" / "bin" / "python3"
PYTHON = str(VENV_PYTHON) if VENV_PYTHON.exists() else "python3"


def run_test(sql_file: Path) -> tuple[bool, str]:
    """Run born-secure lint on a test case and compare against expected output."""
    expected_file = EXPECTED_DIR / (sql_file.stem + ".json")

    if not expected_file.exists():
        return False, f"Missing expected file: {expected_file}"

    expected = json.loads(expected_file.read_text())

    result = subprocess.run(
        [PYTHON, str(LINT_SCRIPT), str(sql_file)],
        capture_output=True,
        text=True,
    )

    # Parse lint output
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError:
        return False, f"Lint produced invalid JSON:\nstdout: {result.stdout}\nstderr: {result.stderr}"

    # Check pass/fail expectation
    if expected["should_pass"]:
        if output["status"] != "PASS":
            found_errors = [v["type"] for v in output.get("violations", [])]
            return False, f"Expected PASS but got FAIL with: {found_errors}"
    else:
        if output["status"] != "FAIL":
            return False, f"Expected FAIL but got PASS"

        # Check expected error types are present
        found_errors = [v["type"] for v in output.get("violations", [])]
        for err in expected["expected_errors"]:
            if err not in found_errors:
                return False, f"Missing expected error '{err}', got: {found_errors}"

    return True, "OK"


def main():
    if not LINT_SCRIPT.exists():
        print(f"ERROR: Lint script not found: {LINT_SCRIPT}", file=sys.stderr)
        sys.exit(2)

    sql_files = sorted(CASES_DIR.glob("*.sql"))
    if not sql_files:
        print("ERROR: No test cases found", file=sys.stderr)
        sys.exit(2)

    passed = 0
    failed = 0
    errors = []

    for sql_file in sql_files:
        ok, msg = run_test(sql_file)
        label = "PASS" if ok else "FAIL"
        print(f"  [{label}] {sql_file.name}: {msg}")

        if ok:
            passed += 1
        else:
            failed += 1
            errors.append((sql_file.name, msg))

    print(f"\n{'='*60}")
    print(f"Born-secure adversarial tests: {passed} passed, {failed} failed")
    print(f"{'='*60}")

    if failed > 0:
        print("\nFailures:")
        for name, msg in errors:
            print(f"  {name}: {msg}")
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()

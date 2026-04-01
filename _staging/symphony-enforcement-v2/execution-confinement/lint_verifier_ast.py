#!/usr/bin/env python3
"""
lint_verifier_ast.py — Structural AST Lint for Verifier Scripts
================================================================
Replaces the string-grep posture lint with a proper structural check.

WHY GREP IS NOT ENOUGH
----------------------
The bash lint checks for the string `psql` anywhere in the file. An agent
defeats this with:
    # psql would go here if DB were available
    grep -q "SECURITY DEFINER" "$MIGRATION_FILE"
The comment contains `psql`, grep finds it, the lint passes, the verifier is
still fake.

WHAT THIS SCRIPT DOES INSTEAD
------------------------------
Strips comment lines, then verifies that `psql` appears as an actual command
token in non-comment code — not inside a comment, not in a variable
assignment string. Also detects the rogue-agent signature pattern (grep
against a source file the agent controls).

TOOL DEPENDENCY
---------------
Python 3.6+ stdlib only (re, subprocess). No external packages required.
Optionally uses shellcheck if present on PATH for syntax validation.

BUGS FIXED vs original:
  - `bool | None` union type annotation replaced with Optional[bool]
    (Python 3.10+ syntax, fails on Ubuntu 20.04/22.04 with Python 3.8/3.9)
  - `list[str]` return annotation replaced with List[str] for same reason
  - `from __future__ import annotations` added for forward-compat
  - `import json` moved to module level (was inside function body)
  - Bare `except Exception` used instead of redundant
    `except (FileNotFoundError, TimeoutExpired, Exception)` which listed
    specific exceptions already covered by the final Exception catch

Usage
-----
  /usr/bin/python3 scripts/audit/lint_verifier_ast.py script.sh [script2.sh ...]

Exit codes
----------
  0  all scripts pass
  1  one or more scripts fail
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Optional

# ---------------------------------------------------------------------------
# Patterns
# ---------------------------------------------------------------------------

# Real psql command invocation — not inside a comment, not a variable value.
_REAL_PSQL_CMD = re.compile(
    r"""
    (?:^|\s)                         # start of line or whitespace
    (?:docker\s+exec\s+\S+\s+)?      # optional: docker exec <container>
    psql                             # the psql command
    (?:\s|$|\\)                      # followed by whitespace, EOL, or continuation
    """,
    re.VERBOSE | re.MULTILINE,
)

# Lines that are entirely a comment
_COMMENT_LINE = re.compile(r"^\s*#")

# Lines where psql appears only inside a comment
_PSQL_ONLY_IN_COMMENT = re.compile(r"^\s*#.*\bpsql\b")

# Rogue-agent signature: grep against a file the agent wrote
_GREP_SOURCE_CHECK = re.compile(
    r"grep\s+.*\$\{?(?:MIGRATION_FILE|REPO_ROOT|script|SQL_FILE)",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Shellcheck integration (optional)
# ---------------------------------------------------------------------------

def _shellcheck_syntax_ok(path: Path) -> Optional[bool]:
    """
    Run shellcheck for syntax validation only.
    Returns:
      False  if shellcheck finds parse-level errors (code < 1100)
      None   if shellcheck is unavailable or errors out
    Never returns True — shellcheck cannot confirm psql is a command node,
    only that the file parses cleanly.
    """
    try:
        result = subprocess.run(
            ["shellcheck", "--shell=bash", "--format=json", str(path)],
            capture_output=True,
            text=True,
            timeout=10,
        )
        findings = json.loads(result.stdout or "[]")
        parse_errors = [f for f in findings if f.get("code", 0) < 1100]
        if parse_errors:
            return False
        return None
    except Exception:  # noqa: BLE001 — shellcheck not available or crashed
        return None


# ---------------------------------------------------------------------------
# Core analysis
# ---------------------------------------------------------------------------

def analyse_script(path: Path) -> List[str]:
    """Return a list of failure reasons. Empty list = PASS."""
    failures: List[str] = []

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"cannot read file: {exc}"]

    lines = text.splitlines()

    # Check 1: is `psql` present at all?
    psql_lines = [(i + 1, line) for i, line in enumerate(lines) if "psql" in line]
    if not psql_lines:
        failures.append(
            "no `psql` found anywhere — this verifier cannot prove database execution"
        )
        return failures

    # Check 2: are ALL psql occurrences inside comments?
    real_psql_lines = [
        (n, ln) for n, ln in psql_lines
        if not _COMMENT_LINE.match(ln) and not _PSQL_ONLY_IN_COMMENT.match(ln)
    ]
    if not real_psql_lines:
        failures.append(
            f"`psql` found on {len(psql_lines)} line(s) but ALL are inside comments.\n"
            + "\n".join(f"    line {n}: {ln.strip()}" for n, ln in psql_lines)
        )
        return failures

    # Check 3: does psql appear as a command invocation in non-comment code?
    non_comment_text = "\n".join(
        line for line in lines if not _COMMENT_LINE.match(line)
    )
    if not _REAL_PSQL_CMD.search(non_comment_text):
        failures.append(
            "`psql` appears in non-comment lines but not as a command invocation. "
            "It may be inside a variable assignment or a string."
        )

    # Check 4: rogue-agent grep-against-source pattern
    grep_hits = [
        (i + 1, line) for i, line in enumerate(lines)
        if _GREP_SOURCE_CHECK.search(line) and not _COMMENT_LINE.match(line)
    ]
    if grep_hits:
        failures.append(
            "script greps against a source file it controls — "
            "rogue-agent pattern: write the string, grep for it, call it a test.\n"
            + "\n".join(f"    line {n}: {ln.strip()}" for n, ln in grep_hits)
        )

    # Check 5: shellcheck syntax (if available)
    if _shellcheck_syntax_ok(path) is False:
        failures.append(
            "shellcheck reports bash parse errors — "
            "script may be syntactically invalid"
        )

    return failures


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage: lint_verifier_ast.py <script.sh> [script2.sh ...]\n"
            "  Verifies each script contains a real psql command invocation,\n"
            "  not just the string in a comment or a grep-only fake test.",
            file=sys.stderr,
        )
        return 1

    paths = [Path(p) for p in sys.argv[1:]]
    fail_count = 0

    for path in paths:
        if not path.exists():
            print(f"  SKIP (not found): {path}")
            continue
        failures = analyse_script(path)
        if failures:
            print(f"  FAIL: {path}")
            for reason in failures:
                print(f"    - {reason}")
            fail_count += 1
        else:
            print(f"  PASS: {path}")

    print()
    if fail_count:
        print(
            f"AST LINT FAILED: {fail_count} script(s) lack valid database execution.\n"
            "\n"
            "  Fix: write a real psql invocation:\n"
            "    docker exec symphony-postgres psql -U symphony -d $DB \\\n"
            '        -v ON_ERROR_STOP=1 -tc "SELECT ..."',
            file=sys.stderr,
        )
        return 1

    print(f"AST LINT OK: {len(paths)} script(s) checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

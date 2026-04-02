#!/usr/bin/env python3
"""
task_declarative_verifier.py — DVF Trusted Runner v4
Owned by ci_harness_owner. Never modified by agents.
"""
import argparse, json, os, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path
try:
    import yaml
except ImportError:
    print("FATAL: PyYAML not installed. Run: pip3 install pyyaml", file=sys.stderr)
    sys.exit(1)
# Runners implemented in v1; json/process reserved for Phase 2
IMPLEMENTED_RUNNERS = {"sql", "filesystem"}
WHITELISTED_RUNNERS = {"sql", "filesystem", "json", "process"}
WHITELISTED_EXPECTS = {"row_exists", "row_not_exists", "no_regex", "has_regex",
                       "json_path_equals", "exit_zero"}
TAUTOLOGY_PATTERNS = [
    r"IS\s+NOT\s+NULL", r"IS\s+NULL", r"!=\s*''", r"<>\s*''",
    r"LIKE\s+'%'", r"\b1\s*=\s*1\b", r"\bTRUE\b",
]
DDL_KEYWORDS = r"(?i)\b(CREATE|ALTER|DROP)\s+(TABLE|INDEX|FUNCTION|TRIGGER|POLICY|SCHEMA)\b"
DML_KEYWORDS = r"(?i)\b(INSERT|UPDATE|DELETE|TRUNCATE)\b"
DANGEROUS_FUNCTIONS = r"(?i)\b(pg_sleep|lo_import|lo_export|pg_read_file|pg_read_binary_file|pg_write_file|pg_execute_server_program|COPY)\b"
DB_CONTAINER = os.environ.get("DB_CONTAINER", "symphony-postgres")
DB_USER = os.environ.get("POSTGRES_USER", "symphony_command")
DB_NAME = os.environ.get("POSTGRES_DB", "symphony")
def fail(code: str, msg: str):
    print(f"DVF_FAIL [{code}]: {msg}", file=sys.stderr)
    sys.exit(1)
def load_required_checks(task_id: str):
    rc_path = Path(f"scripts/audit/required_checks/{task_id}.yml")
    if not rc_path.exists():
        return None  # Legacy task — no scope enforcement
    data = yaml.safe_load(rc_path.read_text(encoding="utf-8"))
    if data.get("task_id") != task_id:
        fail("RC_TASK_MISMATCH", f"required_checks task_id != {task_id}")
    return data
def load_verify_yml(task_id: str):
    vy_path = Path(f"tasks/{task_id}/verify.yml")
    if not vy_path.exists():
        fail("MISSING_VERIFY_YML", f"tasks/{task_id}/verify.yml not found")
    data = yaml.safe_load(vy_path.read_text(encoding="utf-8"))
    if data.get("version") != 1:
        fail("SCHEMA_VERSION", "verify.yml version must be 1")
    if data.get("task_id") != task_id:
        fail("TASK_MISMATCH", f"verify.yml task_id != {task_id}")
    return data
def validate_checks(verify: dict, required: dict | None):
    checks = verify.get("checks", [])
    if not checks:
        fail("EMPTY_CHECKS", "verify.yml has no checks")
    for c in checks:
        if c.get("runner") not in WHITELISTED_RUNNERS:
            fail("BAD_RUNNER", f"runner '{c.get('runner')}' not in whitelist")
        if c.get("expect") not in WHITELISTED_EXPECTS:
            fail("BAD_EXPECT", f"expect '{c.get('expect')}' not in whitelist")
    # Scope coverage
    if required:
        required_tags = {rc["tag"] for rc in required.get("checks", [])}
        provided_tags = {c["tag"] for c in checks}
        missing = required_tags - provided_tags
        if missing:
            fail("SCOPE_VIOLATION", f"verify.yml missing required tags: {missing}")
    # SQL quality gate
    for c in checks:
        if c.get("runner") != "sql":
            continue
        query = c.get("query", "")
        # No DDL in queries
        if re.search(DDL_KEYWORDS, query):
            fail("DDL_IN_QUERY", f"DDL keyword in query for tag '{c['tag']}'")
        # No DML in queries (verification must be read-only)
        if re.search(DML_KEYWORDS, query):
            fail("DML_IN_QUERY", f"DML keyword in query for tag '{c['tag']}'")
        # No dangerous Postgres functions
        if re.search(DANGEROUS_FUNCTIONS, query):
            fail("DANGEROUS_FUNCTION", f"Dangerous function in query for tag '{c['tag']}'")
        # LIMIT 1 for row_exists (allow trailing semicolons and whitespace)
        if c.get("expect") == "row_exists" and not re.search(r"LIMIT\s+1\s*;?\s*$", query.strip(), re.IGNORECASE):
            fail("NO_LIMIT", f"row_exists query must end with LIMIT 1: tag '{c['tag']}'")
        # Tautology detection
        for pat in TAUTOLOGY_PATTERNS:
            if re.search(pat, query, re.IGNORECASE):
                fail("TAUTOLOGY", f"Tautology '{pat}' in query for tag '{c['tag']}'")
        # WHERE value enforcement (from locked required_checks)
        if required:
            rc = next((r for r in required["checks"] if r["tag"] == c["tag"]), None)
            if rc and "minimum_where_values" in rc:
                # Extract text after the final WHERE keyword
                where_parts = re.split(r"\bWHERE\b", query, flags=re.IGNORECASE)
                if len(where_parts) < 2:
                    fail("NO_WHERE", f"SQL missing WHERE clause: tag '{c['tag']}'")
                where_text = where_parts[-1]  # text after final WHERE
                for col, expected_val in rc["minimum_where_values"].items():
                    pattern = rf"\b{re.escape(col)}\b\s*=\s*'{re.escape(expected_val)}'"
                    if not re.search(pattern, where_text, re.IGNORECASE):
                        fail("SQL_QUALITY",
                             f"WHERE for '{col}' must contain literal "
                             f"'{expected_val}': tag '{c['tag']}'")
    # Filesystem path and pattern safety
    for c in checks:
        if c.get("runner") == "filesystem":
            fpath = c.get("file", "")
            if ".." in fpath or fpath.startswith("/"):
                fail("PATH_ESCAPE", f"Unsafe file path: {fpath}")
            if not c.get("pattern"):
                fail("MISSING_PATTERN", f"Runner 'filesystem' requires a regex pattern: tag '{c['tag']}'")
def execute_check(check):
    tag = check["tag"]
    runner = check["runner"]
    expect = check["expect"]
    # Fail-hard for runners not yet implemented
    if runner not in IMPLEMENTED_RUNNERS:
        fail("NOT_IMPLEMENTED",
             f"Runner '{runner}' is whitelisted but not yet implemented "
             f"(reserved for Phase 2): tag '{tag}'")
    if runner == "sql":
        query = check["query"]
        try:
            result = subprocess.run(
                ["docker", "exec", DB_CONTAINER,
                 "psql", "-U", DB_USER, "-d", DB_NAME,
                 "-v", "ON_ERROR_STOP=1", "-tAc", query],
                capture_output=True, text=True, timeout=10
            )
        except subprocess.TimeoutExpired:
            return {"tag": tag, "passed": False, "detail": "query timed out (10s)"}
        if result.returncode != 0:
            return {"tag": tag, "passed": False,
                    "detail": f"psql error: {result.stderr.strip()[:200]}"}
        row_returned = bool(result.stdout.strip())
        if expect == "row_exists":
            return {"tag": tag, "passed": row_returned,
                    "detail": result.stdout.strip() or "(no rows)"}
        elif expect == "row_not_exists":
            return {"tag": tag, "passed": not row_returned,
                    "detail": result.stdout.strip() or "(no rows)"}
    elif runner == "filesystem":
        fpath = check["file"]
        if not Path(fpath).exists():
            return {"tag": tag, "passed": False, "detail": f"file not found: {fpath}"}
        content = Path(fpath).read_text(encoding="utf-8")
        pattern = check["pattern"]
        if expect == "no_regex":
            match = re.search(pattern, content)
            return {"tag": tag, "passed": match is None,
                    "detail": f"match: {match.group()}" if match else "clean"}
        elif expect == "has_regex":
            match = re.search(pattern, content)
            return {"tag": tag, "passed": match is not None,
                    "detail": f"found: {match.group()}" if match else "not found"}
    return {"tag": tag, "passed": False, "detail": f"unhandled expect type: {expect}"}
def emit_evidence(task_id: str, results: list):
    run_id = os.environ.get("SYMPHONY_RUN_ID", "")
    git_sha = os.environ.get("SYMPHONY_GIT_SHA", "")
    ts = os.environ.get("SYMPHONY_RUN_TS_UTC",
                        datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    evidence = {
        "task_id": task_id,
        "run_id": run_id,
        "git_sha": git_sha,
        "timestamp_utc": ts,
        "status": "PASS",
        "runner_version": "dvf-v1",
        "scope_coverage": "FULL",
        "checks": results,
    }
    out_path = Path(f"tasks/{task_id}/evidence.json")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(evidence, f, indent=2)
        f.write("\n")
    print(f"DVF_EVIDENCE: {out_path} (run_id={run_id[:20]}...)")
def main():
    parser = argparse.ArgumentParser(description="DVF Trusted Runner")
    parser.add_argument("--task", required=True)
    parser.add_argument("--phase", required=True, choices=["lint", "pre", "post"])
    args = parser.parse_args()
    os.chdir(os.environ.get("SYMPHONY_ROOT",
             str(Path(__file__).resolve().parents[2])))
    required = load_required_checks(args.task)
    verify = load_verify_yml(args.task)
    validate_checks(verify, required)
    if args.phase == "lint":
        print(f"DVF_LINT_PASS: {args.task}")
        return
    is_idempotent = required.get("idempotent", False) if required else False
    results = [execute_check(c) for c in verify["checks"]]
    if args.phase == "pre":
        if is_idempotent:
            print(f"DVF_PRE_SKIP: {args.task} (idempotent, set in locked required_checks)")
            return
        for r in results:
            if r["passed"]:
                fail("HALLUCINATED_PROOF",
                     f"Check '{r['tag']}' passed BEFORE implementation — "
                     f"proof is trivially true or data pre-exists")
        print(f"DVF_PRE_PASS: {args.task} (all checks correctly FAIL)")
    elif args.phase == "post":
        for r in results:
            if not r["passed"]:
                fail("PROOF_FAILURE",
                     f"Check '{r['tag']}' FAILED after implementation: {r['detail']}")
        emit_evidence(args.task, results)
        print(f"DVF_POST_PASS: {args.task} (all checks PASS, evidence emitted)")
if __name__ == "__main__":
    main()

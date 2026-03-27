#!/usr/bin/env python3

import argparse
import re
import sys
import yaml  # type: ignore
from pathlib import Path

FAIL = 1
PASS = 0


# ----------------------------
# Utility
# ----------------------------

def die(msg):
    print(f"[FAIL] {msg}")
    sys.exit(FAIL)


def warn(msg):
    print(f"[WARN] {msg}")


def ok(msg):
    print(f"[OK] {msg}")


# ----------------------------
# Loaders
# ----------------------------

def load_text(path: Path) -> str:
    if not path.exists():
        die(f"File not found: {path}")
    return path.read_text()


def load_yaml(path: Path) -> dict:
    try:
        data = yaml.safe_load(load_text(path))
        return data if isinstance(data, dict) else {}
    except Exception as e:
        die(f"YAML parse error: {e}")
        return {}


# ----------------------------
# ID Extraction
# ----------------------------

ID_PATTERN = re.compile(r"\[ID ([^\]]+)\]")

def extract_ids(text: str):
    return ID_PATTERN.findall(text)


# ----------------------------
# Section Parsing
# ----------------------------

def extract_sections(plan_text: str) -> dict:
    sections: dict[str, list[str]] = {}
    current = None

    for line in plan_text.splitlines():
        m = re.match(r"^##\s+(.*)", line.strip())
        if m:
            current = str(m.group(1).strip())
            sections[current] = []
        elif isinstance(current, str):
            sections[current].append(line)

    return {k: "\n".join(v).strip() for k, v in sections.items()}


# ----------------------------
# Graph Validation (REAL)
# ----------------------------

def check_graph(meta: dict):
    raw_work = meta.get("work", [])
    raw_acc = meta.get("acceptance_criteria", [])
    raw_ver = meta.get("verification", [])
    
    work = list(raw_work) if isinstance(raw_work, list) else []
    acceptance = list(raw_acc) if isinstance(raw_acc, list) else []
    verification = list(raw_ver) if isinstance(raw_ver, list) else []

    if not work or not acceptance or not verification:
        die("Graph incomplete: missing work / acceptance / verification")

    work_ids = set()
    acc_ids = set()
    ver_ids = set()

    for w in work:
        ids = extract_ids(str(w))
        if not ids:
            die(f"Work item missing ID: {w}")
        work_ids.update(ids)

    for a in acceptance:
        ids = extract_ids(str(a))
        if not ids:
            die(f"Acceptance missing ID: {a}")
        acc_ids.update(ids)

    for v in verification:
        ids = extract_ids(str(v))
        ver_ids.update(ids)

    # Enforce mapping
    for wid in work_ids:
        if wid not in acc_ids:
            die(f"Work ID not mapped to acceptance: {wid}")

    for aid in acc_ids:
        if aid not in ver_ids:
            die(f"Acceptance ID not mapped to verification: {aid}")

    ok("Proof graph fully connected via IDs")


# ----------------------------
# Verifier Integrity
# ----------------------------

NO_OP_PATTERNS = [
    r"\bexit\s+0\b",
    r"\becho\s+PASS\b",
    r"\btrue\b"
]

SELF_REF_PATTERNS = [
    r"plan\.md",
    r"meta\.yml"
]

CHECK_CMDS = ["grep", "test", "jq", "ls", "cat"]

FAIL_GUARD = [
    r"\|\|\s*exit\s+1",
    r"\bset\s+-e\b",
    r"\bgrep\b.*\|\|",
]

def has_failure_path(cmd: str):
    return (
        "|| exit" in cmd
        or "set -e" in cmd
        or re.search(r"\|\|.*exit", cmd)
    )


def check_verifiers(meta: dict):
    raw_verification = meta.get("verification", [])
    verification = list(raw_verification) if isinstance(raw_verification, list) else []

    if not verification:
        die("No verification commands")

    for raw in verification:
        cmd = str(raw).lower()

        # No-op detection
        for pat in NO_OP_PATTERNS:
            if re.search(pat, cmd):
                die(f"No-op verifier: {raw}")

        # Self reference
        for pat in SELF_REF_PATTERNS:
            if re.search(pat, cmd):
                die(f"Self-referential verifier: {raw}")

        # Must inspect state
        if not any(c in cmd for c in CHECK_CMDS):
            die(f"No external state inspection: {raw}")

        # Must have failure path
        if not has_failure_path(cmd):
            die(f"Verifier lacks failure path: {raw}")

    ok("Verifier integrity enforced")


# ----------------------------
# Evidence Binding
# ----------------------------

STRONG_FIELDS = [
    "observed_paths",
    "observed_hashes",
    "command_outputs",
    "execution_trace"
]

WRITE_PATTERNS = [
    r">",
    r">>",
    r"tee"
]

def check_evidence(meta: dict):
    raw_evidence = meta.get("evidence", [])
    raw_verification = meta.get("verification", [])
    
    evidence = list(raw_evidence) if isinstance(raw_evidence, list) else []
    verification = list(raw_verification) if isinstance(raw_verification, list) else []

    if not evidence:
        die("No evidence declared")

    for ev in evidence:
        if not isinstance(ev, dict):
            continue
            
        raw_must = ev.get("must_include", [])
        must = list(raw_must) if isinstance(raw_must, list) else []
        
        path = str(ev.get("path", ""))

        # Strong fields
        for field in STRONG_FIELDS:
            if field not in must:
                die(f"Missing strong evidence field: {field}")

        # Must be written by verification
        matched = False
        for v in verification:
            v_str = str(v)
            if path in v_str and any(p in v_str for p in WRITE_PATTERNS):
                matched = True
                break

        if not matched:
            die(f"Evidence not written by verifier: {path}")

    ok("Evidence binding enforced")


# ----------------------------
# Weak Signal Detection
# ----------------------------

WEAK_TERMS = ["appropriate", "correct", "ensure", "should"]

def weak_signal_score(plan_text: str):
    score: int = 0
    for line in plan_text.splitlines():
        if "done when" in line.lower():
            for term in WEAK_TERMS:
                if term in line.lower():
                    score = int(score) + 1
    return score


# ----------------------------
# Main
# ----------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--meta", required=True)
    args = parser.parse_args()

    plan_text = load_text(Path(args.plan))
    meta = load_yaml(Path(args.meta))

    # Core checks
    check_graph(meta)
    check_verifiers(meta)
    check_evidence(meta)

    # Weak signals
    score = weak_signal_score(plan_text)
    print(f"[INFO] Weak signal score: {score}")

    if int(score) >= 3:
        die("Weak signal threshold exceeded")

    ok("Proof graph integrity PASSED")
    sys.exit(PASS)


if __name__ == "__main__":
    main()

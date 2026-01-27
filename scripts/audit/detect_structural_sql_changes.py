#!/usr/bin/env python3
"""
detect_structural_sql_changes.py

Narrower detector: flags structural SQL signals only (DDL/constraints/index).
Used by unit tests and as a helper in enforce_change_rule if desired.

Outputs JSON:
{"structural_change": true|false, "matches":[...]}
"""
from __future__ import annotations
import argparse, json, re
from pathlib import Path
from typing import List, Dict, Optional

DDL_PATTERNS = [
    r"\bCREATE\s+TABLE\b",
    r"\bALTER\s+TABLE\b",
    r"\bDROP\s+TABLE\b",
    r"\bCREATE\s+(UNIQUE\s+)?INDEX\b",
    r"\bDROP\s+INDEX\b",
    r"\bADD\s+COLUMN\b",
    r"\bDROP\s+COLUMN\b",
    r"\bALTER\s+COLUMN\b",
    r"\bADD\s+CONSTRAINT\b",
    r"\bDROP\s+CONSTRAINT\b",
    r"\bREFERENCES\b",
    r"\bCHECK\s*\(",
    r"\bSET\s+NOT\s+NULL\b",
]

def _strip(line: str) -> Optional[str]:
    if line.startswith("+++") or line.startswith("---"):
        return None
    if line.startswith("+") or line.startswith("-"):
        return line[1:].strip()
    return None

def scan(diff_text: str) -> Dict:
    current_file = ""
    matches: List[Dict] = []
    structural = False

    for raw in diff_text.splitlines():
        if raw.startswith("+++ b/"):
            current_file = raw[len("+++ b/"):].strip()
            continue
        if raw.startswith("--- a/"):
            continue
        if raw.startswith("diff --git") or raw.startswith("index ") or raw.startswith("@@"):
            continue

        content = _strip(raw)
        if not content:
            continue

        for pat in DDL_PATTERNS:
            if re.search(pat, content, flags=re.IGNORECASE):
                structural = True
                matches.append({"pattern": pat, "line": content[:300], "file": current_file})
                break

    return {"structural_change": bool(structural), "matches": matches[:200]}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--diff-file", required=True)
    ap.add_argument("--out", required=False)
    args = ap.parse_args()

    p = Path(args.diff_file)
    if not p.exists():
        raise SystemExit(f"Diff file not found: {p}")

    result = scan(p.read_text(encoding="utf-8", errors="ignore"))
    out = json.dumps(result, indent=2)
    if args.out:
        Path(args.out).write_text(out, encoding="utf-8")
    else:
        print(out)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
detect_structural_changes.py

Conservative, dependency-free detector for "invariant-affecting" changes based on a unified git diff.

It is intentionally heuristic (not a SQL parser). The goal is **noise control**:
- return structural_change=true only when we see strong signals (DDL/constraints/indexes/privileges/security).
- allow false negatives over false positives; exceptions exist for emergencies/edge cases.

Output JSON:
{
  "structural_change": true|false,
  "confidence_hint": 0.0-1.0,
  "matches": [{"type": "...", "pattern": "...", "line": "...", "file": "...", "sign": "+"|"-"}],
  "summary": "..."
}
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Optional

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
    r"\bCREATE\s+TYPE\b",
    r"\bALTER\s+TYPE\b",
    r"\bDROP\s+TYPE\b",
    r"\bCREATE\s+EXTENSION\b",
]

SECURITY_PATTERNS = [
    r"\bGRANT\b",
    r"\bREVOKE\b",
    r"\bALTER\s+DEFAULT\s+PRIVILEGES\b",
    r"\bSECURITY\s+DEFINER\b",
    r"\bSECURITY\s+INVOKER\b",
    r"\bsearch_path\b",
    r"\bSET\s+ROLE\b",
    r"\bCREATE\s+ROLE\b",
    r"\bALTER\s+ROLE\b",
    r"\bDROP\s+ROLE\b",
    r"\bOWNER\s+TO\b",
]

# Strong signals that something migration-like happened even without token hits:
MIGRATION_PATH_RE = re.compile(r"(^|/)schema/migrations/|(^|/)migrations/", re.IGNORECASE)
MIGRATION_FILE_RE = re.compile(r"(^|/)\d{4}.*\.sql$|(^|/)\d{4}_.+\.sql$|(^|/)0+\d+_.+\.sql$", re.IGNORECASE)

# Detect "new file mode" / "deleted file mode" in diff headers
NEW_FILE_RE = re.compile(r"^new file mode\s+\d+")
DELETED_FILE_RE = re.compile(r"^deleted file mode\s+\d+")

# Files that are *likely* invariant-touching, used only as a confidence boost (not as a trigger).
HIGH_CONF_PATHS = (
    "schema/migrations/",
    "scripts/db/",
    "scripts/audit/",
    "libs/db/",
)

def _is_header_line(line: str) -> bool:
    return line.startswith("diff --git") or line.startswith("index ") or line.startswith("@@")

def _strip_diff_sign(line: str) -> Optional[str]:
    if line.startswith("+++") or line.startswith("---"):
        return None
    if line.startswith("+") or line.startswith("-"):
        return line[1:].strip()
    return None

def _score_for_type(t: str) -> float:
    if t == "ddl":
        return 0.85
    if t == "security":
        return 0.80
    if t == "migration_file_added_or_deleted":
        return 0.70
    return 0.30

def scan(diff_text: str) -> Dict:
    current_file: str = ""
    matches: List[Dict] = []
    structural = False
    score = 0.0

    # track whether we saw a migration file added/deleted (even without token hits)
    saw_migration_add_del = False

    for raw in diff_text.splitlines():
        # Track current file path from +++ b/...
        if raw.startswith("+++ b/"):
            current_file = raw[len("+++ b/"):].strip()
            continue
        if raw.startswith("--- a/"):
            continue

        # Detect new/deleted file mode (applies to the next file header usually)
        if NEW_FILE_RE.match(raw) or DELETED_FILE_RE.match(raw):
            # if we're in a migration file context, treat as structural
            if current_file and (MIGRATION_PATH_RE.search(current_file) or MIGRATION_FILE_RE.search(current_file)):
                saw_migration_add_del = True
            continue

        if _is_header_line(raw):
            continue

        content = _strip_diff_sign(raw)
        if content is None or content == "":
            continue

        sign = "+" if raw.startswith("+") else "-"

        # DDL patterns
        for pat in DDL_PATTERNS:
            if re.search(pat, content, flags=re.IGNORECASE):
                structural = True
                matches.append({
                    "type": "ddl",
                    "pattern": pat,
                    "line": content[:300],
                    "file": current_file,
                    "sign": sign,
                })
                score += _score_for_type("ddl")
                break

        # Security/privilege patterns
        for pat in SECURITY_PATTERNS:
            if re.search(pat, content, flags=re.IGNORECASE):
                structural = True
                matches.append({
                    "type": "security",
                    "pattern": pat,
                    "line": content[:300],
                    "file": current_file,
                    "sign": sign,
                })
                score += _score_for_type("security")
                break

    if saw_migration_add_del:
        structural = True
        matches.append({
            "type": "migration_file_added_or_deleted",
            "pattern": "new/deleted migration file",
            "line": "(migration file added or deleted)",
            "file": current_file,
            "sign": "+",
        })
        score += _score_for_type("migration_file_added_or_deleted")

    # Confidence boost if touched files fall under high-confidence paths
    boost = 0.0
    for m in matches:
        f = m.get("file") or ""
        for hp in HIGH_CONF_PATHS:
            if f.startswith(hp):
                boost = max(boost, 0.10)
    score = min(1.0, score + boost)

    confidence_hint = round(score if structural else 0.0, 2)
    summary = "No structural invariant-affecting changes detected."
    if structural:
        summary = f"Structural or privilege/security changes detected (confidence_hint={confidence_hint})."

    return {
        "structural_change": bool(structural),
        "confidence_hint": confidence_hint,
        "matches": matches[:200],
        "summary": summary,
    }

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--diff-file", required=True, help="Path to unified diff text file")
    ap.add_argument("--out", required=False, help="Optional path to write JSON")
    args = ap.parse_args()

    diff_path = Path(args.diff_file)
    if not diff_path.exists():
        raise SystemExit(f"Diff file not found: {diff_path}")

    diff_text = diff_path.read_text(encoding="utf-8", errors="ignore")
    result = scan(diff_text)
    out = json.dumps(result, indent=2)

    if args.out:
        Path(args.out).write_text(out, encoding="utf-8")
    else:
        print(out)

if __name__ == "__main__":
    main()

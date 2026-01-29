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
  "reason_types": ["ddl","security",...],
  "primary_reason": "ddl|security|migration_file_added_or_deleted|other",
  "matched_files": ["path1",...],
  "match_counts": {"ddl":1,...},
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

DDL_ELIGIBLE_PREFIXES = (
    "schema/migrations/",
    "migrations/",
)

SECURITY_ELIGIBLE_PREFIXES = (
    "schema/migrations/",
    "migrations/",
    "scripts/security/",
    "scripts/db/",
    ".github/workflows/",
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

def _is_sql_file(path: str) -> bool:
    return path.lower().endswith(".sql")

def _has_prefix(path: str, prefixes) -> bool:
    return any(path.startswith(p) for p in prefixes)

def _eligible_for(kind: str, path: str) -> bool:
    if not path:
        return False
    if kind == "ddl":
        return _is_sql_file(path) and _has_prefix(path, DDL_ELIGIBLE_PREFIXES)
    if kind == "security":
        return (
            (_is_sql_file(path) and _has_prefix(path, ("schema/migrations/", "migrations/")))
            or _has_prefix(path, ("scripts/security/", "scripts/db/", ".github/workflows/"))
        )
    if kind == "migration_file_added_or_deleted":
        return _is_sql_file(path) and (
            MIGRATION_PATH_RE.search(path) is not None or MIGRATION_FILE_RE.search(path) is not None
        )
    return False

def scan(diff_text: str) -> Dict:
    current_file: str = ""
    matches: List[Dict] = []
    structural = False
    score = 0.0

    # track whether we saw a migration file added/deleted (even without token hits)
    saw_migration_add_del = False
    saw_migration_add_del_file: Optional[str] = None

    match_counts: Dict[str, int] = {}
    matched_files_set = set()
    reason_types_set = set()
    primary_reason: Optional[str] = None
    primary_reason_score = 0.0

    def record(kind: str, pat: str, content: str, sign: str) -> None:
        nonlocal structural, score, primary_reason, primary_reason_score
        matches.append({
            "type": kind,
            "pattern": pat,
            "line": content[:300],
            "file": current_file,
            "sign": sign,
        })

        if not _eligible_for(kind, current_file):
            return

        structural = True
        score += _score_for_type(kind)
        match_counts[kind] = match_counts.get(kind, 0) + 1
        matched_files_set.add(current_file)
        reason_types_set.add(kind)

        s = _score_for_type(kind)
        if s > primary_reason_score:
            primary_reason_score = s
            primary_reason = kind

    for raw in diff_text.splitlines():
        # Capture file from diff header early (new file mode can appear before +++).
        if raw.startswith("diff --git "):
            parts = raw.split()
            if len(parts) >= 4 and parts[-1].startswith("b/"):
                current_file = parts[-1][2:]
            else:
                current_file = ""
            continue

        # Track current file path from +++ b/...
        if raw.startswith("+++ b/"):
            current_file = raw[len("+++ b/"):].strip()
            continue
        if raw.startswith("--- a/") or raw.startswith("--- /dev/null"):
            continue

        # Detect new/deleted file mode (applies to the next file header usually)
        if NEW_FILE_RE.match(raw) or DELETED_FILE_RE.match(raw):
            # if we're in a migration file context, treat as structural
            if current_file and _eligible_for("migration_file_added_or_deleted", current_file):
                saw_migration_add_del = True
                saw_migration_add_del_file = current_file
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
                record("ddl", pat, content, sign)
                break

        # Security/privilege patterns
        for pat in SECURITY_PATTERNS:
            if re.search(pat, content, flags=re.IGNORECASE):
                record("security", pat, content, sign)
                break

    if saw_migration_add_del and saw_migration_add_del_file:
        current_file = saw_migration_add_del_file
        record(
            "migration_file_added_or_deleted",
            "new/deleted migration file",
            "(migration file added or deleted)",
            "+",
        )

    # Confidence boost if touched files fall under high-confidence paths
    boost = 0.0
    for f in matched_files_set:
        for hp in HIGH_CONF_PATHS:
            if f.startswith(hp):
                boost = max(boost, 0.10)
    score = min(1.0, score + boost)

    confidence_hint = round(score if structural else 0.0, 2)
    reason_types = sorted(reason_types_set)
    matched_files = sorted(matched_files_set)
    primary = primary_reason or "other"
    if not structural:
        primary = "other"

    summary = "No structural invariant-affecting changes detected."
    if structural:
        types = ",".join(reason_types) if reason_types else "unknown"
        summary = f"Structural or privilege/security changes detected (types={types}, confidence_hint={confidence_hint})."

    return {
        "structural_change": bool(structural),
        "confidence_hint": confidence_hint,
        "matches": matches[:200],
        "reason_types": reason_types,
        "primary_reason": primary,
        "matched_files": matched_files,
        "match_counts": match_counts,
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

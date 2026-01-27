#!/usr/bin/env python3
"""
validate_invariants_manifest.py

Validates docs/invariants/INVARIANTS_MANIFEST.yml with no external deps.

Checks:
- Each entry has required keys
- id format INV-### and unique
- aliases is REQUIRED, non-empty, and globally unique across all entries
- status in {implemented, roadmap}
- severity in {P0, P1, P2}
- owners REQUIRED, non-empty
- verification REQUIRED, non-empty
- implemented entries must not have placeholder verification (TODO/TBD)

Exit 0 if OK; non-zero with clear messages otherwise.
"""

from __future__ import annotations
import argparse
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


INV_ID_RE = re.compile(r"^INV-\d{3}$")
ALLOWED_STATUS = {"implemented", "roadmap"}
ALLOWED_SEVERITY = {"P0", "P1", "P2"}


def _strip_quotes(v: str) -> str:
    return v.strip().strip('"').strip("'").strip()


def _parse_inline_list(v: str) -> Optional[List[str]]:
    v = v.strip()
    if not (v.startswith("[") and v.endswith("]")):
        return None
    inner = v[1:-1].strip()
    if not inner:
        return []
    parts: List[str] = []
    cur: List[str] = []
    in_squote = False
    in_dquote = False
    for ch in inner:
        if ch == "'" and not in_dquote:
            in_squote = not in_squote
            cur.append(ch)
            continue
        if ch == '"' and not in_squote:
            in_dquote = not in_dquote
            cur.append(ch)
            continue
        if ch == "," and not in_squote and not in_dquote:
            parts.append(_strip_quotes("".join(cur)))
            cur = []
            continue
        cur.append(ch)
    if cur:
        parts.append(_strip_quotes("".join(cur)))
    return [p for p in (p.strip() for p in parts) if p]


def parse_manifest(text: str) -> List[Dict[str, Any]]:
    """
    Constrained YAML-ish manifest parser.
    Supports:
      - list entries starting with: - id: INV-###
      - scalar: key: value
      - inline list: key: [a, b]
      - block list:
          key:
            - a
            - b
    """
    entries: List[Dict[str, Any]] = []
    cur: Optional[Dict[str, Any]] = None
    pending_list_key: Optional[str] = None
    pending_list_indent: Optional[int] = None

    for raw in text.splitlines():
        line = raw.rstrip("\n")
        if not line.strip() or line.strip().startswith("#"):
            continue

        if re.match(r"^\s*-\s+id:\s*", line):
            if cur:
                entries.append(cur)
            cur = {"id": _strip_quotes(line.split("id:", 1)[1])}
            pending_list_key = None
            pending_list_indent = None
            continue

        if cur is None:
            continue

        if pending_list_key is not None and pending_list_indent is not None:
            m_item = re.match(rf"^(\s{{{pending_list_indent},}})-\s+(.*)$", line)
            if m_item:
                cur.setdefault(pending_list_key, [])
                cur[pending_list_key].append(_strip_quotes(m_item.group(2)))
                continue
            pending_list_key = None
            pending_list_indent = None

        m = re.match(r"^\s+(\w+):\s*(.*)$", line)
        if not m:
            continue
        k = m.group(1)
        v = m.group(2).strip()

        if v == "":
            indent = len(line) - len(line.lstrip(" "))
            pending_list_key = k
            pending_list_indent = indent + 2
            cur[k] = []
            continue

        parsed_list = _parse_inline_list(v)
        if parsed_list is not None:
            cur[k] = parsed_list
        else:
            cur[k] = _strip_quotes(v)

    if cur:
        entries.append(cur)
    return entries


def norm(v: Any) -> str:
    if v is None:
        return ""
    if isinstance(v, list):
        return ", ".join(str(x) for x in v)
    return str(v).strip()


def is_placeholder_verification(v: str) -> bool:
    vv = (v or "").strip().lower()
    return (vv == "" or "todo" in vv or "tbd" in vv or vv == "?")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--manifest",
        default="docs/invariants/INVARIANTS_MANIFEST.yml",
        help="Path to manifest YAML",
    )
    args = ap.parse_args()

    manifest_path = Path(args.manifest)
    if not manifest_path.exists():
        print(f"ERROR: Manifest not found: {manifest_path}", file=sys.stderr)
        return 2

    entries = parse_manifest(manifest_path.read_text(encoding="utf-8", errors="ignore"))
    if not entries:
        print("ERROR: Manifest parsed zero entries.", file=sys.stderr)
        return 2

    errors: List[str] = []
    seen_ids: set[str] = set()
    seen_aliases: set[str] = set()

    required_keys = ["id", "aliases", "title", "status", "severity", "owners", "verification"]

    for idx, e in enumerate(entries, start=1):
        eid = norm(e.get("id"))
        where = f"entry#{idx}({eid or 'missing-id'})"

        # required keys
        for k in required_keys:
            if k not in e:
                errors.append(f"{where}: missing required key '{k}'")
        if not eid:
            continue

        if not INV_ID_RE.match(eid):
            errors.append(f"{where}: invalid id format '{eid}' (expected INV-###)")
        if eid in seen_ids:
            errors.append(f"{where}: duplicate id '{eid}'")
        seen_ids.add(eid)

        status = norm(e.get("status")).lower()
        if status not in ALLOWED_STATUS:
            errors.append(f"{where}: invalid status '{status}' (allowed: {sorted(ALLOWED_STATUS)})")

        sev = norm(e.get("severity")).upper()
        if sev not in ALLOWED_SEVERITY:
            errors.append(f"{where}: invalid severity '{sev}' (allowed: {sorted(ALLOWED_SEVERITY)})")

        aliases = e.get("aliases")
        if not isinstance(aliases, list) or len(aliases) == 0:
            errors.append(f"{where}: aliases must be a non-empty list")
        else:
            for a in aliases:
                aa = norm(a)
                if not aa:
                    errors.append(f"{where}: aliases contains empty value")
                    continue
                if aa in seen_aliases:
                    errors.append(f"{where}: alias '{aa}' duplicates another invariant alias")
                seen_aliases.add(aa)

        owners = e.get("owners")
        if not isinstance(owners, list) or len(owners) == 0:
            errors.append(f"{where}: owners must be a non-empty list")

        ver = norm(e.get("verification"))
        if not ver:
            errors.append(f"{where}: verification must be non-empty")
        if status == "implemented" and is_placeholder_verification(ver):
            errors.append(f"{where}: implemented invariant has placeholder/empty verification '{ver}'")

    if errors:
        print("Manifest validation FAILED:", file=sys.stderr)
        for msg in errors:
            print(f" - {msg}", file=sys.stderr)
        return 1

    print(f"OK: Manifest valid ({len(entries)} entries).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

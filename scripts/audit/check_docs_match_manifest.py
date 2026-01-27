#!/usr/bin/env python3
"""
check_docs_match_manifest.py

Validates that Implemented/Roadmap docs stay consistent with the manifest,
WITHOUT generating/overwriting them.

Rules:
- Any INV-### referenced in Implemented doc must be status: implemented in manifest
- Any INV-### referenced in Roadmap doc must be status: roadmap in manifest
- Any alias referenced in docs must exist under some manifest entry aliases
- Optional coverage check (default ON):
    - every implemented manifest entry must appear in Implemented doc (by INV id or any alias)
    - every roadmap manifest entry must appear in Roadmap doc

Disable coverage via env:
  CHECK_DOC_COVERAGE=0
"""

from __future__ import annotations
import argparse
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set


INV_ID_RE = re.compile(r"\bINV-\d{3}\b")


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


def build_alias_index(entries: List[Dict[str, Any]]) -> Dict[str, str]:
    """alias -> inv_id"""
    idx: Dict[str, str] = {}
    for e in entries:
        inv_id = norm(e.get("id"))
        aliases = e.get("aliases")
        if not inv_id or not isinstance(aliases, list):
            continue
        for a in aliases:
            aa = norm(a)
            if aa:
                idx[aa] = inv_id
    return idx


def referenced_invs_and_aliases(doc_text: str, alias_set: Set[str]) -> tuple[Set[str], Set[str]]:
    invs = set(INV_ID_RE.findall(doc_text))

    # Find aliases by searching for exact alias tokens.
    # Build one regex union for performance and correctness (escape special chars).
    aliases_found: Set[str] = set()
    if alias_set:
        # sort longest-first to reduce partial overlaps (rare but safe)
        parts = sorted(alias_set, key=len, reverse=True)
        union = r"|".join(re.escape(a) for a in parts)
        # word-ish boundaries: allow aliases like I-SEC-02; we ensure they match as tokens
        rx = re.compile(rf"(?<![\w-])({union})(?![\w-])")
        for m in rx.finditer(doc_text):
            aliases_found.add(m.group(1))

    return invs, aliases_found


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="docs/invariants/INVARIANTS_MANIFEST.yml")
    ap.add_argument("--implemented", default="docs/invariants/INVARIANTS_IMPLEMENTED.md")
    ap.add_argument("--roadmap", default="docs/invariants/INVARIANTS_ROADMAP.md")
    args = ap.parse_args()

    coverage_on = os.getenv("CHECK_DOC_COVERAGE", "1").strip() not in ("0", "false", "False")

    mp = Path(args.manifest)
    ip = Path(args.implemented)
    rp = Path(args.roadmap)

    if not mp.exists():
        print(f"ERROR: manifest not found: {mp}", file=sys.stderr)
        return 2
    if not ip.exists():
        print(f"ERROR: implemented doc not found: {ip}", file=sys.stderr)
        return 2
    if not rp.exists():
        print(f"ERROR: roadmap doc not found: {rp}", file=sys.stderr)
        return 2

    entries = parse_manifest(mp.read_text(encoding="utf-8", errors="ignore"))
    by_id: Dict[str, Dict[str, Any]] = {norm(e.get("id")): e for e in entries if norm(e.get("id"))}
    alias_to_id = build_alias_index(entries)
    alias_set = set(alias_to_id.keys())

    impl_txt = ip.read_text(encoding="utf-8", errors="ignore")
    road_txt = rp.read_text(encoding="utf-8", errors="ignore")

    impl_invs, impl_aliases = referenced_invs_and_aliases(impl_txt, alias_set)
    road_invs, road_aliases = referenced_invs_and_aliases(road_txt, alias_set)

    errors: List[str] = []

    def resolve_ids(invs: Set[str], aliases: Set[str]) -> Set[str]:
        out = set(invs)
        for a in aliases:
            inv_id = alias_to_id.get(a)
            if not inv_id:
                errors.append(f"Docs reference alias '{a}' but it is not present in manifest aliases.")
            else:
                out.add(inv_id)
        return out

    impl_ids = resolve_ids(impl_invs, impl_aliases)
    road_ids = resolve_ids(road_invs, road_aliases)

    # Validate referenced IDs exist and match expected status
    for inv_id in sorted(impl_ids):
        e = by_id.get(inv_id)
        if not e:
            errors.append(f"Implemented doc references {inv_id} but it is missing from manifest.")
            continue
        status = norm(e.get("status")).lower()
        if status != "implemented":
            errors.append(f"Implemented doc references {inv_id} but manifest status is '{status}' (expected implemented).")

    for inv_id in sorted(road_ids):
        e = by_id.get(inv_id)
        if not e:
            errors.append(f"Roadmap doc references {inv_id} but it is missing from manifest.")
            continue
        status = norm(e.get("status")).lower()
        if status != "roadmap":
            errors.append(f"Roadmap doc references {inv_id} but manifest status is '{status}' (expected roadmap).")

    if coverage_on:
        # Coverage: all manifest implemented entries must appear in implemented doc
        implemented_manifest = {inv_id for inv_id, e in by_id.items() if norm(e.get("status")).lower() == "implemented"}
        roadmap_manifest = {inv_id for inv_id, e in by_id.items() if norm(e.get("status")).lower() == "roadmap"}

        missing_impl = sorted(implemented_manifest - impl_ids)
        missing_road = sorted(roadmap_manifest - road_ids)

        if missing_impl:
            errors.append(
                "Implemented doc is missing these implemented invariants from manifest: "
                + ", ".join(missing_impl)
            )
        if missing_road:
            errors.append(
                "Roadmap doc is missing these roadmap invariants from manifest: "
                + ", ".join(missing_road)
            )

    if errors:
        print("Docs ↔ Manifest consistency FAILED:", file=sys.stderr)
        for msg in errors:
            print(f" - {msg}", file=sys.stderr)
        return 1

    cov_msg = "ON" if coverage_on else "OFF"
    print(f"OK: Docs match manifest (coverage {cov_msg}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

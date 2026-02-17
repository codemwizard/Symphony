from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Any

import yaml  # type: ignore


def _run(root: Path, cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=root, text=True).strip()


def _try_run(root: Path, cmd: list[str]) -> str:
    try:
        return _run(root, cmd)
    except Exception:
        return ""


def _resolve_base_ref(root: Path) -> str:
    import os

    base_ref = os.environ.get("BASE_REF", "").strip()
    if base_ref:
        return base_ref
    gh_base = os.environ.get("GITHUB_BASE_REF", "").strip()
    if gh_base:
        if gh_base.startswith("refs/"):
            return gh_base
        return f"refs/remotes/origin/{gh_base}"
    return "refs/remotes/origin/main"


def _changed_files_from_status(root: Path) -> list[str]:
    out = _try_run(root, ["git", "status", "--porcelain", "--untracked-files=no"])
    files = []
    for line in out.splitlines():
        if not line:
            continue
        path = line[3:].strip()
        if path:
            files.append(path)
    return sorted(set(files))


def _path_matches(path: str, pattern: str) -> bool:
    p = Path(path)
    # Path.match supports ** glob matching in repo-relative paths.
    return p.match(pattern)


def load_regulated_patterns(root: Path) -> list[str]:
    rules_file = root / "docs/operations/REGULATED_SURFACE_PATHS.yml"
    if not rules_file.exists():
        return []
    data = yaml.safe_load(rules_file.read_text(encoding="utf-8")) or {}
    return [str(p) for p in ((data.get("rules") or {}).get("patterns") or [])]


def approval_requirement_context(root: Path) -> dict[str, Any]:
    base_ref = _resolve_base_ref(root)
    head_ref = "HEAD"
    diff_mode = "range"
    merge_base = ""
    changed_files: list[str] = []

    base_ok = _try_run(root, ["git", "rev-parse", "--verify", base_ref]) != ""
    if base_ok:
        merge_base = _try_run(root, ["git", "merge-base", base_ref, head_ref])
        if merge_base:
            out = _try_run(root, ["git", "diff", "--name-only", f"{merge_base}...{head_ref}"])
            changed_files = sorted(set([ln.strip() for ln in out.splitlines() if ln.strip()]))
        else:
            diff_mode = "status_fallback"
            changed_files = _changed_files_from_status(root)
    else:
        diff_mode = "status_fallback"
        changed_files = _changed_files_from_status(root)

    patterns = load_regulated_patterns(root)
    regulated_hits = []
    for path in changed_files:
        if any(_path_matches(path, pat) for pat in patterns):
            regulated_hits.append(path)

    return {
        "base_ref": base_ref,
        "head_ref": head_ref,
        "merge_base": merge_base,
        "diff_mode": diff_mode,
        "changed_files": changed_files,
        "regulated_patterns": patterns,
        "regulated_changed_paths": sorted(set(regulated_hits)),
        "approval_required": bool(regulated_hits),
        "rules_file": "docs/operations/REGULATED_SURFACE_PATHS.yml",
    }

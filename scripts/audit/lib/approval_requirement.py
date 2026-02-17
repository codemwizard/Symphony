from __future__ import annotations

import os
import subprocess
from pathlib import Path
from typing import Any

import yaml  # type: ignore


def _run(root: Path, cmd: list[str]) -> str:
    return subprocess.check_output(cmd, cwd=root, text=True).strip()


def _run_diff_helper(root: Path) -> tuple[str, str, list[str]]:
    helper = root / "scripts/lib/git_diff_range_only.sh"
    if not helper.exists():
        raise RuntimeError(f"diff_helper_missing:{helper}")
    env = os.environ.copy()
    env.setdefault("HEAD_REF", "HEAD")
    script = (
        'source "scripts/lib/git_diff_range_only.sh"\n'
        'base_ref="$(git_resolve_base_ref)"\n'
        'if ! git_ensure_ref "$base_ref"; then\n'
        '  if [[ "$base_ref" == "refs/remotes/origin/main" ]] && git rev-parse --verify refs/heads/origin/main >/dev/null 2>&1; then\n'
        '    base_ref="refs/heads/origin/main"\n'
        "  else\n"
        '  echo "ERROR: base_ref_not_found:$base_ref" >&2\n'
        "  exit 22\n"
        "  fi\n"
        "fi\n"
        'merge_base="$(git_merge_base "$base_ref" "${HEAD_REF:-HEAD}")"\n'
        'printf "__BASE_REF__:%s\\n" "$base_ref"\n'
        'printf "__MERGE_BASE__:%s\\n" "$merge_base"\n'
        'git_changed_files_range "$base_ref" "${HEAD_REF:-HEAD}"\n'
    )
    proc = subprocess.run(
        ["bash", "-lc", script],
        cwd=root,
        env=env,
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        err = (proc.stderr or proc.stdout or "").strip()
        raise RuntimeError(f"diff_helper_failed:rc={proc.returncode}:{err}")
    changed_files: list[str] = []
    base_ref = ""
    merge_base = ""
    for line in (proc.stdout or "").splitlines():
        item = line.strip()
        if not item:
            continue
        if item.startswith("__BASE_REF__:"):
            base_ref = item.split(":", 1)[1]
            continue
        if item.startswith("__MERGE_BASE__:"):
            merge_base = item.split(":", 1)[1]
            continue
        changed_files.append(item)
    changed_files = sorted(set(changed_files))
    if not base_ref or not merge_base:
        raise RuntimeError("diff_helper_failed:missing_base_or_merge_base")
    return base_ref, merge_base, changed_files


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
    base_ref = ""
    head_ref = "HEAD"
    diff_mode = "range"
    merge_base = ""
    changed_files: list[str] = []
    error = ""
    try:
        base_ref, merge_base, changed_files = _run_diff_helper(root)
    except Exception as exc:
        error = str(exc)

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
        "approval_required": bool(regulated_hits) if not error else True,
        "rules_file": "docs/operations/REGULATED_SURFACE_PATHS.yml",
        "error": error,
    }

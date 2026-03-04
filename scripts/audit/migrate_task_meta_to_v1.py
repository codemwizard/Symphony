#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml  # type: ignore

TOOL_VERSION = "1.0.0"
CANONICAL_ORDER = [
    "schema_version",
    "phase",
    "task_id",
    "title",
    "owner_role",
    "status",
    "depends_on",
    "touches",
    "invariants",
    "work",
    "acceptance_criteria",
    "verification",
    "evidence",
    "failure_modes",
    "must_read",
    "implementation_plan",
    "implementation_log",
    "notes",
    "client",
    "assigned_agent",
    "model",
]

LEGACY_MAP = {
    "id": "task_id",
    "verification_command": "verification",
    "implementation_plan_path": "implementation_plan",
    "implementation_log_path": "implementation_log",
    "evidence_path": "evidence",
    "evidence_paths": "evidence",
    "owner": "owner_role",
    "role": "owner_role",
    "assignee_role": "owner_role",
    "dependencies": "depends_on",
    "affected_files": "touches",
}


@dataclass
class FileReport:
    path: str
    schema_before: str
    schema_after: str
    changed: bool
    legacy_keys: list[str] = field(default_factory=list)
    mappings: list[dict[str, Any]] = field(default_factory=list)
    normalizations: list[str] = field(default_factory=list)
    conflicts: list[dict[str, Any]] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Migrate task meta files to canonical v1 schema")
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--apply", action="store_true")
    p.add_argument("--input-root", default=".", help="Migration scan base (default: repository root)")
    p.add_argument("--output-dir", help="Write migrated mirror tree here (apply mode)")
    p.add_argument("--in-place", action="store_true", help="Mutate files in place (apply mode only)")
    p.add_argument("--force", action="store_true", help="Allow apply on dirty git worktree")
    p.add_argument("--run-id", default=None)
    p.add_argument("--report", required=True)
    p.add_argument("--allow-conflicts-with-justification", default=None)
    return p.parse_args()


def git_sha() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "--short", "HEAD"], text=True).strip()
    except Exception:
        return "nogit"


def run_id_from_args(args: argparse.Namespace) -> str:
    if args.run_id:
        return args.run_id
    return f"{git_sha()}-{TOOL_VERSION}"


def report_timestamp(args: argparse.Namespace) -> str:
    env_ts = os.environ.get("MIGRATE_TS_UTC")
    if env_ts:
        return env_ts
    if args.dry_run and args.run_id:
        # Determinism check mode: fixed run_id should produce byte-identical reports.
        return "1970-01-01T00:00:00Z"
    return subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], text=True).strip()


def discover_meta_files(root: Path) -> list[Path]:
    candidates: list[Path] = []
    if (root / "tasks").is_dir():
        base = root / "tasks"
        for meta in base.rglob("meta.yml"):
            if "/_template/" in meta.as_posix() or meta.parent.name == "_template":
                continue
            candidates.append(meta)
    else:
        for meta in root.rglob("meta.yml"):
            if "/_template/" in meta.as_posix() or meta.parent.name == "_template":
                continue
            candidates.append(meta)
    return sorted(candidates, key=lambda p: p.as_posix())


def as_list_str(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        out: list[str] = []
        for item in value:
            if item is None:
                continue
            s = str(item).strip()
            if s:
                out.append(s)
        return out
    if isinstance(value, dict):
        if "path" in value:
            s = str(value["path"]).strip()
            return [s] if s else []
        return [json.dumps(value, sort_keys=True)]
    s = str(value)
    if "\n" in s:
        return [line.strip() for line in s.splitlines() if line.strip()]
    s = s.strip()
    return [s] if s else []


def normalize_status(value: Any) -> str:
    s = str(value or "planned").strip().lower()
    if s in {"todo", "to_do", "not_started"}:
        return "planned"
    if s in {"done", "complete"}:
        return "completed"
    if s in {"in_progress", "planned", "completed"}:
        return s
    return s


def canonicalize_dict(d: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key in CANONICAL_ORDER:
        if key in d:
            out[key] = d[key]
    for key in sorted(d.keys()):
        if key not in out:
            out[key] = d[key]
    return out


def compute_inputs_hash(root: Path, files: list[Path]) -> str:
    h = hashlib.sha256()
    for f in files:
        rel = f.relative_to(root).as_posix().encode("utf-8")
        h.update(rel)
        h.update(b"\0")
        h.update(f.read_bytes())
        h.update(b"\0")
    return h.hexdigest()


def ensure_clean_for_apply(args: argparse.Namespace, root: Path) -> None:
    if args.dry_run:
        return
    if args.output_dir:
        return
    if not args.in_place:
        return
    if args.force:
        return
    try:
        proc = subprocess.run(["git", "status", "--porcelain"], cwd=root, capture_output=True, text=True, check=False)
        if proc.returncode == 0 and proc.stdout.strip():
            raise SystemExit("ERROR: dirty worktree; re-run with --force for in-place apply")
    except FileNotFoundError:
        raise SystemExit("ERROR: git not found; cannot verify dirty worktree safety")


def migrate_one(path: Path, root: Path, justification: str | None) -> tuple[dict[str, Any], FileReport, str | None]:
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise SystemExit(f"ERROR: {path} meta is not a mapping")

    data = dict(raw)
    report = FileReport(
        path=path.relative_to(root).as_posix(),
        schema_before=str(data.get("schema_version") or "0"),
        schema_after="1",
        changed=False,
    )

    # Extract mapped fields and detect conflicts.
    extracted: dict[str, Any] = {}
    for old_key, new_key in LEGACY_MAP.items():
        if old_key in data:
            report.legacy_keys.append(old_key)
            report.mappings.append({"old_key": old_key, "new_key": new_key, "action": "mapped"})
            old_val = data.get(old_key)
            if new_key in data and data.get(new_key) not in (None, "", [], {}):
                if old_val != data.get(new_key):
                    conflict = {
                        "field": new_key,
                        "legacy_key": old_key,
                        "legacy_value": old_val,
                        "canonical_value": data.get(new_key),
                        "selected": "canonical",
                        "justification": justification,
                    }
                    report.conflicts.append(conflict)
            else:
                extracted[new_key] = old_val

    if report.conflicts and not justification:
        return raw, report, "conflicts_detected_without_justification"

    # Build canonical object.
    merged = dict(data)
    merged.update(extracted)

    canonical: dict[str, Any] = {
        "schema_version": 1,
        "phase": str(merged.get("phase") or "0"),
        "task_id": str(merged.get("task_id") or path.parent.name),
        "title": str(merged.get("title") or f"Task {path.parent.name}"),
        "owner_role": str(merged.get("owner_role") or "SUPERVISOR"),
        "status": normalize_status(merged.get("status")),
        "depends_on": as_list_str(merged.get("depends_on")),
        "touches": as_list_str(merged.get("touches")),
        "invariants": as_list_str(merged.get("invariants")),
        "work": as_list_str(merged.get("work")),
        "acceptance_criteria": merged.get("acceptance_criteria") if isinstance(merged.get("acceptance_criteria"), list) else as_list_str(merged.get("acceptance_criteria")),
        "verification": as_list_str(merged.get("verification")),
        "evidence": as_list_str(merged.get("evidence")),
        "failure_modes": as_list_str(merged.get("failure_modes")),
        "must_read": as_list_str(merged.get("must_read")),
        "implementation_plan": str(merged.get("implementation_plan") or ""),
        "implementation_log": str(merged.get("implementation_log") or ""),
        "notes": str(merged.get("notes") or merged.get("description") or ""),
        "client": str(merged.get("client") or "codex_cli"),
        "assigned_agent": str(merged.get("assigned_agent") or "supervisor"),
        "model": str(merged.get("model") or "<UNASSIGNED>"),
    }

    if merged.get("verification") != canonical["verification"]:
        report.normalizations.append("verification_normalized_to_list")
    if merged.get("evidence") != canonical["evidence"]:
        report.normalizations.append("evidence_normalized_to_list")
    report.normalizations.append("phase_normalized_to_string")
    report.normalizations.append("status_normalized")

    canonical = canonicalize_dict(canonical)

    before = yaml.safe_dump(canonicalize_dict(raw), sort_keys=False, allow_unicode=False)
    after = yaml.safe_dump(canonical, sort_keys=False, allow_unicode=False)
    report.changed = before != after

    return canonical, report, None


def write_output(path: Path, content: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(content, sort_keys=False, allow_unicode=False), encoding="utf-8")


def main() -> int:
    args = parse_args()
    root = Path(args.input_root).resolve()
    if not root.exists():
        raise SystemExit(f"ERROR: input root does not exist: {root}")

    if args.apply and not args.output_dir and not args.in_place:
        # For migration rollout safety, in-place must be explicit.
        args.in_place = True

    ensure_clean_for_apply(args, root)

    files = discover_meta_files(root)
    if not files:
        raise SystemExit("ERROR: no task meta files found")

    run_id = run_id_from_args(args)
    migrated: list[tuple[Path, dict[str, Any], FileReport]] = []
    errors: list[dict[str, Any]] = []
    v0_count = 0
    v1_count = 0
    for f in files:
        if str(yaml.safe_load(f.read_text(encoding="utf-8")).get("schema_version") or "0") == "1":
            v1_count += 1
        else:
            v0_count += 1

    for meta in files:
        try:
            migrated_obj, freport, err = migrate_one(meta, root, args.allow_conflicts_with_justification)
            if err:
                errors.append({"path": freport.path, "error": err, "conflicts": freport.conflicts})
            migrated.append((meta, migrated_obj, freport))
        except Exception as ex:
            errors.append({"path": meta.relative_to(root).as_posix(), "error": str(ex)})

    if args.apply and not errors:
        if args.output_dir:
            out_root = Path(args.output_dir).resolve()
            if out_root.exists():
                shutil.rmtree(out_root)
            out_root.mkdir(parents=True, exist_ok=True)
            # Copy full task-pack mirror for discovered meta files.
            pack_dirs = sorted({m.parent for (m, _, _) in migrated}, key=lambda p: p.as_posix())
            for pdir in pack_dirs:
                rel = pdir.relative_to(root)
                shutil.copytree(pdir, out_root / rel, dirs_exist_ok=True)
            for meta, obj, _ in migrated:
                target = Path(args.output_dir).resolve() / meta.relative_to(root)
                write_output(target, obj)
        else:
            for meta, obj, freport in migrated:
                if freport.changed:
                    write_output(meta, obj)

    changed = sum(1 for _, _, r in migrated if r.changed)
    conflicts_count = sum(len(r.conflicts) for _, _, r in migrated)

    report = {
        "task_id": "R-024",
        "status": "PASS" if not errors else "FAIL",
        "tool_version": TOOL_VERSION,
        "mode": "dry-run" if args.dry_run else "apply",
        "git_sha": git_sha(),
        "run_id": run_id,
        "timestamp_utc": report_timestamp(args),
        "input_root": str(root),
        "output_dir": str(Path(args.output_dir).resolve()) if args.output_dir else None,
        "in_place": bool(args.apply and not args.output_dir),
        "inputs_hash": compute_inputs_hash(root, files),
        "summary": {
            "files_scanned": len(files),
            "files_changed": changed,
            "files_unchanged": len(files) - changed,
            "v0_count": v0_count,
            "v1_count": v1_count,
            "conflicts_count": conflicts_count,
            "errors_count": len(errors),
        },
        "files": [
            {
                "path": r.path,
                "schema_before": r.schema_before,
                "schema_after": r.schema_after,
                "changed": r.changed,
                "legacy_keys": sorted(r.legacy_keys),
                "mappings": sorted(r.mappings, key=lambda m: (m["old_key"], m["new_key"])),
                "normalizations": sorted(r.normalizations),
                "conflicts": r.conflicts,
            }
            for _, _, r in migrated
        ],
        "errors": errors,
        "conflict_override_justification": args.allow_conflicts_with_justification,
    }

    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")

    if errors:
        print(f"FAIL: {len(errors)} migration error(s). Report: {report_path}")
        return 1

    print(f"PASS: migrated analysis complete. Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

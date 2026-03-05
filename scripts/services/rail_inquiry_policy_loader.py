#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any

import jsonschema


class PolicyError(RuntimeError):
    pass


def _load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise PolicyError(f"invalid_json:{path}:{exc}") from exc


def _validate_store(store: dict[str, Any], schema: dict[str, Any]) -> None:
    jsonschema.validate(instance=store, schema=schema)
    versions = store.get("versions") or []
    version_ids = [v.get("version_id") for v in versions]
    if len(set(version_ids)) != len(version_ids):
        raise PolicyError("duplicate_version_id")
    active = store.get("active_version_id")
    if active not in set(version_ids):
        raise PolicyError("active_version_not_found")


def _active_version(store: dict[str, Any]) -> dict[str, Any]:
    active = store["active_version_id"]
    for ver in store["versions"]:
        if ver["version_id"] == active:
            return ver
    raise PolicyError("active_version_not_found")


def resolve_policy(store: dict[str, Any], rail_id: str) -> dict[str, Any]:
    version = _active_version(store)
    policies = version.get("policies") or []
    exact = next((p for p in policies if p.get("rail_id") == rail_id), None)
    if exact:
        return {"policy_version_id": version["version_id"], **exact}

    # wildcard fallback: prefix-* style only
    for p in policies:
        rid = str(p.get("rail_id", ""))
        if rid.endswith("*") and rail_id.startswith(rid[:-1]):
            return {"policy_version_id": version["version_id"], **p}

    raise PolicyError(f"unknown_rail_policy:{rail_id}")


def emit_inquiry_event(resolved: dict[str, Any], rail_id: str, output: Path) -> None:
    payload = {
        "event_class": "inquiry_event",
        "inquiry_id": "inq-policy-loader-smoke",
        "instruction_id": "inst-policy-loader-smoke",
        "rail": rail_id,
        "poll_count": 0,
        "status": "INQUIRY_SENT",
        "policy_version_id": resolved["policy_version_id"],
        "timestamp_utc": "2026-03-05T00:00:00Z",
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def emit_activation_event(version_id: str, actor: str, output: Path) -> None:
    signing_key = (os.environ.get("EVIDENCE_SIGNING_KEY") or "").strip()
    payload = {
        "event_class": "policy_activation_event",
        "policy_id": "rail_inquiry_policy",
        "policy_version": version_id,
        "activated_by": actor,
        "timestamp_utc": "2026-03-05T00:00:00Z",
    }
    if not signing_key:
        payload["unsigned_reason"] = "DEPENDENCY_NOT_READY"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def reject_missing_version_id(candidate_path: Path) -> None:
    candidate = _load_json(candidate_path)
    versions = candidate.get("versions") or []
    for idx, version in enumerate(versions):
        if not str(version.get("version_id", "")).strip():
            raise PolicyError(f"missing_version_id_at_index:{idx}")


def reject_in_place_edit_active(store_path: Path, version_id: str) -> None:
    store = _load_json(store_path)
    if store.get("active_version_id") == version_id:
        raise PolicyError("active_version_in_place_edit_blocked")


def main() -> int:
    parser = argparse.ArgumentParser(description="Rail inquiry policy runtime loader")
    parser.add_argument("--store", default="config/hardening/rail_inquiry_policies.json")
    parser.add_argument("--schema", default="evidence/schemas/hardening/rail_inquiry_policy.schema.json")
    parser.add_argument("--rail-id")
    parser.add_argument("--emit-inquiry-evidence")
    parser.add_argument("--activate-version-id")
    parser.add_argument("--activated-by", default="system")
    parser.add_argument("--activation-evidence")
    parser.add_argument("--candidate-store")
    parser.add_argument("--reject-in-place-edit-version-id")
    parser.add_argument("--print-json", action="store_true")
    args = parser.parse_args()

    try:
        store_path = Path(args.store)
        schema_path = Path(args.schema)
        store = _load_json(store_path)
        schema = _load_json(schema_path)
        _validate_store(store, schema)

        if args.candidate_store:
            reject_missing_version_id(Path(args.candidate_store))

        if args.reject_in_place_edit_version_id:
            reject_in_place_edit_active(store_path, args.reject_in_place_edit_version_id)

        resolved = None
        if args.rail_id:
            resolved = resolve_policy(store, args.rail_id)
            if args.emit_inquiry_evidence:
                emit_inquiry_event(resolved, args.rail_id, Path(args.emit_inquiry_evidence))

        if args.activate_version_id:
            if args.activation_evidence is None:
                raise PolicyError("activation_evidence_path_required")
            emit_activation_event(args.activate_version_id, args.activated_by, Path(args.activation_evidence))

        if args.print_json:
            print(json.dumps({
                "status": "PASS",
                "active_version_id": store["active_version_id"],
                "resolved_policy": resolved,
            }, indent=2))
        return 0
    except Exception as exc:
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

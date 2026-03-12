#!/usr/bin/env python3
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path


def git_sha() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def locate_age(root: Path) -> Path:
    for candidate in (
        shutil.which("age"),
        root / ".toolchain/age/usr/bin/age",
    ):
        if not candidate:
            continue
        path = Path(candidate)
        if path.exists():
            return path
    raise SystemExit("missing_age_binary")


def validate_manifest_entries(manifest_payload: dict, extracted_root: Path) -> bool:
    for entry in manifest_payload.get("entries", []):
        target = extracted_root / entry["path"]
        if not target.is_file():
            return False
        if sha256(target) != entry["sha256"]:
            return False
    return True


def validate_bundle_members(tf: tarfile.TarFile, expected_files: set[str]) -> list[tarfile.TarInfo]:
    allowed_dirs = {""}
    for rel_path in expected_files:
        parent = Path(rel_path).parent
        while str(parent) not in {"", "."}:
            allowed_dirs.add(parent.as_posix())
            parent = parent.parent

    safe_members: list[tarfile.TarInfo] = []
    for member in tf.getmembers():
        normalized = Path(member.name).as_posix().lstrip("./")
        if not normalized:
            safe_members.append(member)
            continue

        member_path = Path(normalized)
        if member_path.is_absolute() or ".." in member_path.parts:
            raise SystemExit(f"unsafe_tar_member:{member.name}")

        if member.issym() or member.islnk():
            raise SystemExit(f"unsupported_tar_member:{member.name}")

        if member.isdir():
            if normalized not in allowed_dirs:
                raise SystemExit(f"unexpected_tar_directory:{member.name}")
            safe_members.append(member)
            continue

        if not member.isfile():
            raise SystemExit(f"unsupported_tar_member:{member.name}")

        if normalized not in expected_files:
            raise SystemExit(f"unexpected_tar_member:{member.name}")

        safe_members.append(member)

    return safe_members


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    out_dir = root / "scripts/dr/output/tsk_p1_int_007"
    manifest = out_dir / "manifest.json"
    signature = out_dir / "manifest.json.sig"
    signing_pub = out_dir / "manifest_signing_public.pem"
    encrypted_bundle = out_dir / "bundle.tar.age"
    recovery_key = out_dir / "recovery/primary_recovery.agekey"
    evidence_path = root / "evidence/phase1/tsk_p1_int_008_offline_verification.json"
    threshold_ms = 300000
    age_bin = locate_age(root)

    for path in (manifest, signature, signing_pub, encrypted_bundle, recovery_key):
        if not path.exists():
            raise SystemExit(f"missing_required_input:{path}")

    start = time.time()
    with tempfile.TemporaryDirectory(prefix="tsk_p1_int_008_") as tmp:
        tmpdir = Path(tmp)
        bundle_root = tmpdir / "bundle_root"
        extracted = tmpdir / "extracted"
        bundle_root.mkdir()
        extracted.mkdir()

        # Copy only the bundle-root artifacts into a clean directory to show
        # verification uses the exported bundle materials, not the repo tree.
        for src in (manifest, signature, signing_pub, encrypted_bundle, recovery_key):
            rel = src.relative_to(out_dir)
            dest = bundle_root / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)

        subprocess.run(
            ["openssl", "dgst", "-sha256", "-verify", str(bundle_root / "manifest_signing_public.pem"),
             "-signature", str(bundle_root / "manifest.json.sig"), str(bundle_root / "manifest.json")],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        tar_path = tmpdir / "bundle.tar"
        subprocess.run(
            [str(age_bin), "-d", "-i", str(bundle_root / "recovery/primary_recovery.agekey"),
             "-o", str(tar_path), str(bundle_root / "bundle.tar.age")],
            check=True,
        )

        manifest_payload = json.loads((bundle_root / "manifest.json").read_text(encoding="utf-8"))
        with tarfile.open(tar_path) as tf:
            safe_members = validate_bundle_members(tf, {entry["path"] for entry in manifest_payload.get("entries", [])})
            for member in safe_members:
                tf.extract(member, extracted)

        manifest_pass = validate_manifest_entries(manifest_payload, extracted)
        if not manifest_pass:
            raise SystemExit("manifest_validation_failed")

        tamper_target = extracted / "canonical/evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json"
        original = tamper_target.read_text(encoding="utf-8")
        tampered = original.replace('"status": "PASS"', '"status": "FAIL"', 1)
        if tampered == original:
            tampered = original + "\n#tampered\n"
        tamper_target.write_text(tampered, encoding="utf-8")
        tamper_rejected = not validate_manifest_entries(manifest_payload, extracted)

    elapsed_ms = int((time.time() - start) * 1000)
    payload = {
        "check_id": "TSK-P1-INT-008-OFFLINE-VERIFY",
        "task_id": "TSK-P1-INT-008",
        "run_id": os.environ.get("SYMPHONY_RUN_ID", f"int008-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
        "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "git_sha": git_sha(),
        "status": "PASS" if manifest_pass and tamper_rejected and elapsed_ms <= threshold_ms else "FAIL",
        "pass": manifest_pass and tamper_rejected and elapsed_ms <= threshold_ms,
        "bundle_root": str(out_dir),
        "offline_only": True,
        "network_required": False,
        "live_runtime_required": False,
        "signature_verification_pass": True,
        "manifest_hash_validation_pass": manifest_pass,
        "tamper_rejection_pass": tamper_rejected,
        "environment_proof": "tempdir_shared_nothing_bundle_root_only",
        "elapsed_ms": elapsed_ms,
        "threshold_ms": threshold_ms,
    }
    evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    if not payload["pass"]:
        raise SystemExit("offline_verification_failed")
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())

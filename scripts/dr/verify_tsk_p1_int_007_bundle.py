#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
from pathlib import Path


def run(*args: str) -> None:
    subprocess.run(args, check=True)


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


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    out_dir = root / "scripts/dr/output/tsk_p1_int_007"
    manifest = out_dir / "manifest.json"
    signature = out_dir / "manifest.json.sig"
    signing_pub = out_dir / "manifest_signing_public.pem"
    encrypted = out_dir / "bundle.tar.age"
    recovery_key = out_dir / "recovery/primary_recovery.agekey"
    recipient_file = out_dir / "bundle.age.recipient.txt"
    custody_doc = out_dir / "custody_handoff.md"
    evidence = root / "evidence/phase1/tsk_p1_int_007_dr_bundle_generator.json"
    age_bin = locate_age(root)

    for path in (manifest, signature, signing_pub, encrypted, recovery_key, recipient_file, custody_doc, evidence):
        if not path.exists():
            raise SystemExit(f"missing_required_output:{path}")

    payload = json.loads(manifest.read_text(encoding="utf-8"))
    if payload.get("task_id") != "TSK-P1-INT-007":
        raise SystemExit("unexpected_task_id")
    if payload.get("protection_method") != "age":
        raise SystemExit("unexpected_protection_method")
    if not payload.get("entries"):
        raise SystemExit("empty_manifest_entries")

    run("openssl", "dgst", "-sha256", "-verify", str(signing_pub), "-signature", str(signature), str(manifest))

    decrypt_target = out_dir / "verify_roundtrip.tar"
    try:
        run(str(age_bin), "-d", "-i", str(recovery_key), "-o", str(decrypt_target), str(encrypted))
        if decrypt_target.stat().st_size == 0:
            raise SystemExit("empty_decrypted_bundle")
    finally:
        decrypt_target.unlink(missing_ok=True)

    evidence_payload = json.loads(evidence.read_text(encoding="utf-8"))
    if not evidence_payload.get("threshold_pass"):
        raise SystemExit("threshold_not_met")
    if not evidence_payload.get("decrypt_roundtrip_pass"):
        raise SystemExit("decrypt_roundtrip_not_recorded")
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())

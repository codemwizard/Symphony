#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TASK_ID="TSK-P1-INT-007"
OUT_DIR="$ROOT_DIR/scripts/dr/output/tsk_p1_int_007"
STAGING_DIR="$OUT_DIR/staging"
CANON_DIR="$STAGING_DIR/canonical"
ARTIFACT_DIR="$STAGING_DIR/artifacts"
TOOLS_DIR="$STAGING_DIR/verifier_tooling"
POLICY_DIR="$STAGING_DIR/policy_archive"
KEYS_DIR="$OUT_DIR/recovery"
CUSTODY_DOC="$OUT_DIR/custody_handoff.md"
MANIFEST="$OUT_DIR/manifest.json"
SIGNATURE="$OUT_DIR/manifest.json.sig"
SIGNING_PUB="$OUT_DIR/manifest_signing_public.pem"
ENCRYPTED_BUNDLE="$OUT_DIR/bundle.tar.age"
RECIPIENT_FILE="$OUT_DIR/bundle.age.recipient.txt"
EVIDENCE_FILE="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_int_007_dr_bundle_generator.json}"
THRESHOLD_MS="${INT_007_THRESHOLD_MS:-120000}"
AGE_BIN="${AGE_BIN:-}"
AGE_KEYGEN_BIN="${AGE_KEYGEN_BIN:-}"

if [[ -z "$AGE_BIN" ]]; then
  if command -v age >/dev/null 2>&1; then
    AGE_BIN="$(command -v age)"
  elif [[ -x "$ROOT_DIR/.toolchain/age/usr/bin/age" ]]; then
    AGE_BIN="$ROOT_DIR/.toolchain/age/usr/bin/age"
  else
    echo "missing_age_binary" >&2
    exit 1
  fi
fi

if [[ -z "$AGE_KEYGEN_BIN" ]]; then
  if command -v age-keygen >/dev/null 2>&1; then
    AGE_KEYGEN_BIN="$(command -v age-keygen)"
  elif [[ -x "$ROOT_DIR/.toolchain/age/usr/bin/age-keygen" ]]; then
    AGE_KEYGEN_BIN="$ROOT_DIR/.toolchain/age/usr/bin/age-keygen"
  else
    echo "missing_age_keygen_binary" >&2
    exit 1
  fi
fi

INPUTS=(
  "evidence/phase1/approval_metadata.json"
  "evidence/phase1/agent_conformance_architect.json"
  "evidence/phase1/agent_conformance_implementer.json"
  "evidence/phase1/agent_conformance_policy_guardian.json"
  "evidence/phase1/human_governance_review_signoff.json"
  "evidence/phase1/invproc_06_ci_wiring_closeout.json"
  "evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json"
  "evidence/phase1/tsk_p1_int_003_tamper_detection.json"
  "evidence/phase1/tsk_p1_int_004_ack_gap_controls.json"
  "evidence/phase1/tsk_p1_int_005_restricted_posture.json"
  "evidence/phase1/tsk_p1_int_006_offline_bridge.json"
  "evidence/phase0/key_management_policy.json"
  "evidence/phase0/revocation_tables.json"
  "docs/security/KEY_MANAGEMENT_POLICY.md"
  "docs/operations/KEY_ROTATION_SOP.md"
)

VERIFIER_TOOLS=(
  "scripts/audit/verify_tsk_p1_int_002.sh"
  "scripts/audit/verify_tsk_p1_int_003.sh"
  "scripts/audit/verify_tsk_p1_int_004.sh"
  "scripts/audit/verify_tsk_p1_int_005.sh"
  "scripts/audit/verify_tsk_p1_int_006.sh"
)

for path in "${VERIFIER_TOOLS[@]}"; do
  [[ -f "$path" ]] || { echo "missing_required_verifier:$path" >&2; exit 1; }
done

# Refresh live evidence inputs so the bundle is built from current verifier output,
# even after pre_ci has cleaned evidence directories.
bash scripts/audit/verify_tsk_p1_int_002.sh
bash scripts/audit/verify_tsk_p1_int_003.sh
bash scripts/audit/verify_tsk_p1_int_004.sh
bash scripts/audit/verify_tsk_p1_int_005.sh
bash scripts/audit/verify_tsk_p1_int_006.sh

for path in "${INPUTS[@]}"; do
  [[ -f "$path" ]] || { echo "missing_input_after_refresh:$path" >&2; exit 1; }
done

mkdir -p "$OUT_DIR" "$CANON_DIR" "$ARTIFACT_DIR" "$TOOLS_DIR" "$POLICY_DIR" "$KEYS_DIR"
rm -rf "$STAGING_DIR"
mkdir -p "$CANON_DIR" "$ARTIFACT_DIR" "$TOOLS_DIR" "$POLICY_DIR"
rm -f "$MANIFEST" "$SIGNATURE" "$SIGNING_PUB" "$ENCRYPTED_BUNDLE" "$RECIPIENT_FILE"

start_epoch="$(python3 - <<'PY'
import time
print(f"{time.time():.6f}")
PY
)"

run_id="${SYMPHONY_RUN_ID:-int007-$(date -u +%Y%m%dT%H%M%SZ)}"
export run_id

for input in "${INPUTS[@]}"; do
  dest="$ARTIFACT_DIR/${input}"
  mkdir -p "$(dirname "$dest")"
  cp "$input" "$dest"
done

for tool in "${VERIFIER_TOOLS[@]}"; do
  dest="$TOOLS_DIR/${tool}"
  mkdir -p "$(dirname "$dest")"
  cp "$tool" "$dest"
  chmod 0755 "$dest"
done

cp docs/security/KEY_MANAGEMENT_POLICY.md "$POLICY_DIR/KEY_MANAGEMENT_POLICY.md"
cp docs/operations/KEY_ROTATION_SOP.md "$POLICY_DIR/KEY_ROTATION_SOP.md"

python3 - <<'PY' "$ARTIFACT_DIR" "$CANON_DIR"
import json
import shutil
import sys
from pathlib import Path

artifact_dir = Path(sys.argv[1])
canon_dir = Path(sys.argv[2])

for path in sorted(artifact_dir.rglob("*")):
    if not path.is_file():
        continue
    rel = path.relative_to(artifact_dir)
    out = canon_dir / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix == ".json":
        payload = json.loads(path.read_text(encoding="utf-8"))
        out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    else:
        shutil.copy2(path, out)
PY

cat > "$CUSTODY_DOC" <<'EOF'
# TSK-P1-INT-007 Recovery Material Custody Handoff

Bundle class: disaster-recovery verification bundle  
Protection method: age (X25519 recipient encryption)  
Environment: sandbox / development demonstration only

## Designated Holders

- Primary holder: symphony-dr-primary
- Secondary holder: symphony-dr-secondary

## Handoff Requirements

1. Recovery material must be stored separately from the encrypted bundle.
2. The encrypted bundle may be copied freely; decryption requires the age secret key.
3. Holders must verify the detached manifest signature before using bundle contents.
4. Historical verification must use only the bundled verifier tooling and canonicalized artifacts.

## Sandbox Demonstration Note

For this Phase-1 task, the age identity is checked into `scripts/dr/output/tsk_p1_int_007/recovery/`
so `TSK-P1-INT-008` can perform a shared-nothing offline verification in the same repo.
This is acceptable only for sandbox demonstration. Production custody must externalize
the private recovery material.
EOF

"$AGE_KEYGEN_BIN" -o "$KEYS_DIR/primary_recovery.agekey" >"$RECIPIENT_FILE" 2>"$KEYS_DIR/primary_recovery.publog"
recipient="$(awk '/Public key:/ {print $3}' "$KEYS_DIR/primary_recovery.publog")"
printf '%s\n' "$recipient" > "$RECIPIENT_FILE"

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$KEYS_DIR/manifest_signing_private.pem" >/dev/null 2>&1
openssl pkey -in "$KEYS_DIR/manifest_signing_private.pem" -pubout -out "$SIGNING_PUB" >/dev/null 2>&1
signing_reference="openssl-rsa-sha256:$SIGNING_PUB"

python3 - <<'PY' "$STAGING_DIR" "$MANIFEST" "$signing_reference" "$recipient" "$run_id"
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

staging_dir = Path(sys.argv[1])
manifest = Path(sys.argv[2])
signing_reference = sys.argv[3]
recipient = sys.argv[4]
run_id = sys.argv[5]

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def git_sha() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

entries = []
for path in sorted(staging_dir.rglob("*")):
    if not path.is_file():
        continue
    entries.append({
        "path": str(path.relative_to(staging_dir)),
        "sha256": sha256(path),
        "size_bytes": path.stat().st_size,
    })

manifest_payload = {
    "schema_version": "1.0",
    "task_id": "TSK-P1-INT-007",
    "check_id": "TSK-P1-INT-007-DR-BUNDLE",
    "run_id": run_id,
    "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "bundle_version": "phase1-int007-v1",
    "signing_reference": signing_reference,
    "protection_method": "age",
    "age_recipient": recipient,
    "entries": entries,
}
manifest.write_text(json.dumps(manifest_payload, indent=2) + "\n", encoding="utf-8")
PY

openssl dgst -sha256 -sign "$KEYS_DIR/manifest_signing_private.pem" -out "$SIGNATURE" "$MANIFEST"

tar -C "$STAGING_DIR" -cf "$OUT_DIR/bundle.tar" .
"$AGE_BIN" -r "$recipient" -o "$ENCRYPTED_BUNDLE" "$OUT_DIR/bundle.tar"

"$AGE_BIN" -d -i "$KEYS_DIR/primary_recovery.agekey" -o "$OUT_DIR/bundle.verify.tar" "$ENCRYPTED_BUNDLE"
cmp -s "$OUT_DIR/bundle.tar" "$OUT_DIR/bundle.verify.tar"
rm -f "$OUT_DIR/bundle.verify.tar" "$OUT_DIR/bundle.tar"

python3 - <<'PY' "$EVIDENCE_FILE" "$OUT_DIR" "$MANIFEST" "$SIGNATURE" "$SIGNING_PUB" "$ENCRYPTED_BUNDLE" "$RECIPIENT_FILE" "$CUSTODY_DOC" "$THRESHOLD_MS" "$start_epoch" "$run_id"
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

evidence_path, out_dir, manifest, signature, signing_pub, encrypted_bundle, recipient_file, custody_doc, threshold_ms, start_epoch, run_id = sys.argv[1:]
out_dir = Path(out_dir)

def git_sha() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

manifest_payload = json.loads(Path(manifest).read_text(encoding="utf-8"))
elapsed_ms = int((time.time() - float(start_epoch)) * 1000)

payload = {
    "check_id": "TSK-P1-INT-007-DR-BUNDLE",
    "task_id": "TSK-P1-INT-007",
    "run_id": run_id,
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": "PASS",
    "pass": True,
    "bundle_dir": str(out_dir),
    "encrypted_bundle_path": str(Path(encrypted_bundle)),
    "manifest_path": str(Path(manifest)),
    "signature_path": str(Path(signature)),
    "signing_public_key_path": str(Path(signing_pub)),
    "recovery_recipient_path": str(Path(recipient_file)),
    "custody_doc_path": str(Path(custody_doc)),
    "protection_method": "age",
    "generation_elapsed_ms": elapsed_ms,
    "generation_threshold_ms": int(threshold_ms),
    "threshold_pass": elapsed_ms <= int(threshold_ms),
    "age_recipient": Path(recipient_file).read_text(encoding="utf-8").strip(),
    "custody_holders": [
        "symphony-dr-primary",
        "symphony-dr-secondary"
    ],
    "manifest_entry_count": len(manifest_payload["entries"]),
    "real_artifact_inputs": [
        "evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json",
        "evidence/phase1/tsk_p1_int_003_tamper_detection.json",
        "evidence/phase1/tsk_p1_int_004_ack_gap_controls.json",
        "evidence/phase1/tsk_p1_int_005_restricted_posture.json",
        "evidence/phase1/tsk_p1_int_006_offline_bridge.json",
        "evidence/phase1/approval_metadata.json",
        "evidence/phase1/human_governance_review_signoff.json",
        "evidence/phase1/invproc_06_ci_wiring_closeout.json",
        "evidence/phase0/revocation_tables.json",
        "evidence/phase0/key_management_policy.json"
    ],
    "canonicalization_archive_present": True,
    "trust_anchor_material_present": True,
    "revocation_material_present": True,
    "policy_archive_present": True,
    "verifier_tooling_present": True,
    "decrypt_roundtrip_pass": True,
    "sandbox_custody_demo_only": True,
}
if not payload["threshold_pass"]:
    payload["status"] = "FAIL"
    payload["pass"] = False
    payload["reason"] = "bundle_generation_threshold_exceeded"
Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
if payload["status"] != "PASS":
    raise SystemExit(1)
PY

rm -f "$KEYS_DIR/manifest_signing_private.pem" "$KEYS_DIR/primary_recovery.publog"
echo "TSK-P1-INT-007 bundle generated. Evidence: $EVIDENCE_FILE"

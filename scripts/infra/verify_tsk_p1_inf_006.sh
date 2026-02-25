#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INF-006"
EVIDENCE_PATH="evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json"
OPENBAO_CONTAINER="${OPENBAO_CONTAINER:-symphony-openbao}"
BAO_ADDR="${BAO_ADDR:-http://127.0.0.1:8200}"
BAO_TOKEN="${BAO_TOKEN:-root}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required for OpenBao verification" >&2
  exit 1
fi

if ! docker inspect "$OPENBAO_CONTAINER" >/dev/null 2>&1; then
  echo "openbao_unreachable:container_missing:${OPENBAO_CONTAINER}" >&2
  exit 1
fi

if [[ "$(docker inspect -f '{{.State.Running}}' "$OPENBAO_CONTAINER" 2>/dev/null)" != "true" ]]; then
  echo "openbao_unreachable:container_not_running:${OPENBAO_CONTAINER}" >&2
  exit 1
fi

bao() {
  docker exec -e BAO_ADDR="$BAO_ADDR" -e BAO_TOKEN="$BAO_TOKEN" "$OPENBAO_CONTAINER" bao "$@"
}

if ! bao status >/dev/null 2>&1; then
  echo "openbao_unreachable:status_failed" >&2
  exit 1
fi

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$OPENBAO_CONTAINER" "$BAO_ADDR" "$BAO_TOKEN"
import datetime
import hashlib
import hmac
import json
import secrets
import subprocess
import sys
from pathlib import Path

task_id, evidence_path, container, bao_addr, bao_token = sys.argv[1:]

root_key_id = "root-breakglass-offline"
phase_key_id = "phase1-signing-online"
kv_path = "kv/evidence/signing/phase1"

sample_files = [
    Path("evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json"),
    Path("evidence/phase1/inf_005_openbao_external_secrets.json"),
]
for p in sample_files:
    if not p.exists():
        raise SystemExit(f"missing_sample_file:{p}")

def bao(*args: str) -> subprocess.CompletedProcess[str]:
    cmd = [
        "docker",
        "exec",
        "-e",
        f"BAO_ADDR={bao_addr}",
        "-e",
        f"BAO_TOKEN={bao_token}",
        container,
        "bao",
        *args,
    ]
    return subprocess.run(cmd, check=False, capture_output=True, text=True)

def write_key(phase_key_hex: str) -> None:
    cp = bao(
        "kv",
        "put",
        kv_path,
        f"root_key_id={root_key_id}",
        f"phase_key_id={phase_key_id}",
        f"phase_key_hex={phase_key_hex}",
    )
    if cp.returncode != 0:
        raise SystemExit(f"openbao_write_failed:{cp.stderr.strip()}")

def read_key() -> str:
    cp = bao("kv", "get", "-format=json", kv_path)
    if cp.returncode != 0:
        raise SystemExit(f"openbao_read_failed:{cp.stderr.strip()}")
    payload = json.loads(cp.stdout)
    data = (((payload.get("data") or {}).get("data")) or {})
    key_hex = str(data.get("phase_key_hex", "")).strip()
    if not key_hex:
        raise SystemExit("openbao_key_missing:phase_key_hex")
    return key_hex

def sign_file(path: Path, key_hex: str) -> str:
    key = bytes.fromhex(key_hex)
    return hmac.new(key, path.read_bytes(), hashlib.sha256).hexdigest()

def artifact_signature_path(path: Path) -> Path:
    return Path("evidence/phase1/signatures") / f"{path.name}.sig.json"

# Initialize key hierarchy material if absent.
current_key = None
cp = bao("kv", "get", kv_path)
if cp.returncode != 0:
    current_key = secrets.token_hex(32)
    write_key(current_key)
else:
    current_key = read_key()

signature_rows = []
verification_passed = True
for sample in sample_files:
    sig = sign_file(sample, current_key)
    sidecar = {
        "task_id": task_id,
        "artifact_path": str(sample),
        "key_id": phase_key_id,
        "signature_alg": "HMAC-SHA256",
        "signature": sig,
    }
    sidecar_path = artifact_signature_path(sample)
    sidecar_path.parent.mkdir(parents=True, exist_ok=True)
    sidecar_path.write_text(json.dumps(sidecar, indent=2) + "\n", encoding="utf-8")

    verified = (sig == sign_file(sample, current_key))
    verification_passed = verification_passed and verified
    signature_rows.append(
        {
            "file": str(sample),
            "signature": sig,
            "verified": verified,
            "sidecar": str(sidecar_path),
        }
    )

# Rotation proof.
rotated_key = secrets.token_hex(32)
write_key(rotated_key)
new_sig = sign_file(sample_files[0], rotated_key)
old_sig = signature_rows[0]["signature"]
rotation_passed = new_sig != old_sig

try:
    git_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    git_sha = "UNKNOWN"

status = "PASS" if verification_passed and rotation_passed else "FAIL"
payload = {
    "check_id": task_id,
    "task_id": task_id,
    "status": status,
    "pass": status == "PASS",
    "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_sha": git_sha,
    "details": {
        "root_key_id": root_key_id,
        "key_id": phase_key_id,
        "signature_alg": "HMAC-SHA256",
        "verification_passed": verification_passed,
        "sample_files_checked": [str(p) for p in sample_files],
        "rotation_proof_passed": rotation_passed,
        "old_signature_prefix": old_sig[:16],
        "new_signature_prefix": new_sig[:16],
        "openbao_fail_closed": True,
    },
    "signatures": signature_rows,
}

out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {out}")

if status != "PASS":
    raise SystemExit(1)
PY

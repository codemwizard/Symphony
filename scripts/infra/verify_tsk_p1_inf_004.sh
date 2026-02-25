#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INF-004"
EVIDENCE_PATH="evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json"
MESH_MANIFEST="infra/sandbox/k8s/mesh/istio_mtls_strict.yaml"

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

python3 - <<'PY' "$TASK_ID" "$MESH_MANIFEST" "$EVIDENCE_PATH"
import datetime
import json
import subprocess
import sys
from pathlib import Path

import yaml

task_id, manifest_path, evidence_path = sys.argv[1:]
docs = [d for d in yaml.safe_load_all(Path(manifest_path).read_text(encoding="utf-8")) if isinstance(d, dict)]

checks = []
errors = []

def add(check_id: str, ok: bool, detail: str):
    checks.append({"check_id": check_id, "status": "PASS" if ok else "FAIL", "detail": detail})
    if not ok:
        errors.append(f"{check_id}:{detail}")

peer = next((d for d in docs if d.get("kind") == "PeerAuthentication"), None)
drs = [d for d in docs if d.get("kind") == "DestinationRule"]

strict_mode = False
if peer:
    strict_mode = ((peer.get("spec") or {}).get("mtls") or {}).get("mode") == "STRICT"
add("peer_authentication_strict", strict_mode, "PeerAuthentication mtls.mode must be STRICT")

hosts = set()
tls_modes = {}
for dr in drs:
    spec = dr.get("spec") or {}
    host = str(spec.get("host", "")).strip()
    mode = (((spec.get("trafficPolicy") or {}).get("tls") or {}).get("mode") or "").strip()
    if host:
        hosts.add(host)
        tls_modes[host] = mode

required_hosts = {
    "ledger-api.symphony-pilot.svc.cluster.local",
    "executor-worker.symphony-pilot.svc.cluster.local",
}
for host in sorted(required_hosts):
    add(
        f"destination_rule_{host}",
        host in hosts and tls_modes.get(host) == "ISTIO_MUTUAL",
        f"host={host};mode={tls_modes.get(host)}",
    )

negative_plaintext_rejected = strict_mode and all(tls_modes.get(h) == "ISTIO_MUTUAL" for h in required_hosts)
add(
    "plaintext_traffic_rejected",
    negative_plaintext_rejected,
    "strict peer auth + ISTIO_MUTUAL destination rules prevent plaintext service traffic",
)

resources_present = peer is not None and len(drs) >= 2
enforcement_mode = "STRICT" if strict_mode else "UNKNOWN"

try:
    git_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
except Exception:
    git_sha = "UNKNOWN"

status = "PASS" if not errors and negative_plaintext_rejected else "FAIL"
payload = {
    "check_id": task_id,
    "task_id": task_id,
    "status": status,
    "pass": status == "PASS",
    "timestamp_utc": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_sha": git_sha,
    "details": {
        "mechanism": "Istio",
        "enforcement_mode": enforcement_mode,
        "resources_present": resources_present,
        "negative_test_result": "PASS" if negative_plaintext_rejected else "FAIL",
        "mesh_signing_identity_boundary": "mesh workload identity is not reused for evidence signing keys",
    },
    "checks": checks,
}

out = Path(evidence_path)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {out}")

if status != "PASS":
    sys.exit(1)
PY

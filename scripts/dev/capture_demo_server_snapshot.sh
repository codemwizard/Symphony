#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_ID=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="${2:-}"
      shift 2
      ;;
    --run-id=*)
      RUN_ID="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

[[ -n "$RUN_ID" ]] || { echo "--run-id is required" >&2; exit 2; }
safe_run_id="$(printf '%s' "$RUN_ID" | tr -cd 'A-Za-z0-9._-')"
[[ "$safe_run_id" == "$RUN_ID" ]] || { echo "invalid_run_id" >&2; exit 2; }

BUNDLE_ROOT="$ROOT_DIR/evidence/phase1/demo_run/$RUN_ID"
mkdir -p "$BUNDLE_ROOT"
chmod 700 "$BUNDLE_ROOT"
export ROOT_DIR RUN_ID BUNDLE_ROOT

resolve_target() {
  local rel="$1"
  local target="$BUNDLE_ROOT/$rel"
  local root_real target_real
  root_real="$(realpath -m "$BUNDLE_ROOT")"
  target_real="$(realpath -m "$target")"
  case "$target_real" in
    "$root_real"/*) ;;
    *) echo "output_path_outside_bundle_root:$rel" >&2; exit 1 ;;
  esac
  [[ ! -L "$target" ]] || { echo "symlink_output_target_forbidden:$target" >&2; exit 1; }
  printf '%s\n' "$target"
}

check_port() {
  local host="$1" port="$2"
  if timeout 2 bash -lc "</dev/tcp/$host/$port" >/dev/null 2>&1; then
    echo true
  else
    echo false
  fi
}

write_text_file() {
  local rel="$1"
  local path
  path="$(resolve_target "$rel")"
  cat > "$path"
  chmod 600 "$path"
}

# Secret fingerprints use HMAC-SHA256 with run-scoped ephemeral key material.
SNAPSHOT_HMAC_KEY="$(python3 - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
)"
export SYMPHONY_# Secret fingerprints use HMAC-SHA256 with run-scoped ephemeral key material.
SNAPSHOT_HMAC_KEY="$SNAPSHOT_HMAC_KEY"

BRANCH_REF="$(git branch --show-current 2>/dev/null || true)"
[[ -n "$BRANCH_REF" ]] || BRANCH_REF="HEAD"
CURRENT_SHA="$(git rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
ORIGIN_MAIN_SHA="$(git rev-parse refs/remotes/origin/main 2>/dev/null || echo UNKNOWN)"
FLOOR_COMMIT="${SYMPHONY_DEMO_FLOOR_COMMIT:-0e2da15d}"
FLOOR_OK=false
if git merge-base --is-ancestor "$FLOOR_COMMIT" HEAD >/dev/null 2>&1; then FLOOR_OK=true; fi
TREE_CLEAN=true
if ! git diff --quiet --ignore-submodules HEAD -- || ! git diff --cached --quiet --ignore-submodules --; then TREE_CLEAN=false; fi
PORT_8080_REACHABLE="$(check_port 127.0.0.1 8080)"
PORT_5432_REACHABLE="$(check_port 127.0.0.1 5432)"
PORT_8200_REACHABLE="$(check_port 127.0.0.1 8200)"
export BRANCH_REF CURRENT_SHA ORIGIN_MAIN_SHA FLOOR_COMMIT FLOOR_OK TREE_CLEAN PORT_8080_REACHABLE PORT_5432_REACHABLE PORT_8200_REACHABLE

if command -v ss >/dev/null 2>&1; then
  ss -ltnp > "$(resolve_target listeners.txt)"
else
  printf 'ss not available\n' > "$(resolve_target listeners.txt)"
fi
chmod 600 "$(resolve_target listeners.txt)"

docker ps --format '{{.ID}} {{.Image}} {{.Ports}} {{.Names}}' > "$(resolve_target docker_ps.txt)" 2>/dev/null || printf 'docker ps unavailable\n' > "$(resolve_target docker_ps.txt)"
chmod 600 "$(resolve_target docker_ps.txt)"

compose_detected=false
for compose_file in docker-compose.yml compose.yml infra/openbao/docker-compose.yml; do
  if [[ -f "$compose_file" ]]; then
    compose_detected=true
    break
  fi
done
if [[ "$compose_detected" == true ]] && docker compose version >/dev/null 2>&1; then
  docker compose ps > "$(resolve_target docker_compose_ps.txt)" 2>/dev/null || printf 'docker compose ps failed\n' > "$(resolve_target docker_compose_ps.txt)"
  chmod 600 "$(resolve_target docker_compose_ps.txt)"
fi

{
  echo "branch_ref=$BRANCH_REF"
  echo "current_sha=$CURRENT_SHA"
  echo "origin_main_sha=$ORIGIN_MAIN_SHA"
  echo "floor_commit=$FLOOR_COMMIT"
  echo "floor_ok=$FLOOR_OK"
  echo "tree_clean=$TREE_CLEAN"
  git remote -v 2>/dev/null || true
  git status --short 2>/dev/null || true
} > "$(resolve_target git_context.txt)"
chmod 600 "$(resolve_target git_context.txt)"

{
  echo "DATABASE_URL_present=$([[ -n "${DATABASE_URL:-}" ]] && echo true || echo false)"
  if [[ -n "${DATABASE_URL:-}" ]]; then
    timeout 5 psql "$DATABASE_URL" -X -t -A -c 'select 1' 2>&1 || true
  fi
} > "$(resolve_target postgres_snapshot.txt)"
chmod 600 "$(resolve_target postgres_snapshot.txt)"

if [[ "$PORT_8200_REACHABLE" == true ]]; then
  {
    echo "BAO_ADDR=${BAO_ADDR:-http://127.0.0.1:8200}"
    curl -fsS "${BAO_ADDR:-http://127.0.0.1:8200}/v1/sys/health" 2>&1 || true
    echo "verify_openbao_not_dev_present=$([[ -x scripts/audit/verify_openbao_not_dev.sh ]] && echo true || echo false)"
  } > "$(resolve_target openbao_snapshot.txt)"
  chmod 600 "$(resolve_target openbao_snapshot.txt)"
fi

{
  ps -eo pid,ppid,user,comm,args | rg 'dotnet|LedgerApi|symphony|openbao|postgres' || true
} > "$(resolve_target process_snapshot.txt)"
chmod 600 "$(resolve_target process_snapshot.txt)"

{
  echo 'df -h'
  df -h
  echo
  echo 'free -h'
  free -h 2>/dev/null || true
  echo
  echo 'uptime'
  uptime || true
} > "$(resolve_target system_resources.txt)"
chmod 600 "$(resolve_target system_resources.txt)"

{
  echo "hostname"
  hostname || true
  echo
  echo "hostname -I"
  hostname -I 2>/dev/null || true
  echo
  echo "ip -brief addr"
  ip -brief addr 2>/dev/null || true
} > "$(resolve_target network_identity.txt)"
chmod 600 "$(resolve_target network_identity.txt)"

python3 - <<'PY' > "$(resolve_target env_contract_snapshot.json)"
import hashlib
import hmac
import json
import os

required = [
    "SYMPHONY_RUNTIME_PROFILE",
    "ASPNETCORE_URLS",
    "DATABASE_URL",
    "INGRESS_STORAGE_MODE",
    "SYMPHONY_UI_TENANT_ID",
    "SYMPHONY_UI_API_KEY",
    "INGRESS_API_KEY",
    "ADMIN_API_KEY",
    "SYMPHONY_KNOWN_TENANTS",
]
secret_names = {"DATABASE_URL", "SYMPHONY_UI_API_KEY", "INGRESS_API_KEY", "ADMIN_API_KEY"}
key = bytes.fromhex(os.environ["SYMPHONY_SNAPSHOT_HMAC_KEY"])
rows = []
for name in required:
    value = os.environ.get(name, "")
    row = {
        "name": name,
        "present": bool(value),
        "source": "environment",
    }
    if name in secret_names and value:
        row["fingerprint_hmac_sha256_24"] = hmac.new(key, f"{name}:{value}".encode(), hashlib.sha256).hexdigest()[:24]
    rows.append(row)
print(json.dumps({"run_id": os.environ["RUN_ID"], "vars": rows}, indent=2))
PY
chmod 600 "$(resolve_target env_contract_snapshot.json)"

python3 - <<'PY' > "$(resolve_target server_snapshot.json)"
import json
import os
import platform
import subprocess

def cmd(args):
    try:
        return subprocess.check_output(args, text=True).strip()
    except Exception:
        return "missing"

def systemctl_state(name):
    return cmd(["systemctl", "is-active", name])

payload = {
    "hostname": cmd(["hostname"]),
    "kernel": platform.release(),
    "distro": platform.platform(),
    "timestamp_utc": cmd(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
    "current_branch_ref": os.environ.get("BRANCH_REF", ""),
    "current_sha": os.environ.get("CURRENT_SHA", ""),
    "origin_main_sha": os.environ.get("ORIGIN_MAIN_SHA", ""),
    "floor_commit": os.environ.get("FLOOR_COMMIT", ""),
    "floor_commit_ok": os.environ.get("FLOOR_OK", "false") == "true",
    "clean_tree_ok": os.environ.get("TREE_CLEAN", "false") == "true",
    "versions": {
        "dotnet": cmd(["dotnet", "--version"]),
        "docker": cmd(["docker", "--version"]),
        "docker_compose": cmd(["docker", "compose", "version"]),
        "psql": cmd(["psql", "--version"]),
        "kubectl": cmd(["kubectl", "version", "--client", "--short"]),
    },
    "services": {
        "docker": systemctl_state("docker"),
        "k3s": systemctl_state("k3s"),
    },
    "listeners": {
        "8080": os.environ.get("PORT_8080_REACHABLE"),
        "5432": os.environ.get("PORT_5432_REACHABLE"),
        "8200": os.environ.get("PORT_8200_REACHABLE"),
    },
    "postgres_reachable": os.environ.get("PORT_5432_REACHABLE") == "true",
    "openbao_reachable": os.environ.get("PORT_8200_REACHABLE") == "true",
    "current_user": os.environ.get("USER", "unknown"),
    "effective_network_identity_path": f"evidence/phase1/demo_run/{os.environ['RUN_ID']}/network_identity.txt",
}
print(json.dumps(payload, indent=2))
PY
chmod 600 "$(resolve_target server_snapshot.json)"

echo "Snapshot written: $BUNDLE_ROOT"

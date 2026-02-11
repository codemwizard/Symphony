#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/infra/openbao/docker-compose.yml"
CONFIG_FILE="$ROOT_DIR/infra/openbao/openbao.hcl"
STATE_DIR="/tmp/symphony_openbao"
ROLE_NAME="symphony-app"
POLICY_NAME="symphony-read"
BAO_ADDR="http://127.0.0.1:8200"
ROOT_TOKEN="root"

mkdir -p "$STATE_DIR"

if [[ "${SKIP_OPENBAO_BOOTSTRAP:-0}" == "1" ]]; then
  echo "Skipping OpenBao bootstrap because SKIP_OPENBAO_BOOTSTRAP=1" >&2
  exit 0
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "OpenBao compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "OpenBao config file not found: $CONFIG_FILE" >&2
  exit 1
fi

docker compose -f "$COMPOSE_FILE" up -d

# Wait for health
for i in {1..30}; do
  if curl -sS "$BAO_ADDR/v1/sys/health" >/dev/null; then
    break
  fi
  sleep 1
  if [[ $i -eq 30 ]]; then
    echo "OpenBao not healthy at $BAO_ADDR" >&2
    exit 1
  fi
done

# Use bao CLI inside container
bao_exec() {
  docker exec -e BAO_ADDR="$BAO_ADDR" -e BAO_TOKEN="$ROOT_TOKEN" symphony-openbao bao "$@"
}

# Audit device is managed declaratively via config (see infra/openbao/openbao.hcl)

# Enable kv-v2 (ignore if exists)
bao_exec secrets enable -path=kv kv-v2 || true

# Enable approle auth (ignore if exists)
bao_exec auth enable approle || true

# Write policy: allow read on kv/data/allowed/*
cat > "$STATE_DIR/policy.hcl" <<'POLICY'
path "kv/data/allowed/*" {
  capabilities = ["read"]
}
POLICY

docker cp "$STATE_DIR/policy.hcl" symphony-openbao:/tmp/policy.hcl
bao_exec policy write "$POLICY_NAME" /tmp/policy.hcl

# Create role
bao_exec write auth/approle/role/$ROLE_NAME token_policies="$POLICY_NAME" token_ttl=1h token_max_ttl=4h

# Create secrets for smoke test
bao_exec kv put kv/allowed/test value="ok"
bao_exec kv put kv/forbidden/test value="nope"

# Fetch role_id and secret_id
ROLE_ID=$(bao_exec read -field=role_id auth/approle/role/$ROLE_NAME/role-id)
SECRET_ID=$(bao_exec write -field=secret_id -f auth/approle/role/$ROLE_NAME/secret-id)

printf '%s' "$ROLE_ID" > "$STATE_DIR/role_id"
printf '%s' "$SECRET_ID" > "$STATE_DIR/secret_id"

echo "OpenBao bootstrap complete. role_id and secret_id saved to $STATE_DIR."

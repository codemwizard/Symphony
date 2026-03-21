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

# Write policy: allow read on kv/data/symphony/secrets/*
cat > "$STATE_DIR/policy.hcl" <<'POLICY'
path "kv/data/symphony/secrets/*" {
  capabilities = ["read"]
}
path "kv/data/allowed/test" {
  capabilities = ["read"]
}
POLICY

docker cp "$STATE_DIR/policy.hcl" symphony-openbao:/tmp/policy.hcl
bao_exec policy write "$POLICY_NAME" /tmp/policy.hcl

# Create role
bao_exec write auth/approle/role/$ROLE_NAME token_policies="$POLICY_NAME" token_ttl=1h token_max_ttl=4h

# ─── Seed 5 distinct key domains ───
# Each domain has its own OpenBao path to prevent key-domain collapse.
# Secrets are generated fresh on each bootstrap (dev/smoke-test only).

INGRESS_KEY=$(openssl rand -hex 32)
ADMIN_KEY=$(openssl rand -hex 32)
SESSION_KEY=$(openssl rand -hex 32)
INSTRUCTION_KEY=$(openssl rand -hex 32)
EVIDENCE_KEY=$(openssl rand -hex 32)
EVIDENCE_KEY_ID="evidence-signing-key-v1"

bao_exec kv put kv/symphony/secrets/api         ingress_api_key="$INGRESS_KEY"
bao_exec kv put kv/symphony/secrets/admin        admin_api_key="$ADMIN_KEY"
bao_exec kv put kv/symphony/secrets/session      operator_session_key="$SESSION_KEY"
bao_exec kv put kv/symphony/secrets/instruction  demo_instruction_signing_key="$INSTRUCTION_KEY"
bao_exec kv put kv/symphony/secrets/signing      evidence_signing_key="$EVIDENCE_KEY" evidence_signing_key_id="$EVIDENCE_KEY_ID"

# Legacy smoke-test paths (kept for openbao_smoke_test.sh compatibility)
bao_exec kv put kv/allowed/test value="ok"
bao_exec kv put kv/forbidden/test value="nope"

# Fetch role_id and secret_id
ROLE_ID=$(bao_exec read -field=role_id auth/approle/role/$ROLE_NAME/role-id)
SECRET_ID=$(bao_exec write -field=secret_id -f auth/approle/role/$ROLE_NAME/secret-id)

printf '%s' "$ROLE_ID" > "$STATE_DIR/role_id"
printf '%s' "$SECRET_ID" > "$STATE_DIR/secret_id"

# Export keys for local dev convenience (env-based provider fallback)
cat > "$STATE_DIR/secrets.env" <<EOF
export SYMPHONY_RUNTIME_PROFILE="pilot-demo"
export BAO_ROLE_ID="$ROLE_ID"
export BAO_SECRET_ID="$SECRET_ID"
export INGRESS_API_KEY="$INGRESS_KEY"
export ADMIN_API_KEY="$ADMIN_KEY"
export OPERATOR_SESSION_KEY="$SESSION_KEY"
export DEMO_INSTRUCTION_SIGNING_KEY="$INSTRUCTION_KEY"
export EVIDENCE_SIGNING_KEY="$EVIDENCE_KEY"
export EVIDENCE_SIGNING_KEY_ID="$EVIDENCE_KEY_ID"
EOF

echo "OpenBao bootstrap complete. role_id, secret_id, and secrets.env saved to $STATE_DIR."

#!/usr/bin/env bash
set -euo pipefail
file="infra/openbao/docker-compose.prod.yml"
rg -n 'openbao/openbao@sha256:' "$file" >/dev/null
if rg -n -- '-dev|-dev-root-token-id|OPENBAO_DEV_ROOT_TOKEN_ID' "$file" >/dev/null; then
  echo "❌ dev-mode OpenBao flags present in production compose"
  exit 1
fi
echo "✅ OpenBao production compose is non-dev and digest pinned"

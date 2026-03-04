#!/usr/bin/env bash
set -euo pipefail
service=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --service) service="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done
[[ -n "$service" ]] || { echo "--service is required"; exit 1; }
file="infra/openbao/docker-compose.prod.yml"
line=$(awk "/^  ${service}:/{flag=1} flag && /image:/{print; exit}" "$file")
[[ -n "$line" ]] || { echo "❌ service image not found for $service"; exit 1; }
echo "$line" | rg '@sha256:[0-9a-f]{64}' >/dev/null || { echo "❌ $service image not pinned by digest"; exit 1; }
echo "✅ $service image pinned by digest"

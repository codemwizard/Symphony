#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "missing_required_env:$name" >&2
    exit 1
  fi
}

for var in \
  SYMPHONY_RUNTIME_PROFILE \
  INGRESS_STORAGE_MODE \
  ASPNETCORE_URLS \
  DATABASE_URL \
  SYMPHONY_SECRETS_PROVIDER \
  VAULT_ADDR \
  BAO_TOKEN
do
  require_env "$var"
done

command -v psql >/dev/null 2>&1 || { echo "missing_required_dependency:psql" >&2; exit 1; }
psql "$DATABASE_URL" -Atqc 'select 1' >/dev/null

bash scripts/db/migrate.sh

LOG_DIR="$(mktemp -d)"
API_LOG="$LOG_DIR/ledger-api.log"

cleanup() {
  if [[ -n "${API_PID:-}" ]] && kill -0 "$API_PID" 2>/dev/null; then
    kill "$API_PID" 2>/dev/null || true
    wait "$API_PID" 2>/dev/null || true
  fi
  rm -rf "$LOG_DIR"
}
trap cleanup EXIT

dotnet run --no-launch-profile --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj >"$API_LOG" 2>&1 &
API_PID=$!

for _ in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:8080/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl -fsS http://127.0.0.1:8080/health >/dev/null
curl -fsS http://127.0.0.1:8080/pilot-demo/supervisory >/dev/null

verifiers=(
  "bash scripts/audit/verify_tsk_p1_demo_014.sh"
  "bash scripts/audit/verify_tsk_p1_demo_008.sh"
  "bash scripts/audit/verify_tsk_p1_demo_009.sh"
  "bash scripts/audit/verify_tsk_p1_demo_010.sh"
  "bash scripts/audit/verify_tsk_p1_demo_011.sh"
  "bash scripts/audit/verify_tsk_p1_demo_017.sh"
  "bash scripts/audit/verify_tsk_p1_demo_026.sh"
  "bash scripts/audit/verify_task_ui_wire_007.sh"
  "bash scripts/audit/verify_task_ui_wire_010.sh"
  "bash scripts/audit/verify_task_ui_wire_011.sh"
)

for cmd in "${verifiers[@]}"; do
  echo "-> $cmd"
  bash -lc "$cmd"
done

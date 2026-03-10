#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="infra/docker/.env"
DB_CONTAINER="symphony-postgres"
DB_HOST_PORT="${HOST_POSTGRES_PORT:-5432}"
KEEP_TEMP_DB="${KEEP_TEMP_DB:-0}"
TEMP_DB=""

require_docker_access() {
  command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is required"; exit 2; }
  docker info >/dev/null 2>&1 || { echo "ERROR: docker daemon is not reachable"; exit 2; }
}

pick_free_db_port() {
  port_in_use() { ss -ltn "sport = :$1" | grep -q LISTEN; }
  port_owned_by_container() {
    docker ps --format '{{.Names}} {{.Ports}}' | grep -E "^${DB_CONTAINER} .*[:.]$1->5432/tcp" >/dev/null 2>&1
  }
  if port_in_use "${DB_HOST_PORT}" && ! port_owned_by_container "${DB_HOST_PORT}"; then
    DB_HOST_PORT=55432
    if port_in_use "${DB_HOST_PORT}" && ! port_owned_by_container "${DB_HOST_PORT}"; then
      echo "ERROR: both 5432 and fallback 55432 are in use"
      exit 2
    fi
  fi
  export HOST_POSTGRES_PORT="$DB_HOST_PORT"
}

cleanup_temp_db() {
  if [[ -z "${TEMP_DB}" ]]; then
    return 0
  fi
  if [[ "${KEEP_TEMP_DB}" == "1" ]]; then
    echo "==> KEEP_TEMP_DB=1 set; leaving temp DB in place: ${TEMP_DB}"
    return 0
  fi
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${TEMP_DB}' AND pid <> pg_backend_pid();" >/dev/null 2>&1 || true
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "DROP DATABASE IF EXISTS \"${TEMP_DB}\";" >/dev/null 2>&1 || true
}
trap cleanup_temp_db EXIT

require_docker_access
pick_free_db_port

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${POSTGRES_USER:?POSTGRES_USER must be set or provided by infra/docker/.env}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set or provided by infra/docker/.env}"

export HOST_POSTGRES_PORT="$DB_HOST_PORT"
compose_cmd=(docker compose -f infra/docker/docker-compose.yml)
if [[ -f "$ENV_FILE" ]]; then
  compose_cmd+=(--env-file "$ENV_FILE")
fi
"${compose_cmd[@]}" up -d db >/dev/null

for _ in $(seq 1 30); do
  if docker exec "$DB_CONTAINER" pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker exec "$DB_CONTAINER" pg_isready -U "$POSTGRES_USER" >/dev/null 2>&1 || {
  echo "ERROR: postgres container did not become ready" >&2
  exit 2
}

ts="$(date -u +%Y%m%d%H%M%S)"
rand="$RANDOM"
TEMP_DB="symphony_tsk_p1_024_${ts}_${rand}"
TEMP_DB="$(echo "$TEMP_DB" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')"
docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
  -c "CREATE DATABASE \"${TEMP_DB}\";" >/dev/null

export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${DB_HOST_PORT}/${TEMP_DB}"

"$ROOT_DIR/scripts/db/migrate.sh" >/dev/null
"$ROOT_DIR/scripts/db/verify_anchor_sync_operational_invariant.sh"
"$ROOT_DIR/scripts/db/tests/test_anchor_sync_operational.sh"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-024 --evidence "$ROOT_DIR/evidence/phase1/anchor_sync_operational_invariant.json"
python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-024 --evidence "$ROOT_DIR/evidence/phase1/anchor_sync_resume_semantics.json"

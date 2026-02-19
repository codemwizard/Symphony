#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ -f scripts/audit/env/phase0_flags.sh ]]; then
  # shellcheck disable=SC1090
  source scripts/audit/env/phase0_flags.sh
fi

echo "==> Pre-CI local checks"

ENV_FILE="infra/docker/.env"
COMPOSE_FILE="infra/docker/docker-compose.yml"
DB_CONTAINER="symphony-postgres"
DB_HOST_PORT="${HOST_POSTGRES_PORT:-5432}"
FRESH_DB="${FRESH_DB:-1}"   # enforce CI parity by default (ephemeral DB per run)
KEEP_TEMP_DB="${KEEP_TEMP_DB:-0}" # set to 1 to keep temp DB for debugging

# For strict parity with GitHub Actions, do not allow a developer shell to override diff refs.
# Resolve an unambiguous base ref after fetch (prefer remote-tracking; fallback to local origin/main branch).
export BASE_REF=""
export HEAD_REF="HEAD"

require_docker_access() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker is required to run DB tests"
    echo "Hint: install Docker Desktop or Docker Engine and ensure 'docker' is on PATH."
    return 1
  fi

  if ! docker info >/dev/null 2>&1; then
    echo "ERROR: docker daemon is not reachable"
    echo "Hint: start Docker and verify access with: docker info"
    echo "Hint: if permission denied on /var/run/docker.sock, add your user to the docker group and re-login."
    return 1
  fi
}

pick_free_db_port() {
  # Keep CI parity on 5432 when available; fallback only when local 5432 is occupied.
  port_in_use() {
    ss -ltn "sport = :$1" | grep -q LISTEN
  }

  port_owned_by_symphony_container() {
    docker ps --format '{{.Names}} {{.Ports}}' | grep -E "^${DB_CONTAINER} .*[:.]$1->5432/tcp" >/dev/null 2>&1
  }

  if port_in_use "${DB_HOST_PORT}" && ! port_owned_by_symphony_container "${DB_HOST_PORT}"; then
    DB_HOST_PORT=55432
    if port_in_use "${DB_HOST_PORT}" && ! port_owned_by_symphony_container "${DB_HOST_PORT}"; then
      echo "ERROR: both 5432 and fallback 55432 are in use; set HOST_POSTGRES_PORT to a free port and retry."
      return 1
    fi
    echo "WARN: host port 5432 is in use; using fallback HOST_POSTGRES_PORT=${DB_HOST_PORT} for local pre-CI"
  fi
  export HOST_POSTGRES_PORT="$DB_HOST_PORT"
}

run_ci_db_parity_migration_probe() {
  local ci_user ci_password ci_probe_db role_pw_sql probe_db
  ci_user="${CI_PARITY_DB_USER:-symphony}"
  ci_password="${CI_PARITY_DB_PASSWORD:-symphony}"

  if [[ "${SKIP_CI_DB_PARITY_PROBE:-0}" == "1" ]]; then
    echo "==> CI DB parity migration probe skipped (SKIP_CI_DB_PARITY_PROBE=1)"
    return 0
  fi

  if [[ ! "$ci_user" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "ERROR: CI_PARITY_DB_USER must be a simple SQL identifier, got '$ci_user'"
    return 1
  fi

  if [[ "$ci_user" != "${POSTGRES_USER:-}" ]]; then
    echo "WARN: local POSTGRES_USER='${POSTGRES_USER:-}' differs from CI DB user '${ci_user}'"
  fi

  role_pw_sql="${ci_password//\'/\'\'}"

  echo "==> CI DB parity migration probe (fresh DB as role '${ci_user}')"
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${ci_user}') THEN CREATE ROLE ${ci_user} LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD '${role_pw_sql}'; ELSE ALTER ROLE ${ci_user} LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD '${role_pw_sql}'; END IF; END \$\$;" >/dev/null

  ci_probe_db="symphony_ci_parity_probe_$(date -u +%Y%m%d%H%M%S)_$RANDOM"
  probe_db="$(echo "$ci_probe_db" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')"
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "CREATE DATABASE \"${probe_db}\" OWNER ${ci_user};" >/dev/null

  DATABASE_URL="postgres://${ci_user}:${ci_password}@localhost:${DB_HOST_PORT}/${probe_db}" scripts/db/migrate.sh >/dev/null

  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${probe_db}' AND pid <> pg_backend_pid();" >/dev/null 2>&1 || true
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "DROP DATABASE IF EXISTS \"${probe_db}\";" >/dev/null 2>&1 || true
}

echo "==> Toolchain parity bootstrap (local)"
if [[ -x scripts/audit/bootstrap_local_ci_toolchain.sh ]]; then
  scripts/audit/bootstrap_local_ci_toolchain.sh
  export PATH="$ROOT/.toolchain/bin:$PATH"
else
  echo "ERROR: scripts/audit/bootstrap_local_ci_toolchain.sh not found"
  exit 1
fi

echo "==> Sync base ref for CI parity (refs/remotes/origin/main)"
if ! git fetch --no-tags --prune origin main:refs/remotes/origin/main >/dev/null 2>&1; then
  echo "WARN: fetch failed; probing local refs for parity diff base"
fi

BASE_REF_CANDIDATES=(
  "refs/remotes/origin/main"
  "origin/main"
  "refs/heads/origin/main"
  "FETCH_HEAD"
)
for candidate in "${BASE_REF_CANDIDATES[@]}"; do
  if git rev-parse --verify "${candidate}^{commit}" >/dev/null 2>&1; then
    export BASE_REF="$candidate"
    break
  fi
done
if [[ -z "$BASE_REF" ]]; then
  echo "ERROR: no usable origin/main ref found (tried refs/remotes/origin/main, origin/main, refs/heads/origin/main, FETCH_HEAD)"
  exit 1
fi
if [[ "$BASE_REF" != "refs/remotes/origin/main" ]]; then
  echo "WARN: using fallback BASE_REF=${BASE_REF} (remote-tracking ref unavailable)"
fi

if [[ -x scripts/audit/enforce_change_rule.sh ]]; then
  echo "==> Structural change-rule gate (CI parity, range diff)"
  BASE_REF="$BASE_REF" HEAD_REF="HEAD" scripts/audit/enforce_change_rule.sh
else
  echo "ERROR: scripts/audit/enforce_change_rule.sh not found"
  exit 1
fi

CLEAN_EVIDENCE="${CLEAN_EVIDENCE:-1}"
if [[ "$CLEAN_EVIDENCE" == "1" ]]; then
  if [[ -x scripts/ci/clean_evidence.sh ]]; then
    scripts/ci/clean_evidence.sh
  else
    echo "WARN: scripts/ci/clean_evidence.sh not found; skipping"
  fi
fi

echo "==> Governance preflight: task plan/log presence"
if [[ -x scripts/audit/verify_task_plans_present.sh ]]; then
  scripts/audit/verify_task_plans_present.sh
else
  echo "ERROR: scripts/audit/verify_task_plans_present.sh not found"
  exit 1
fi

echo "==> Phase-0 parity verification (static)"
if [[ -x scripts/audit/verify_phase0_parity.sh ]]; then
  scripts/audit/verify_phase0_parity.sh
else
  echo "ERROR: scripts/audit/verify_phase0_parity.sh not found"
  exit 1
fi

echo "==> Remediation trace gate (production-affecting changes)"
if [[ -f scripts/audit/verify_remediation_trace.sh ]]; then
  # Range diff is required for parity with CI (commit-range, not worktree/staged).
  REMEDIATION_TRACE_DIFF_MODE="${REMEDIATION_TRACE_DIFF_MODE:-range}" bash scripts/audit/verify_remediation_trace.sh
else
  echo "ERROR: scripts/audit/verify_remediation_trace.sh not found"
  exit 1
fi

echo "==> Agent conformance verification"
if [[ -x scripts/audit/verify_agent_conformance.sh ]]; then
  scripts/audit/verify_agent_conformance.sh
else
  echo "ERROR: scripts/audit/verify_agent_conformance.sh not found"
  exit 1
fi

echo "==> Agent conformance spec verification"
if [[ -x scripts/audit/verify_agent_conformance_spec.sh ]]; then
  scripts/audit/verify_agent_conformance_spec.sh
else
  echo "ERROR: scripts/audit/verify_agent_conformance_spec.sh not found"
  exit 1
fi

if [[ -x scripts/services/test_ingress_api_contract.sh ]]; then
  echo "==> Phase-1 ingress API contract self-test"
  scripts/services/test_ingress_api_contract.sh
fi

if [[ -x scripts/services/test_executor_worker_runtime.sh ]]; then
  echo "==> Phase-1 executor worker runtime self-test"
  scripts/services/test_executor_worker_runtime.sh
fi

if [[ -x scripts/services/test_evidence_pack_api_contract.sh ]]; then
  echo "==> Phase-1 evidence pack API self-test"
  scripts/services/test_evidence_pack_api_contract.sh
fi

if [[ -x scripts/services/test_exception_case_pack_generator.sh ]]; then
  echo "==> Phase-1 exception case-pack self-test"
  scripts/services/test_exception_case_pack_generator.sh
fi

if [[ -x scripts/services/test_pilot_authz_tenant_boundary.sh ]]; then
  echo "==> Phase-1 pilot authz tenant-boundary self-test"
  scripts/services/test_pilot_authz_tenant_boundary.sh
fi

if [[ -x scripts/audit/verify_pilot_harness_readiness.sh ]]; then
  echo "==> Phase-1 pilot harness readiness verification"
  scripts/audit/verify_pilot_harness_readiness.sh
fi

if [[ -x scripts/audit/verify_product_kpi_readiness.sh ]]; then
  echo "==> Phase-1 product KPI readiness verification"
  scripts/audit/verify_product_kpi_readiness.sh
fi

if [[ -x scripts/security/verify_sandbox_deploy_manifest_posture.sh ]]; then
  echo "==> Phase-1 sandbox deploy posture verification"
  scripts/security/verify_sandbox_deploy_manifest_posture.sh
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  if [[ -n "${POSTGRES_USER:-}" && -n "${POSTGRES_PASSWORD:-}" && -n "${POSTGRES_DB:-}" ]]; then
    DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${DB_HOST_PORT}/${POSTGRES_DB}"
    export DATABASE_URL
  fi
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: DATABASE_URL not set and infra/docker/.env missing required POSTGRES_* values"
  exit 1
fi

if ! require_docker_access; then
  exit 1
fi

if ! pick_free_db_port; then
  exit 1
fi

if [[ -f "$COMPOSE_FILE" ]]; then
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d
else
  echo "ERROR: $COMPOSE_FILE not found"
  exit 1
fi

echo "==> Waiting for postgres container to be healthy"
for i in {1..60}; do
  if docker exec "$DB_CONTAINER" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! docker exec "$DB_CONTAINER" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
  echo "ERROR: postgres container not ready"
  exit 1
fi

if ! run_ci_db_parity_migration_probe; then
  echo "ERROR: CI DB parity migration probe failed"
  exit 1
fi

# Fresh DB parity: create an ephemeral database per run and drop it on exit.
# This avoids mutating a developer's long-lived dev DB while still giving CI-equivalent freshness.
TEMP_DB=""
cleanup_temp_db() {
  if [[ "${FRESH_DB}" != "1" ]]; then
    return 0
  fi
  if [[ -z "${TEMP_DB}" ]]; then
    return 0
  fi
  if [[ "${KEEP_TEMP_DB}" == "1" ]]; then
    echo "==> KEEP_TEMP_DB=1 set; leaving temp DB in place: ${TEMP_DB}"
    return 0
  fi
  echo "==> Dropping temp DB: ${TEMP_DB}"
  # terminate connections then drop
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${TEMP_DB}' AND pid <> pg_backend_pid();" >/dev/null 2>&1 || true
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "DROP DATABASE IF EXISTS \"${TEMP_DB}\";" >/dev/null 2>&1 || true
}
trap cleanup_temp_db EXIT

if [[ "${FRESH_DB}" == "1" ]]; then
  echo "==> Fresh DB parity enabled (FRESH_DB=1): creating ephemeral DB"
  # Postgres DB identifiers must be <=63 chars, lowercase + underscores are safest.
  ts="$(date -u +%Y%m%d%H%M%S)"
  rand="$RANDOM"
  base="symphony_pre_ci_${ts}_${rand}"
  TEMP_DB="$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')"
  docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 -X \
    -c "CREATE DATABASE \"${TEMP_DB}\";" >/dev/null
  DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${DB_HOST_PORT}/${TEMP_DB}"
  export DATABASE_URL
  echo "   DATABASE_URL set to ephemeral DB: ${TEMP_DB}"
else
  echo "==> Fresh DB parity disabled (FRESH_DB=${FRESH_DB}); using DATABASE_URL as provided"
fi

if [[ -x scripts/audit/run_phase0_ordered_checks.sh ]]; then
  scripts/audit/run_phase0_ordered_checks.sh
else
  echo "ERROR: scripts/audit/run_phase0_ordered_checks.sh not found"
  exit 1
fi

echo "==> DB verify_invariants.sh"
if [[ -x scripts/db/verify_invariants.sh ]]; then
  # Control-plane reference (INV-031 / INT-G22): scripts/db/tests/test_outbox_pending_indexes.sh
  # Control-plane reference (INV-113 / INT-G29): scripts/db/verify_anchor_sync_operational_invariant.sh
  # Control-plane reference (INV-117 / INT-G32): scripts/db/verify_timeout_posture.sh
  # Control-plane reference (INV-118 / INT-G33): scripts/db/tests/test_ingress_hotpath_indexes.sh
  SKIP_POLICY_SEED=1 scripts/db/verify_invariants.sh
else
  echo "ERROR: scripts/db/verify_invariants.sh not found"
  exit 1
fi

echo "==> Phase-0 contract evidence status (merged local evidence)"
if [[ -x scripts/audit/verify_phase0_contract_evidence_status.sh ]]; then
  CI_ONLY=1 EVIDENCE_ROOT="evidence/phase0" scripts/audit/verify_phase0_contract_evidence_status.sh
else
  echo "ERROR: scripts/audit/verify_phase0_contract_evidence_status.sh not found"
  exit 1
fi

echo "==> Sovereign/Regulator DB posture verifiers (Phase-0 placeholders until implemented)"
if [[ -x scripts/db/verify_boz_observability_role.sh ]]; then
  scripts/db/verify_boz_observability_role.sh
fi
if [[ -x scripts/db/verify_anchor_sync_hooks.sh ]]; then
  scripts/db/verify_anchor_sync_hooks.sh
fi
if [[ -x scripts/db/verify_anchor_sync_operational_invariant.sh ]]; then
  scripts/db/verify_anchor_sync_operational_invariant.sh
fi
if [[ -x scripts/db/verify_timeout_posture.sh ]]; then
  scripts/db/verify_timeout_posture.sh
fi
if [[ -x scripts/db/verify_instruction_finality_invariant.sh ]]; then
  scripts/db/verify_instruction_finality_invariant.sh
fi
if [[ -x scripts/db/verify_pii_decoupling_hooks.sh ]]; then
  scripts/db/verify_pii_decoupling_hooks.sh
fi
if [[ -x scripts/db/verify_rail_sequence_truth_anchor.sh ]]; then
  scripts/db/verify_rail_sequence_truth_anchor.sh
fi

if [[ -n "${DATABASE_URL:-}" ]]; then
  if [[ -x scripts/db/tests/test_db_functions.sh ]]; then
    scripts/db/tests/test_db_functions.sh
  fi
  if [[ -x scripts/db/tests/test_idempotency_zombie.sh ]]; then
    scripts/db/tests/test_idempotency_zombie.sh
  fi
  if [[ -x scripts/db/tests/test_outbox_claim_semantics.sh ]]; then
    scripts/db/tests/test_outbox_claim_semantics.sh
  fi
  if [[ -x scripts/db/tests/test_outbox_lease_fencing.sh ]]; then
    scripts/db/tests/test_outbox_lease_fencing.sh
  fi
  if [[ -x scripts/db/tests/test_instruction_finality.sh ]]; then
    scripts/db/tests/test_instruction_finality.sh
  fi
  if [[ -x scripts/db/tests/test_pii_decoupling.sh ]]; then
    scripts/db/tests/test_pii_decoupling.sh
  fi
  if [[ -x scripts/db/tests/test_rail_sequence_continuity.sh ]]; then
    scripts/db/tests/test_rail_sequence_continuity.sh
  fi
  if [[ -x scripts/db/tests/test_anchor_sync_operational.sh ]]; then
    scripts/db/tests/test_anchor_sync_operational.sh
  fi
  if [[ -x scripts/db/tests/test_ingress_hotpath_indexes.sh ]]; then
    scripts/db/tests/test_ingress_hotpath_indexes.sh
  fi

  # CI parity: these DB checks run in GitHub Actions db_verify_invariants job.
  if [[ -x scripts/db/n_minus_one_check.sh ]]; then
    scripts/db/n_minus_one_check.sh
  fi
  if [[ -x scripts/db/tests/test_no_tx_migrations.sh ]]; then
    scripts/db/tests/test_no_tx_migrations.sh
  fi

  echo "==> Policy seed checksum tests"
  if [[ -x scripts/db/tests/test_seed_policy_checksum.sh ]]; then
    scripts/db/tests/test_seed_policy_checksum.sh
  fi
fi

echo "==> Phase-0 contract evidence status (post-DB parity)"
if [[ -x scripts/audit/verify_phase0_contract_evidence_status.sh ]]; then
  scripts/audit/verify_phase0_contract_evidence_status.sh
else
  echo "ERROR: scripts/audit/verify_phase0_contract_evidence_status.sh not found"
  exit 1
fi

if [[ -x scripts/audit/verify_phase1_demo_proof_pack.sh ]]; then
  echo "==> Phase-1 regulator/tier-1 demo-proof pack verification"
  scripts/audit/verify_phase1_demo_proof_pack.sh
fi

if [[ "${RUN_PHASE1_GATES:-0}" == "1" ]]; then
  echo "==> Phase-1 evidence store mode policy verification"
  if [[ -x scripts/audit/verify_evidence_store_mode_policy.sh ]]; then
    scripts/audit/verify_evidence_store_mode_policy.sh
  else
    echo "ERROR: scripts/audit/verify_evidence_store_mode_policy.sh not found"
    exit 1
  fi

  echo "==> Phase-1 perf smoke profile"
  if [[ -x scripts/audit/run_perf_smoke.sh ]]; then
    scripts/audit/run_perf_smoke.sh
  else
    echo "ERROR: scripts/audit/run_perf_smoke.sh not found"
    exit 1
  fi

  echo "==> Phase-1 no-MCP guard"
  if [[ -x scripts/audit/verify_no_mcp_phase1.sh ]]; then
    scripts/audit/verify_no_mcp_phase1.sh
  else
    echo "ERROR: scripts/audit/verify_no_mcp_phase1.sh not found"
    exit 1
  fi

  echo "==> Phase-1 no-MCP guard fixture tests"
  if [[ -x scripts/audit/tests/test_no_mcp_phase1_guard.sh ]]; then
    scripts/audit/tests/test_no_mcp_phase1_guard.sh
  else
    echo "ERROR: scripts/audit/tests/test_no_mcp_phase1_guard.sh not found"
    exit 1
  fi

  echo "==> Phase-1 approval metadata requirement fixture tests"
  if [[ -x scripts/audit/tests/test_approval_metadata_requirements.sh ]]; then
    scripts/audit/tests/test_approval_metadata_requirements.sh
  else
    echo "ERROR: scripts/audit/tests/test_approval_metadata_requirements.sh not found"
    exit 1
  fi

  echo "==> Phase-1 invariant semantic integrity verification"
  if [[ -x scripts/audit/verify_invariant_semantic_integrity.sh ]]; then
    scripts/audit/verify_invariant_semantic_integrity.sh
  else
    echo "ERROR: scripts/audit/verify_invariant_semantic_integrity.sh not found"
    exit 1
  fi

  echo "==> Phase-1 invariant semantic integrity fixture tests"
  if [[ -x scripts/audit/tests/test_invariant_semantic_integrity.sh ]]; then
    scripts/audit/tests/test_invariant_semantic_integrity.sh
  else
    echo "ERROR: scripts/audit/tests/test_invariant_semantic_integrity.sh not found"
    exit 1
  fi

  echo "==> Phase-1 contract evidence status (post-DB parity)"
  if [[ -x scripts/audit/verify_phase1_contract.sh ]]; then
    scripts/audit/verify_phase1_contract.sh
  else
    echo "ERROR: scripts/audit/verify_phase1_contract.sh not found"
    exit 1
  fi

  echo "==> Phase-1 closeout verification"
  if [[ -x scripts/audit/verify_phase1_closeout.sh ]]; then
    scripts/audit/verify_phase1_closeout.sh
  else
    echo "ERROR: scripts/audit/verify_phase1_closeout.sh not found"
    exit 1
  fi
fi

echo "✅ Pre-CI local checks PASSED."

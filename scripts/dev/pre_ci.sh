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

if git rev-parse --verify refs/remotes/origin/main >/dev/null 2>&1; then
  export BASE_REF="refs/remotes/origin/main"
elif git rev-parse --verify refs/heads/origin/main >/dev/null 2>&1; then
  export BASE_REF="refs/heads/origin/main"
  echo "WARN: using local branch refs/heads/origin/main (remote-tracking ref unavailable)"
else
  echo "ERROR: no usable origin/main ref found (expected refs/remotes/origin/main or refs/heads/origin/main)"
  exit 1
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
    DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"
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
  DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${TEMP_DB}"
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

if [[ "${RUN_PHASE1_GATES:-0}" == "1" ]]; then
  echo "==> Phase-1 contract evidence status (post-DB parity)"
  if [[ -x scripts/audit/verify_phase1_contract.sh ]]; then
    scripts/audit/verify_phase1_contract.sh
  else
    echo "ERROR: scripts/audit/verify_phase1_contract.sh not found"
    exit 1
  fi
fi

echo "✅ Pre-CI local checks PASSED."

#!/usr/bin/env bash
set -Eeuo pipefail


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

PRE_CI_REPRO_COMMAND="${PRE_CI_REPRO_COMMAND:-scripts/dev/pre_ci.sh}"
export PRE_CI_REPRO_COMMAND

if [[ -f scripts/audit/pre_ci_debug_contract.sh ]]; then
  # shellcheck disable=SC1090
  source scripts/audit/pre_ci_debug_contract.sh
else
  echo "ERROR: scripts/audit/pre_ci_debug_contract.sh not found"
  exit 1
fi

pre_ci_on_error() {
  local rc=$?
  pre_ci_record_failure
  exit "$rc"
}

pre_ci_debug_init

# -- DRD lockout gate ---------------------------------------------------------
# Must run BEFORE any other gate. If a DRD lockout is active (two-strike
# non-convergence on the same failure signature), pre_ci refuses to run.
# The lockout is only cleared manually after a remediation casefile is created.
# Exit code 99 = DRD lockout. No other gate uses this code.
pre_ci_check_drd_lockout

# --- PRE_CI_CONTEXT_EXPORT ---
# Export execution context so guarded verifiers know they run inside the harness.
export PRE_CI_CONTEXT=1

# Unique run ID. Evidence files embed this; pre-generated outputs won't match.
PRE_CI_RUN_ID="${PRE_CI_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)_$$}"
export PRE_CI_RUN_ID

# Strip known bypass variables. Presence indicates an exploit attempt.
unset SKIP_VALIDATION SKIP_GATES CI_BYPASS DEBUG_OVERRIDE FORCE_PASS 2>/dev/null || true
# --- end PRE_CI_CONTEXT_EXPORT ---

# --- PRE_CI_INTEGRITY_CHECK ---
# Verify integrity of guarded verifier scripts before any gate runs.
# Hard-fails if manifest is missing or any hash mismatches.
_ic_manifest=".toolchain/script_integrity/verifier_hashes.sha256"
if [[ ! -f "$_ic_manifest" ]]; then
  echo "ERROR: integrity manifest not found at $_ic_manifest" >&2
  echo "  Run apply_execution_confinement.sh to generate it." >&2
  exit 1
fi
if ! sha256sum --check "$_ic_manifest" --quiet 2>/dev/null; then
  echo "INTEGRITY FAIL: one or more guarded scripts have been modified." >&2
  echo "  Run sha256sum --check $_ic_manifest to identify which files changed." >&2
  echo "  After reviewing, regenerate: bash _staging/symphony-enforcement-v2/execution-confinement/apply_execution_confinement.sh" >&2
  exit 1
fi
_ic_count="$(grep -c '^[0-9a-f]' "$_ic_manifest" 2>/dev/null || echo 0)"
echo "==> Script integrity OK ($_ic_count guarded scripts verified)"
unset _ic_manifest _ic_count
# --- end PRE_CI_INTEGRITY_CHECK ---

# --- STRIP_BYPASS_ENV_VARS_SOURCED ---
# Strip all known bypass environment variables unconditionally.
# An agent that sets SKIP_CI_DB_PARITY_PROBE=1 or similar is detected,
# logged, and blocked here before any gate runs.
# Sourced (not executed) so unset affects this shell.
[[ -f scripts/audit/strip_bypass_env_vars.sh ]] || {
  echo "FATAL: scripts/audit/strip_bypass_env_vars.sh missing -- env hygiene cannot be enforced" >&2
  exit 1
}
source scripts/audit/strip_bypass_env_vars.sh
# --- end STRIP_BYPASS_ENV_VARS_SOURCED ---

trap pre_ci_on_error ERR
pre_ci_print_triage_banner

if [[ -f scripts/audit/env/phase0_flags.sh ]]; then
  # shellcheck disable=SC1090
  source scripts/audit/env/phase0_flags.sh
fi

# Local pre-CI must default to development so evidence writes are not blocked by unknown env.
export SYMPHONY_ENV="${SYMPHONY_ENV:-development}"

echo "==> Pre-CI local checks"

# Local pre-CI runs should be treated as development for evidence write policy.
export SYMPHONY_ENV="${SYMPHONY_ENV:-development}"
RUN_DEMO_GATES="${RUN_DEMO_GATES:-0}"

ENV_FILE="infra/docker/.env"
COMPOSE_FILE="infra/docker/docker-compose.yml"
DB_CONTAINER="symphony-postgres"
DB_HOST_PORT="${HOST_POSTGRES_PORT:-5432}"
FRESH_DB="${FRESH_DB:-1}"   # enforce CI parity by default (ephemeral DB per run)
KEEP_TEMP_DB="${KEEP_TEMP_DB:-0}" # set to 1 to keep temp DB for debugging
SERVICE_PHASE1_EVIDENCE_DIR="$ROOT/services/ledger-api/dotnet/src/LedgerApi/evidence/phase1"
ROOT_PHASE1_EVIDENCE_DIR="$ROOT/evidence/phase1"

# For strict parity with GitHub Actions, do not allow a developer shell to override diff refs.
# Use only the canonical remote-tracking base ref.
export BASE_REF="refs/remotes/origin/main"
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

sync_phase1_service_evidence() {
  if [[ -d "$SERVICE_PHASE1_EVIDENCE_DIR" ]]; then
    mkdir -p "$ROOT_PHASE1_EVIDENCE_DIR"
    find "$SERVICE_PHASE1_EVIDENCE_DIR" -maxdepth 1 -type f -name '*.json' -print0 | while IFS= read -r -d '' file; do
      cp "$file" "$ROOT_PHASE1_EVIDENCE_DIR/$(basename "$file")"
    done
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

pre_ci_set_context "bootstrap/toolchain" "PRECI.BOOTSTRAP.TOOLCHAIN" "pre_ci.bootstrap_local_ci_toolchain" "Toolchain parity bootstrap"
echo "==> Toolchain parity bootstrap (local)"
if [[ -x scripts/audit/bootstrap_local_ci_toolchain.sh ]]; then
  scripts/audit/bootstrap_local_ci_toolchain.sh
  export PATH="$ROOT/.toolchain/bin:$PATH"
else
  echo "ERROR: scripts/audit/bootstrap_local_ci_toolchain.sh not found"
  exit 1
fi

pre_ci_set_context "source-control parity" "PRECI.SOURCE_CONTROL.ORIGIN_MAIN_SYNC" "pre_ci.origin_main_sync" "Sync base ref for CI parity"
echo "==> Sync base ref for CI parity (refs/remotes/origin/main)"
if ! git fetch --no-tags --prune origin +refs/heads/main:refs/remotes/origin/main >/dev/null 2>&1; then
  echo "ERROR: failed to fetch refs/remotes/origin/main; cannot run parity diff gates"
  exit 1
fi
if ! git rev-parse --verify "${BASE_REF}^{commit}" >/dev/null 2>&1; then
  # Some hook contexts may fetch successfully but not materialize the remote-tracking ref.
  remote_main_sha="$(git ls-remote --heads origin main 2>/dev/null | awk 'NR==1 {print $1}')"
  if [[ "$remote_main_sha" =~ ^[0-9a-f]{40}$ ]]; then
    git update-ref "${BASE_REF}" "$remote_main_sha" >/dev/null 2>&1 || true
  fi
fi
if ! git rev-parse --verify "${BASE_REF}^{commit}" >/dev/null 2>&1; then
  echo "ERROR: refs/remotes/origin/main not found after fetch"
  exit 1
fi
export BASE_REF="refs/remotes/origin/main"

pre_ci_set_context "branch-content" "PRECI.STRUCTURAL.CHANGE_RULE" "pre_ci.enforce_change_rule" "Structural change-rule gate"
if [[ -x scripts/audit/enforce_change_rule.sh ]]; then
  echo "==> Structural change-rule gate (CI parity, range diff)"
  BASE_REF="$BASE_REF" HEAD_REF="HEAD" scripts/audit/enforce_change_rule.sh
else
  echo "ERROR: scripts/audit/enforce_change_rule.sh not found"
  exit 1
fi

echo "==> Green Finance born-secure RLS lint gate (RLS-002)"
if [[ -x scripts/db/lint_rls_born_secure.sh ]]; then
  scripts/db/lint_rls_born_secure.sh
else
  echo "WARN: scripts/db/lint_rls_born_secure.sh not found; skipping"
fi

CLEAN_EVIDENCE="${CLEAN_EVIDENCE:-1}"
if [[ "$CLEAN_EVIDENCE" == "1" ]]; then
  if [[ -x scripts/ci/clean_evidence.sh ]]; then
    scripts/ci/clean_evidence.sh
  else
    echo "WARN: scripts/ci/clean_evidence.sh not found; skipping"
  fi
fi

pre_ci_set_context "shared governance state" "PRECI.GOVERNANCE.TASK_PLAN_LOG" "pre_ci.verify_task_plans_present" "Governance preflight task plan/log presence"
echo "==> Governance preflight: task plan/log presence"
if [[ -x scripts/audit/verify_task_plans_present.sh ]]; then
  scripts/audit/verify_task_plans_present.sh
else
  echo "ERROR: scripts/audit/verify_task_plans_present.sh not found"
  exit 1
fi

pre_ci_set_context "shared governance state" "PRECI.GOVERNANCE.TASK_META_SCHEMA" "pre_ci.verify_task_meta_schema" "Governance preflight strict task meta schema"
echo "==> Governance preflight: strict task meta schema"
if [[ -x scripts/audit/verify_task_meta_schema.sh ]]; then
  scripts/audit/verify_task_meta_schema.sh --mode strict --scope changed --json --out evidence/security_remediation/r_026_run_task_strict_enforcement.json
else
  echo "ERROR: scripts/audit/verify_task_meta_schema.sh not found"
  exit 1
fi

echo "==> Phase-0 task metadata truth gate (TSK-CLEAN-001)"
if [[ -x scripts/audit/verify_tsk_clean_001.sh ]]; then
  scripts/audit/verify_tsk_clean_001.sh --evidence evidence/phase0/tsk_clean_001__task_metadata_truth_pass.json
else
  echo "ERROR: scripts/audit/verify_tsk_clean_001.sh not found"
  exit 1
fi

echo "==> Phase-0 perf posture truth gate (TSK-CLEAN-002)"
if [[ -x scripts/audit/verify_tsk_clean_002.sh ]]; then
  scripts/audit/verify_tsk_clean_002.sh --evidence evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere.json
else
  echo "ERROR: scripts/audit/verify_tsk_clean_002.sh not found"
  exit 1
fi

echo "==> Phase-0 parity verification (static)"
if [[ -x scripts/audit/verify_phase0_parity.sh ]]; then
  scripts/audit/verify_phase0_parity.sh
else
  echo "ERROR: scripts/audit/verify_phase0_parity.sh not found"
  exit 1
fi

pre_ci_set_context "shared governance state" "PRECI.REMEDIATION.TRACE" "pre_ci.verify_remediation_trace" "Remediation trace gate"
echo "==> Remediation trace gate (production-affecting changes)"
if [[ -f scripts/audit/verify_remediation_trace.sh ]]; then
  # Range diff is required for parity with CI (commit-range, not worktree/staged).
  REMEDIATION_TRACE_DIFF_MODE="${REMEDIATION_TRACE_DIFF_MODE:-range}" bash scripts/audit/verify_remediation_trace.sh
else
  echo "ERROR: scripts/audit/verify_remediation_trace.sh not found"
  exit 1
fi

pre_ci_set_context "shared governance state" "PRECI.REMEDIATION.FRESHNESS" "pre_ci.verify_remediation_artifact_freshness" "Remediation artifact freshness gate"
echo "==> Remediation artifact freshness gate (guarded execution surface changes)"
if [[ -f scripts/audit/verify_remediation_artifact_freshness.sh ]]; then
  BASE_REF="$BASE_REF" HEAD_REF="HEAD" bash scripts/audit/verify_remediation_artifact_freshness.sh
else
  echo "ERROR: scripts/audit/verify_remediation_artifact_freshness.sh not found"
  exit 1
fi

pre_ci_set_context "shared governance state" "PRECI.AGENT.CONFORMANCE" "pre_ci.verify_agent_conformance" "Agent conformance verification"
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

pre_ci_set_context "branch-content" "PRECI.PHASE1.SELFTESTS" "pre_ci.phase1_selftests" "Phase-1 self-tests"
if [[ "${RUN_DEMO_GATES}" == "1" ]]; then
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

  sync_phase1_service_evidence

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
fi

pre_ci_set_context "DB/environment" "PRECI.DB.ENVIRONMENT" "pre_ci.phase1_db_verifiers" "Phase-1 DB and environment verifiers"
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

echo "==> Phase-0 levy rates structural hook verification (TSK-P0-LEVY-001)"
if [[ -x scripts/db/verify_levy_rates_hook.sh ]]; then
  scripts/db/verify_levy_rates_hook.sh
else
  echo "ERROR: scripts/db/verify_levy_rates_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 levy applicability expand-first hook verification (TSK-P0-LEVY-002)"
if [[ -x scripts/db/verify_levy_applicable_hook.sh ]]; then
  scripts/db/verify_levy_applicable_hook.sh
else
  echo "ERROR: scripts/db/verify_levy_applicable_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 levy calculation records structural hook verification (TSK-P0-LEVY-003)"
if [[ -x scripts/db/verify_levy_calculation_records_hook.sh ]]; then
  scripts/db/verify_levy_calculation_records_hook.sh
else
  echo "ERROR: scripts/db/verify_levy_calculation_records_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 levy remittance periods structural hook verification (TSK-P0-LEVY-004)"
if [[ -x scripts/db/verify_levy_remittance_periods_hook.sh ]]; then
  scripts/db/verify_levy_remittance_periods_hook.sh
else
  echo "ERROR: scripts/db/verify_levy_remittance_periods_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 KYC provider registry structural hook verification (TSK-P0-KYC-001)"
if [[ -x scripts/db/verify_kyc_provider_registry_hook.sh ]]; then
  scripts/db/verify_kyc_provider_registry_hook.sh
else
  echo "ERROR: scripts/db/verify_kyc_provider_registry_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 KYC verification records structural hook verification (TSK-P0-KYC-002)"
if [[ -x scripts/db/verify_kyc_verification_records_hook.sh ]]; then
  scripts/db/verify_kyc_verification_records_hook.sh
else
  echo "ERROR: scripts/db/verify_kyc_verification_records_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 KYC hold hook verification (TSK-P0-KYC-003)"
if [[ -x scripts/db/verify_kyc_hold_hook.sh ]]; then
  scripts/db/verify_kyc_hold_hook.sh
else
  echo "ERROR: scripts/db/verify_kyc_hold_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 KYC retention policy hook verification (TSK-P0-KYC-004)"
if [[ -x scripts/db/verify_kyc_retention_policy_hook.sh ]]; then
  scripts/db/verify_kyc_retention_policy_hook.sh
else
  echo "ERROR: scripts/db/verify_kyc_retention_policy_hook.sh not found"
  exit 1
fi

echo "==> Phase-0 gate?invariant linkage audit (TSK-P0-208)"
if [[ -x scripts/audit/verify_tsk_p0_208.sh ]]; then
  scripts/audit/verify_tsk_p0_208.sh --evidence evidence/phase0/tsk_p0_208__gate_invariant_linkage_audit.json
else
  echo "ERROR: scripts/audit/verify_tsk_p0_208.sh not found"
  exit 1
fi

echo "==> Phase-0 BoZ observability role proof (TSK-P0-210)"
if [[ -x scripts/audit/verify_tsk_p0_210.sh ]]; then
  scripts/audit/verify_tsk_p0_210.sh --evidence evidence/phase0/tsk_p0_210__boz_observability_role_proof_include_set.json
else
  echo "ERROR: scripts/audit/verify_tsk_p0_210.sh not found"
  exit 1
fi

echo "==> Phase-0 contract evidence status (merged local evidence)"
if [[ -x scripts/ci/verify_phase0_contract_evidence_status_parity.sh ]]; then
  scripts/ci/verify_phase0_contract_evidence_status_parity.sh
else
  echo "ERROR: scripts/ci/verify_phase0_contract_evidence_status_parity.sh not found"
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

echo "==> Green Finance RLS runtime verification (RLS-002)"
if [[ -x scripts/audit/verify_gf_rls_runtime.sh ]]; then
  scripts/audit/verify_gf_rls_runtime.sh
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
if [[ -x scripts/ci/verify_phase0_contract_evidence_status_parity.sh ]]; then
  scripts/ci/verify_phase0_contract_evidence_status_parity.sh
else
  echo "ERROR: scripts/ci/verify_phase0_contract_evidence_status_parity.sh not found"
  exit 1
fi

echo "==> Phase-0 required evidence parity gate (CI-equivalent)"
if [[ -x scripts/ci/check_evidence_required.sh ]]; then
  CI_ONLY=1 scripts/ci/check_evidence_required.sh evidence/phase0
else
  echo "ERROR: scripts/ci/check_evidence_required.sh not found"
  exit 1
fi

if [[ "${RUN_DEMO_GATES}" == "1" ]] && [[ -x scripts/audit/verify_phase1_demo_proof_pack.sh ]]; then
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

  echo "==> Phase-1 perf promotion verification (TSK-P1-057-FINAL)"
  if [[ -x scripts/audit/verify_p1_057_final_perf_promotion.sh ]]; then
    scripts/audit/verify_p1_057_final_perf_promotion.sh
  else
    echo "ERROR: scripts/audit/verify_p1_057_final_perf_promotion.sh not found"
    exit 1
  fi

  echo "==> Phase-1 engine metrics capture verification (PERF-001)"
  if [[ -x scripts/audit/verify_perf_001_engine_metrics_capture.sh ]]; then
    scripts/audit/verify_perf_001_engine_metrics_capture.sh
  else
    echo "ERROR: scripts/audit/verify_perf_001_engine_metrics_capture.sh not found"
    exit 1
  fi

  echo "==> Phase-1 smart regression + warmup verification (PERF-002)"
  if [[ -x scripts/audit/verify_perf_002_regression_detection_warmup.sh ]]; then
    scripts/audit/verify_perf_002_regression_detection_warmup.sh
  else
    echo "ERROR: scripts/audit/verify_perf_002_regression_detection_warmup.sh not found"
    exit 1
  fi

  echo "==> Phase-1 rebaseline SHA-lock verification (PERF-003)"
  if [[ -x scripts/audit/verify_perf_003_rebaseline_sha_lock.sh ]]; then
    scripts/audit/verify_perf_003_rebaseline_sha_lock.sh
  else
    echo "ERROR: scripts/audit/verify_perf_003_rebaseline_sha_lock.sh not found"
    exit 1
  fi

  echo "==> Phase-1 regulatory timing compliance gate (PERF-005)"
  if [[ -x scripts/perf/verify_perf_005.sh ]]; then
    scripts/perf/verify_perf_005.sh --evidence evidence/phase1/perf_005__regulatory_timing_compliance_gate.json
  else
    echo "ERROR: scripts/perf/verify_perf_005.sh not found"
    exit 1
  fi

  echo "==> Phase-1 finality seam stub verification (PERF-005A)"
  if [[ -x scripts/audit/verify_perf_005a_finality_seam_stub.sh ]]; then
    scripts/audit/verify_perf_005a_finality_seam_stub.sh
  else
    echo "ERROR: scripts/audit/verify_perf_005a_finality_seam_stub.sh not found"
    exit 1
  fi

  echo "==> Phase-1 operational risk framework + translation layer (PERF-006)"
  if [[ -x scripts/perf/verify_perf_006.sh ]]; then
    scripts/perf/verify_perf_006.sh --evidence evidence/phase1/perf_006__operational_risk_framework_translation_layer.json
  else
    echo "ERROR: scripts/perf/verify_perf_006.sh not found"
    exit 1
  fi

  echo "==> Phase-1 escrow state machine + atomic reservation semantics (TSK-P1-ESC-001)"
  if [[ -x scripts/db/verify_tsk_p1_esc_001.sh ]]; then
    scripts/db/verify_tsk_p1_esc_001.sh --evidence evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json
  else
    echo "ERROR: scripts/db/verify_tsk_p1_esc_001.sh not found"
    exit 1
  fi

  echo "==> Phase-1 escrow ceiling enforcement + tenant isolation (TSK-P1-ESC-002)"
  if [[ -x scripts/db/verify_tsk_p1_esc_002.sh ]]; then
    scripts/db/verify_tsk_p1_esc_002.sh --evidence evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json
  else
    echo "ERROR: scripts/db/verify_tsk_p1_esc_002.sh not found"
    exit 1
  fi

  echo "==> Phase-1 no backward calls verification (INV-135)"
  if [[ -x scripts/audit/verify_no_backward_calls.sh ]]; then
    scripts/audit/verify_no_backward_calls.sh
  else
    echo "ERROR: scripts/audit/verify_no_backward_calls.sh not found"
    exit 1
  fi

  echo "==> Phase-1 OU ownership registry verification (INV-136)"
  if [[ -x scripts/db/verify_ou_ownership_registry.sh ]]; then
    scripts/db/verify_ou_ownership_registry.sh
  else
    echo "ERROR: scripts/db/verify_ou_ownership_registry.sh not found"
    exit 1
  fi

  echo "==> Phase-1 plane isolation verification (INV-137)"
  if [[ -x scripts/db/verify_plane_isolation.sh ]]; then
    scripts/db/verify_plane_isolation.sh
  else
    echo "ERROR: scripts/db/verify_plane_isolation.sh not found"
    exit 1
  fi

  echo "==> Phase-1 identity provenance immutability verification (INV-142)"
  if [[ -x scripts/audit/verify_identity_provenance_immutability.sh ]]; then
    scripts/audit/verify_identity_provenance_immutability.sh
  else
    echo "ERROR: scripts/audit/verify_identity_provenance_immutability.sh not found"
    exit 1
  fi

  echo "==> Phase-1 audit precedence verification (INV-143)"
  if [[ -x scripts/audit/verify_audit_precedence.sh ]]; then
    scripts/audit/verify_audit_precedence.sh
  else
    echo "ERROR: scripts/audit/verify_audit_precedence.sh not found"
    exit 1
  fi

  echo "==> Phase-1 card-data non-presence verification (INV-144)"
  if [[ -x scripts/security/verify_card_data_non_presence.sh ]]; then
    scripts/security/verify_card_data_non_presence.sh
  else
    echo "ERROR: scripts/security/verify_card_data_non_presence.sh not found"
    exit 1
  fi

  echo "==> Phase-1 attestation/outbox atomicity verification (INV-146)"
  if [[ -x scripts/db/verify_attestation_outbox_atomicity.sh ]]; then
    scripts/db/verify_attestation_outbox_atomicity.sh
  else
    echo "ERROR: scripts/db/verify_attestation_outbox_atomicity.sh not found"
    exit 1
  fi

  echo "==> Phase-1 command lifecycle integrity verification (INV-147)"
  if [[ -x scripts/db/verify_command_lifecycle_integrity.sh ]]; then
    scripts/db/verify_command_lifecycle_integrity.sh
  else
    echo "ERROR: scripts/db/verify_command_lifecycle_integrity.sh not found"
    exit 1
  fi

  echo "==> Phase-1 instruction hierarchy SQLSTATE mapping verification (TSK-P1-HIER-009)"
  if [[ -x scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh ]]; then
    scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh --evidence evidence/phase1/hier_009_instruction_hierarchy_sqlstates.json
  else
    echo "ERROR: scripts/db/verify_hier_009_instruction_hierarchy_sqlstates.sh not found"
    exit 1
  fi

  echo "==> Phase-1 program migration contract verification (TSK-P1-HIER-010)"
  if [[ -x scripts/db/verify_hier_010_program_migration.sh ]]; then
    scripts/db/verify_hier_010_program_migration.sh --evidence evidence/phase1/hier_010_program_migration.json
  else
    echo "ERROR: scripts/db/verify_hier_010_program_migration.sh not found"
    exit 1
  fi

  echo "==> Phase-1 supervisor access mechanisms verification (TSK-P1-HIER-011)"
  if [[ -x scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh ]]; then
    scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh --evidence evidence/phase1/hier_011_supervisor_access_mechanisms.json
  else
    echo "ERROR: scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh not found"
    exit 1
  fi

  echo "==> Phase-1 container build pipeline verification (TSK-P1-INF-002)"
  if [[ -x scripts/audit/verify_inf_002_container_build_pipeline.sh ]]; then
    scripts/audit/verify_inf_002_container_build_pipeline.sh --evidence evidence/phase1/inf_002_container_build_pipeline.json
  else
    echo "ERROR: scripts/audit/verify_inf_002_container_build_pipeline.sh not found"
    exit 1
  fi

  echo "==> Phase-1 Postgres HA + backups + PITR verification (TSK-P1-INF-001)"
  if [[ -x scripts/infra/verify_tsk_p1_inf_001.sh ]]; then
    scripts/infra/verify_tsk_p1_inf_001.sh --evidence evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json
  else
    echo "ERROR: scripts/infra/verify_tsk_p1_inf_001.sh not found"
    exit 1
  fi

  echo "==> Phase-1 OpenBao + External Secrets verification (TSK-P1-INF-005)"
  if [[ -x scripts/audit/verify_inf_005_openbao_external_secrets.sh ]]; then
    scripts/audit/verify_inf_005_openbao_external_secrets.sh --evidence evidence/phase1/inf_005_openbao_external_secrets.json
  else
    echo "ERROR: scripts/audit/verify_inf_005_openbao_external_secrets.sh not found"
    exit 1
  fi

  echo "==> Phase-1 service-to-service mTLS mesh verification (TSK-P1-INF-004)"
  if [[ -x scripts/infra/verify_tsk_p1_inf_004.sh ]]; then
    scripts/infra/verify_tsk_p1_inf_004.sh --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json
  else
    echo "ERROR: scripts/infra/verify_tsk_p1_inf_004.sh not found"
    exit 1
  fi

  echo "==> Phase-1 k8s manifests + migration health proof verification (TSK-P1-INF-003)"
  if [[ -x scripts/infra/verify_tsk_p1_inf_003.sh ]]; then
    scripts/infra/verify_tsk_p1_inf_003.sh --evidence evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json
  else
    echo "ERROR: scripts/infra/verify_tsk_p1_inf_003.sh not found"
    exit 1
  fi

  echo "==> Phase-1 evidence signing key management verification (TSK-P1-INF-006)"
  if [[ -x scripts/infra/verify_tsk_p1_inf_006.sh ]]; then
    scripts/infra/verify_tsk_p1_inf_006.sh --evidence evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json
  else
    echo "ERROR: scripts/infra/verify_tsk_p1_inf_006.sh not found"
    exit 1
  fi

  echo "==> Phase-1 ingress tenant context verification (TSK-P1-TEN-001)"
  if [[ -x scripts/audit/verify_ten_001_ingress_tenant_context.sh ]]; then
    scripts/audit/verify_ten_001_ingress_tenant_context.sh --evidence evidence/phase1/ten_001_ingress_tenant_context.json
  else
    echo "ERROR: scripts/audit/verify_ten_001_ingress_tenant_context.sh not found"
    exit 1
  fi

  echo "==> Phase-1 tenant onboarding admin verification (TSK-P1-TEN-003)"
  if [[ -x scripts/audit/verify_ten_003_tenant_onboarding_admin.sh ]]; then
    scripts/audit/verify_ten_003_tenant_onboarding_admin.sh --evidence evidence/phase1/ten_003_tenant_onboarding_admin.json
  else
    echo "ERROR: scripts/audit/verify_ten_003_tenant_onboarding_admin.sh not found"
    exit 1
  fi

  echo "==> Phase-1 command/query DB role separation verification (INV-149)"
  if [[ -x scripts/db/verify_command_query_role_separation.sh ]]; then
    scripts/db/verify_command_query_role_separation.sh
  else
    echo "ERROR: scripts/db/verify_command_query_role_separation.sh not found"
    exit 1
  fi

  echo "==> Phase-1 adapter interface contract tests (TSK-P1-ADP-001)"
  if [[ -x scripts/audit/verify_adp_001_adapter_contract_tests.sh ]]; then
    scripts/audit/verify_adp_001_adapter_contract_tests.sh --evidence evidence/phase1/adp_001_adapter_contract_tests.json
  else
    echo "ERROR: scripts/audit/verify_adp_001_adapter_contract_tests.sh not found"
    exit 1
  fi

  echo "==> Phase-1 simulated rail adapter verification (TSK-P1-ADP-002)"
  if [[ -x scripts/audit/verify_adp_002_simulated_rail_adapter.sh ]]; then
    scripts/audit/verify_adp_002_simulated_rail_adapter.sh --evidence evidence/phase1/adp_002_simulated_rail_adapter.json
  else
    echo "ERROR: scripts/audit/verify_adp_002_simulated_rail_adapter.sh not found"
    exit 1
  fi

  echo "==> Phase-1 no hot-table external reads verification (INV-151)"
  if [[ -x scripts/audit/verify_no_hot_table_external_reads.sh ]]; then
    scripts/audit/verify_no_hot_table_external_reads.sh
  else
    echo "ERROR: scripts/audit/verify_no_hot_table_external_reads.sh not found"
    exit 1
  fi

  echo "==> Phase-1 incident workflow + 48-hour export verification (TSK-P1-REG-003)"
  if [[ -x scripts/audit/verify_reg_003_incident_48h_export.sh ]]; then
    scripts/audit/verify_reg_003_incident_48h_export.sh --evidence evidence/phase1/reg_003_incident_48h_export.json
  else
    echo "ERROR: scripts/audit/verify_reg_003_incident_48h_export.sh not found"
    exit 1
  fi

  echo "==> Phase-1 closeout verifier scaffold verification (TSK-P1-202)"
  if [[ -x scripts/audit/verify_tsk_p1_202.sh ]]; then
    scripts/audit/verify_tsk_p1_202.sh --evidence evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json
  else
    echo "ERROR: scripts/audit/verify_tsk_p1_202.sh not found"
    exit 1
  fi

  echo "==> Phase-1 perf closeout extension verification (PERF-004)"
  if [[ -x scripts/perf/verify_perf_004.sh ]]; then
    scripts/perf/verify_perf_004.sh --evidence evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json
  else
    echo "ERROR: scripts/perf/verify_perf_004.sh not found"
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

# --- AST_LINT_GATE ---
# AST-level structural lint: verifies psql appears as a real command
# invocation, not a comment or dead string. Mandatory — missing tool = exit 1.
echo "==> GF verifier AST lint (structural command invocation check)"
[[ -f scripts/audit/lint_verifier_ast.py ]] || {
  echo "FATAL: scripts/audit/lint_verifier_ast.py not found" >&2
  exit 1
}
/usr/bin/python3 scripts/audit/lint_verifier_ast.py \
  scripts/db/verify_gf_fnc_001.sh \
  scripts/db/verify_gf_fnc_002.sh \
  scripts/db/verify_gf_fnc_003.sh \
  scripts/db/verify_gf_fnc_004.sh \
  scripts/db/verify_gf_fnc_005.sh \
  scripts/db/verify_gf_fnc_006.sh
# --- end AST_LINT_GATE ---

echo "==> GF migration scope enforcement (TSK-P1-RLS-003)"
VENV_PYTHON=".venv/bin/python3"
if [[ ! -x "$VENV_PYTHON" ]]; then
  VENV_PYTHON="python3"
fi
GF_MIGRATIONS=(schema/migrations/008[0-9]_gf_*.sql schema/migrations/009[0-9]_gf_*.sql schema/migrations/01[0-9][0-9]_gf_*.sql)
if [[ -f scripts/db/lint_gf_migration_scope.py ]]; then
  "$VENV_PYTHON" scripts/db/lint_gf_migration_scope.py "${GF_MIGRATIONS[@]}" 2>/dev/null
else
  echo "ERROR: scripts/db/lint_gf_migration_scope.py not found"
  exit 1
fi

echo "==> RLS scope lint adversarial tests"
if [[ -f tests/rls_scope/run_tests.py ]]; then
  "$VENV_PYTHON" tests/rls_scope/run_tests.py
else
  echo "ERROR: tests/rls_scope/run_tests.py not found"
  exit 1
fi

# --- EVIDENCE_SIGNATURE_VERIFY ---
# Verify phase1 evidence was signed by sign_evidence.py in THIS run.
# Pre-generated, hand-typed, or tampered JSON files are rejected.
echo "==> Phase-1 evidence signature integrity check"
[[ -f scripts/audit/sign_evidence.py ]] || {
  echo "FATAL: scripts/audit/sign_evidence.py not found" >&2
  exit 1
}
if [[ -d evidence/phase1 ]] && compgen -G "evidence/phase1/*.json" > /dev/null 2>&1; then
  /usr/bin/python3 scripts/audit/sign_evidence.py \
    --verify \
    --dir evidence/phase1 \
    --enrollment-file scripts/audit/signed_evidence_enrollment.txt
else
  echo "  INFO: no phase1 evidence files yet -- skipping signature check"
fi
# --- end EVIDENCE_SIGNATURE_VERIFY ---

echo "==> Green Finance Schema + Function Verification"
GREEN_FINANCE_VERIFIERS=(
  "scripts/audit/verify_gf_w1_gov_005a.sh"
  "scripts/db/verify_gf_sch_001.sh"
  "scripts/db/verify_gf_sch_008.sh"
  "scripts/db/verify_gf_fnc_001.sh"
  "scripts/db/verify_gf_fnc_002.sh"
  "scripts/db/verify_gf_fnc_003.sh"
  "scripts/db/verify_gf_fnc_004.sh"
  "scripts/db/verify_gf_fnc_005.sh"
  "scripts/db/verify_gf_fnc_006.sh"
  "scripts/db/verify_gf_fnc_007a.sh"
)

for verifier in "${GREEN_FINANCE_VERIFIERS[@]}"; do
  if [[ -x "$verifier" ]]; then
    echo "Running $verifier..."
    "$verifier"
  else
    echo "WARN: $verifier not found or not executable. Skipping to permit gradual GF deployment."
  fi
done

pre_ci_clear_failure_state
echo "==> Verifying TSK-P1-210 to 220 (Hardening and Demo Architecture)"
for i in {210..220}; do
  if [[ -x "scripts/audit/verify_tsk_p1_${i}.sh" ]]; then
    "scripts/audit/verify_tsk_p1_${i}.sh"
  fi
done


# --- TSK_POST_EXEC_INTEGRITY ---
# Post-execution integrity re-check: re-verify all manifested files have not
# been swapped or modified during this run. Catches runtime swap attacks.
echo "==> Post-execution integrity check"
_post_manifest="/home/mwiza/workspace/Symphony/.toolchain/trust_manifest.sha256"
if [[ -f "$_post_manifest" ]]; then
  if ! sha256sum --check "$_post_manifest" --quiet 2>/dev/null; then
    echo "POST-EXECUTION INTEGRITY FAILURE: files were modified during the run." >&2
    echo "  This indicates a runtime swap attack or concurrent modification." >&2
    echo "  The run result is UNTRUSTED even though gates passed." >&2
    exit 1
  fi
  echo "  Post-execution integrity: OK"
else
  echo "WARN: post-execution manifest not found -- skipping re-check" >&2
fi
# --- end TSK_POST_EXEC_INTEGRITY ---
echo "? Pre-CI local checks PASSED."


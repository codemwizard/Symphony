#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RUN_ID=""
DRY_RUN=0
DEMO_MODE="${SYMPHONY_DEMO_MODE:-rehearsal-only}"
FLOOR_COMMIT="${SYMPHONY_DEMO_FLOOR_COMMIT:-0e2da15d}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="${2:-}"; shift 2 ;;
    --run-id=*) RUN_ID="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --demo-mode) DEMO_MODE="${2:-}"; shift 2 ;;
    --demo-mode=*) DEMO_MODE="${1#*=}"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$RUN_ID" ]] || RUN_ID="demo-$(date -u +%Y%m%dT%H%M%SZ)-$(git rev-parse --short HEAD)"
safe_run_id="$(printf '%s' "$RUN_ID" | tr -cd 'A-Za-z0-9._-')"
[[ "$safe_run_id" == "$RUN_ID" ]] || { echo "invalid_run_id" >&2; exit 2; }

BUNDLE_ROOT="$ROOT_DIR/evidence/phase1/demo_run/$RUN_ID"
PROCESS_DIR="$ROOT_DIR/tmp/demo_run/$RUN_ID"
LOG_DIR="$BUNDLE_ROOT/logs"
mkdir -p "$BUNDLE_ROOT" "$PROCESS_DIR" "$LOG_DIR"
chmod 700 "$BUNDLE_ROOT" "$PROCESS_DIR" "$LOG_DIR"

PID_FILE="$PROCESS_DIR/ledger-api.pid"
STDOUT_LOG="$LOG_DIR/ledger-api.stdout.log"
STDERR_LOG="$LOG_DIR/ledger-api.stderr.log"
BROWSER_CHECKLIST="$BUNDLE_ROOT/browser_smoke_checklist.json"
RUN_SUMMARY="$BUNDLE_ROOT/run_summary.json"
PROVISIONING_JSON="$BUNDLE_ROOT/provisioning_result.json"
SERVER_SMOKE_JSON="$BUNDLE_ROOT/server_smoke.json"
PORT_OFFENDER="$BUNDLE_ROOT/port_8080_offender.txt"
PUBLISH_DIR="$PROCESS_DIR/publish"
export ROOT_DIR RUN_ID BUNDLE_ROOT PROCESS_DIR LOG_DIR PID_FILE STDOUT_LOG STDERR_LOG BROWSER_CHECKLIST RUN_SUMMARY FLOOR_COMMIT DEMO_MODE

RUN_START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CURRENT_SHA="$(git rev-parse HEAD)"
export RUN_START_UTC CURRENT_SHA

MIGRATION_STATUS="not-run"
PUBLISH_STATUS="not-run"
HEALTH_STATUS="not-run"
PROVISIONING_STATUS="not-run"
SERVER_SMOKE_STATUS="not-run"
BROWSER_SMOKE_STATUS="not-run"
PILOT_HARNESS_STATUS="not-run"
DEMO_REHEARSAL_STATUS="not-run"
PROOF_PACK_STATUS="not-run"
TEARDOWN_STATUS="not-run"
KEY_ROTATION_STATUS="not-recorded"
FINAL_VERDICT="FAIL"
LIVENESS_ENDPOINT="/health"
READINESS_ENDPOINT="/health"
export MIGRATION_STATUS PUBLISH_STATUS HEALTH_STATUS PROVISIONING_STATUS SERVER_SMOKE_STATUS BROWSER_SMOKE_STATUS PILOT_HARNESS_STATUS DEMO_REHEARSAL_STATUS PROOF_PACK_STATUS TEARDOWN_STATUS KEY_ROTATION_STATUS FINAL_VERDICT LIVENESS_ENDPOINT READINESS_ENDPOINT

record_browser_checklist() {
  python3 - <<'PY'
import json, os
payload = {
    "run_id": os.environ["RUN_ID"],
    "status_values": ["manual-confirmed", "not-run", "waived"],
    "checks": [
        {"id": "open_supervisory_ui", "status": "not-run"},
        {"id": "supervisory_shell_visible", "status": "not-run"},
        {"id": "pilot_success_visible", "status": "not-run"},
        {"id": "reveal_flow_clickable", "status": "not-run"},
        {"id": "export_ux_present", "status": "not-run"}
    ],
    "mode": os.environ.get("DEMO_MODE", "rehearsal-only")
}
with open(os.environ["BROWSER_CHECKLIST"], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
    fh.write("\n")
PY
  chmod 600 "$BROWSER_CHECKLIST"
}

emit_summary() {
  python3 - <<'PY'
import json, os
from datetime import datetime, timezone
payload = {
    "run_id": os.environ["RUN_ID"],
    "start_utc": os.environ.get("RUN_START_UTC"),
    "end_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_sha": os.environ.get("CURRENT_SHA"),
    "git_ref": os.popen("git branch --show-current 2>/dev/null").read().strip() or "HEAD",
    "operator_user": os.environ.get("USER", "unknown"),
    "demo_mode": os.environ.get("DEMO_MODE"),
    "snapshot_paths": {
        "bundle_root": os.environ["BUNDLE_ROOT"],
        "browser_smoke_checklist": os.environ["BROWSER_CHECKLIST"],
    },
    "migration_status": os.environ.get("MIGRATION_STATUS"),
    "publish_status": os.environ.get("PUBLISH_STATUS"),
    "process": {
        "pid_file": os.environ["PID_FILE"],
        "stdout_log": os.environ["STDOUT_LOG"],
        "stderr_log": os.environ["STDERR_LOG"],
    },
    "health": {
        "liveness_endpoint": os.environ.get("LIVENESS_ENDPOINT", "/health"),
        "readiness_endpoint": os.environ.get("READINESS_ENDPOINT", "/health"),
        "status": os.environ.get("HEALTH_STATUS"),
    },
    "provisioning_status": os.environ.get("PROVISIONING_STATUS"),
    "server_smoke_status": os.environ.get("SERVER_SMOKE_STATUS"),
    "browser_smoke_status": os.environ.get("BROWSER_SMOKE_STATUS"),
    "pilot_harness_status": os.environ.get("PILOT_HARNESS_STATUS"),
    "demo_rehearsal_status": os.environ.get("DEMO_REHEARSAL_STATUS"),
    "proof_pack_status": os.environ.get("PROOF_PACK_STATUS"),
    "teardown_status": os.environ.get("TEARDOWN_STATUS"),
    "key_rotation_closeout_status": os.environ.get("KEY_ROTATION_STATUS"),
    "final_verdict": os.environ.get("FINAL_VERDICT"),
}
with open(os.environ["RUN_SUMMARY"], "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
    fh.write("\n")
PY
  chmod 600 "$RUN_SUMMARY"
}

cleanup_process() {
  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 2
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
}

on_exit() {
  local ec=$?
  if [[ $ec -ne 0 && "$FINAL_VERDICT" == "FAIL" ]]; then
    TEARDOWN_STATUS="cleanup-after-failure"
    export TEARDOWN_STATUS
  fi
  cleanup_process || true
  emit_summary || true
  exit $ec
}
trap on_exit EXIT
trap 'FINAL_VERDICT="FAIL"; KEY_ROTATION_STATUS="not-completed"; export FINAL_VERDICT KEY_ROTATION_STATUS; exit 130' INT TERM

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "missing_binary:$1" >&2; exit 1; }; }
require_env() { [[ -n "${!1:-}" ]] || { echo "missing_env:$1" >&2; exit 1; }; }

record_browser_checklist

# Fresh fetch source gate.
git fetch origin >/dev/null 2>&1 || { echo "origin_fetch_failed" >&2; exit 1; }
upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
[[ "$upstream_ref" == "origin/main" ]] || { echo "deployment_checkout_not_tracking_origin_main:$upstream_ref" >&2; exit 1; }
git merge-base --is-ancestor HEAD refs/remotes/origin/main >/dev/null 2>&1 || { echo "head_not_reachable_from_fetched_origin_main" >&2; exit 1; }
git merge-base --is-ancestor "$FLOOR_COMMIT" HEAD >/dev/null 2>&1 || { echo "head_below_floor_commit:$FLOOR_COMMIT" >&2; exit 1; }
git diff --quiet --ignore-submodules HEAD -- && git diff --cached --quiet --ignore-submodules -- || { echo "dirty_worktree" >&2; exit 1; }

bash scripts/dev/capture_demo_server_snapshot.sh --run-id "$RUN_ID"

require_cmd dotnet
require_cmd docker
require_cmd psql
require_cmd curl
require_cmd jq

require_env SYMPHONY_RUNTIME_PROFILE
require_env ASPNETCORE_URLS
require_env DATABASE_URL
require_env INGRESS_STORAGE_MODE
require_env SYMPHONY_UI_TENANT_ID
require_env SYMPHONY_UI_API_KEY
require_env INGRESS_API_KEY
require_env ADMIN_API_KEY
require_env SYMPHONY_KNOWN_TENANTS

[[ "$SYMPHONY_RUNTIME_PROFILE" == "pilot-demo" ]] || { echo "runtime_profile_must_be_pilot_demo" >&2; exit 1; }
[[ "$ASPNETCORE_URLS" == "http://0.0.0.0:8080" ]] || { echo "aspnetcore_urls_must_bind_0_0_0_0_8080" >&2; exit 1; }
[[ "$INGRESS_STORAGE_MODE" == "db_psql" ]] || { echo "ingress_storage_mode_must_be_db_psql" >&2; exit 1; }
[[ "$SYMPHONY_UI_API_KEY" == "$INGRESS_API_KEY" ]] || { echo "ui_api_key_mismatch_ingress_api_key" >&2; exit 1; }
printf '%s' "$SYMPHONY_KNOWN_TENANTS" | tr ',' '\n' | grep -Fx "$SYMPHONY_UI_TENANT_ID" >/dev/null || { echo "ui_tenant_not_allowlisted" >&2; exit 1; }

if ! timeout 5 bash -lc '</dev/tcp/127.0.0.1/5432' >/dev/null 2>&1; then
  echo "postgres_unreachable_127_0_0_1_5432" >&2
  exit 1
fi

# Default host behavior is a single active run. Concurrent run_id execution is forbidden by default.
occupant="$(ss -ltnp '( sport = :8080 )' 2>/dev/null | tail -n +2 || true)"
if [[ -n "$occupant" ]]; then
  if [[ -f "$PID_FILE" ]]; then
    stale_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [[ -n "$stale_pid" ]] && kill -0 "$stale_pid" 2>/dev/null; then
      cleanup_process
    else
      rm -f "$PID_FILE"
    fi
  fi
  occupant_after="$(ss -ltnp '( sport = :8080 )' 2>/dev/null | tail -n +2 || true)"
  if [[ -n "$occupant_after" ]]; then
    printf '%s\n' "$occupant_after" > "$PORT_OFFENDER"
    chmod 600 "$PORT_OFFENDER"
    echo "unknown_8080_occupant" >&2
    exit 1
  fi
fi

if [[ "$DEMO_MODE" == "full-demo" ]]; then
  [[ "${BAO_ADDR:-http://127.0.0.1:8200}" == https://* ]] || { echo "full_demo_requires_tls_openbao_addr" >&2; exit 1; }
  bash scripts/audit/verify_openbao_not_dev.sh
  bash scripts/infra/verify_tsk_p1_inf_006.sh
else
  if timeout 3 bash -lc '</dev/tcp/127.0.0.1/8200' >/dev/null 2>&1; then
    bash scripts/infra/verify_tsk_p1_inf_006.sh || true
  fi
fi

if [[ "$DRY_RUN" == "1" ]]; then
  FINAL_VERDICT="DRY_RUN_OK"
  KEY_ROTATION_STATUS="not-run"
  export FINAL_VERDICT KEY_ROTATION_STATUS
  echo "dry_run_ok:$RUN_SUMMARY"
  exit 0
fi

MIGRATION_STATUS="running"; export MIGRATION_STATUS
bash scripts/db/migrate.sh
MIGRATION_STATUS="PASS"; export MIGRATION_STATUS

mkdir -p "$PUBLISH_DIR"
dotnet publish services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj -c Release -o "$PUBLISH_DIR" >"$LOG_DIR/publish.stdout.log" 2>"$LOG_DIR/publish.stderr.log"
chmod 600 "$LOG_DIR/publish.stdout.log" "$LOG_DIR/publish.stderr.log"
PUBLISH_STATUS="PASS"; export PUBLISH_STATUS

EXECUTABLE="$PUBLISH_DIR/LedgerApi.DemoHost"
if [[ ! -x "$EXECUTABLE" ]]; then
  EXECUTABLE="$(find "$PUBLISH_DIR" -maxdepth 1 -type f -name 'LedgerApi.DemoHost*' | head -1)"
fi
[[ -n "$EXECUTABLE" && -f "$EXECUTABLE" ]] || { echo "published_executable_missing" >&2; exit 1; }

"$EXECUTABLE" >"$STDOUT_LOG" 2>"$STDERR_LOG" &
echo $! > "$PID_FILE"
chmod 600 "$PID_FILE" "$STDOUT_LOG" "$STDERR_LOG"

HEALTH_STATUS="running"; export HEALTH_STATUS
for _ in $(seq 1 30); do
  code="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/health || true)"
  if [[ "$code" == "200" ]]; then
    HEALTH_STATUS="PASS"; export HEALTH_STATUS
    break
  fi
  sleep 2
done
[[ "$HEALTH_STATUS" == "PASS" ]] || { echo "health_check_failed" >&2; exit 1; }

provision_payload="$(jq -n --arg tenant_id "$SYMPHONY_UI_TENANT_ID" --arg display_name "${SYMPHONY_DEMO_TENANT_DISPLAY_NAME:-Demo Tenant}" --arg jurisdiction_code "${SYMPHONY_DEMO_JURISDICTION_CODE:-ZM}" --arg plan "${SYMPHONY_DEMO_PLAN:-pilot}" '{tenant_id:$tenant_id,display_name:$display_name,jurisdiction_code:$jurisdiction_code,plan:$plan}')"
provision_status="$(curl -s -o "$PROVISIONING_JSON" -w '%{http_code}' -X POST http://127.0.0.1:8080/v1/admin/tenants -H 'Content-Type: application/json' -H "x-admin-api-key: ${ADMIN_API_KEY}" --data "$provision_payload" || true)"
chmod 600 "$PROVISIONING_JSON"
if [[ "$provision_status" == "200" ]]; then
  PROVISIONING_STATUS="PASS_TENANT_ONLY"; export PROVISIONING_STATUS
else
  PROVISIONING_STATUS="FAIL"; export PROVISIONING_STATUS
  echo "tenant_onboarding_failed:$provision_status" >&2
  exit 1
fi
if [[ "$DEMO_MODE" == "full-demo" ]]; then
  echo "full_demo_signoff_blocked_external_provisioning_gap" >&2
  exit 1
fi

reveal_status="$(curl -s -o "$BUNDLE_ROOT/reveal.json" -w '%{http_code}' "http://127.0.0.1:8080/v1/supervisory/programmes/${SYMPHONY_DEMO_PROGRAMME_ID:-program-a}/reveal" -H "x-api-key: ${INGRESS_API_KEY}" -H "x-tenant-id: ${SYMPHONY_UI_TENANT_ID}" || true)"
export_status="$(curl -s -o "$BUNDLE_ROOT/export.json" -w '%{http_code}' -X POST "http://127.0.0.1:8080/v1/supervisory/programmes/${SYMPHONY_DEMO_PROGRAMME_ID:-program-a}/export" -H "x-api-key: ${INGRESS_API_KEY}" -H "x-tenant-id: ${SYMPHONY_UI_TENANT_ID}" || true)"
pilot_status="$(curl -s -o "$BUNDLE_ROOT/pilot_success.json" -w '%{http_code}' "http://127.0.0.1:8080/pilot-demo/api/pilot-success" || true)"
export reveal_status export_status pilot_status
python3 - <<'PY' > "$SERVER_SMOKE_JSON"
import json, os
payload = {
    "run_id": os.environ["RUN_ID"],
    "reveal_http": os.environ["reveal_status"],
    "export_http": os.environ["export_status"],
    "pilot_success_http": os.environ["pilot_status"],
}
print(json.dumps(payload, indent=2))
PY
chmod 600 "$SERVER_SMOKE_JSON"
if [[ "$reveal_status" == "200" && "$export_status" == "200" && "$pilot_status" == "200" ]]; then
  SERVER_SMOKE_STATUS="PASS"; export SERVER_SMOKE_STATUS
else
  SERVER_SMOKE_STATUS="FAIL"; export SERVER_SMOKE_STATUS
  echo "server_smoke_failed" >&2
  exit 1
fi

bash scripts/dev/run_phase1_pilot_harness.sh
PILOT_HARNESS_STATUS="PASS"; export PILOT_HARNESS_STATUS
bash scripts/dev/run_demo_rehearsal.sh
DEMO_REHEARSAL_STATUS="PASS"; export DEMO_REHEARSAL_STATUS
bash scripts/audit/verify_phase1_demo_proof_pack.sh
PROOF_PACK_STATUS="PASS"; export PROOF_PACK_STATUS

BROWSER_SMOKE_STATUS="manual-required"; export BROWSER_SMOKE_STATUS
bash scripts/dev/capture_demo_server_snapshot.sh --run-id "$RUN_ID"

TEARDOWN_STATUS="clean-shutdown"; export TEARDOWN_STATUS
KEY_ROTATION_STATUS="waived-required-manual-closeout"; export KEY_ROTATION_STATUS
FINAL_VERDICT="REHEARSAL_ONLY_PASS"; export FINAL_VERDICT

echo "run_complete:$RUN_SUMMARY"

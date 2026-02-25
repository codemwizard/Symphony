#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INF-001"
EVIDENCE_PATH="evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

cluster_manifest="infra/sandbox/postgres-ha/cnpg_cluster.yaml"
backup_manifest="infra/sandbox/postgres-ha/backup_schedule.yaml"
pitr_script="infra/sandbox/postgres-ha/pitr_test.sh"

errors=0
ha_config_verified=false
backup_schedule_confirmed=false

if [[ ! -f "$cluster_manifest" ]]; then
  echo "missing cluster manifest: $cluster_manifest" >&2
  errors=$((errors+1))
else
  if rg -q '^kind:\s+Cluster$' "$cluster_manifest" && rg -q '^\s*instances:\s+2$' "$cluster_manifest" && rg -q 'barmanObjectStore:' "$cluster_manifest"; then
    ha_config_verified=true
  else
    errors=$((errors+1))
  fi
fi

if [[ ! -f "$backup_manifest" ]]; then
  echo "missing backup schedule manifest: $backup_manifest" >&2
  errors=$((errors+1))
else
  if rg -q '^kind:\s+ScheduledBackup$' "$backup_manifest" && rg -q 'schedule:' "$backup_manifest"; then
    backup_schedule_confirmed=true
  else
    errors=$((errors+1))
  fi
fi

if [[ ! -x "$pitr_script" ]]; then
  echo "missing pitr script: $pitr_script" >&2
  errors=$((errors+1))
  pitr_json='{"restore_target_timestamp":"","restored_schema_version":"","pitr_test_passed":false}'
else
  pitr_json="$($pitr_script)"
fi

pitr_test_passed="$(python3 - <<PY
import json
obj=json.loads('''$pitr_json''')
print('true' if obj.get('pitr_test_passed') else 'false')
PY
)"
restore_target_timestamp="$(python3 - <<PY
import json
obj=json.loads('''$pitr_json''')
print(obj.get('restore_target_timestamp',''))
PY
)"
restored_schema_version="$(python3 - <<PY
import json
obj=json.loads('''$pitr_json''')
print(obj.get('restored_schema_version',''))
PY
)"

if [[ "$pitr_test_passed" != "true" || -z "$restore_target_timestamp" || -z "$restored_schema_version" ]]; then
  errors=$((errors+1))
fi

ha_py="False"
[[ "$ha_config_verified" == "true" ]] && ha_py="True"
backup_py="False"
[[ "$backup_schedule_confirmed" == "true" ]] && backup_py="True"
pitr_py="False"
[[ "$pitr_test_passed" == "true" ]] && pitr_py="True"

status="PASS"
if (( errors > 0 )); then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<PY
import datetime, json, pathlib, subprocess
try:
    git_sha=subprocess.check_output(["git","rev-parse","HEAD"], text=True).strip()
except Exception:
    git_sha="UNKNOWN"

out={
  "check_id":"$TASK_ID",
  "task_id":"$TASK_ID",
  "status":"$status",
  "pass":"$status"=="PASS",
  "timestamp_utc":datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00','Z'),
  "git_sha":git_sha,
  "ha_config_verified": $ha_py,
  "backup_schedule_confirmed": $backup_py,
  "pitr_test_passed": $pitr_py,
  "restore_target_timestamp": "$restore_target_timestamp",
  "restored_schema_version": "$restored_schema_version",
  "manifests": {
    "cluster": "$cluster_manifest",
    "backup_schedule": "$backup_manifest"
  }
}
path=pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(out, indent=2)+"\n", encoding="utf-8")
print(f"Evidence written: {path}")
if out["status"]!="PASS":
    raise SystemExit(1)
PY

#!/usr/bin/env bash
set -euo pipefail

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

bash scripts/audit/verify_inf_001_postgres_ha_pitr.sh --evidence "$EVIDENCE_PATH"

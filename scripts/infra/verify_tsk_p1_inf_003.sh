#!/usr/bin/env bash
set -euo pipefail

EVIDENCE_PATH="evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json"

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

bash scripts/audit/verify_inf_003_k8s_manifests_migration_health.sh --evidence "$EVIDENCE_PATH"

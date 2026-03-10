#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

phase=""
slug=""
failure_signature=""
origin_task_id=""
origin_gate_id=""
repro_command=""
today="$(date -u +%F)"

usage() {
  cat <<'EOF'
Usage:
  scripts/audit/new_remediation_casefile.sh \
    --phase phase1 \
    --slug my-failure \
    --failure-signature CI.EXAMPLE.FAIL \
    --repro-command "scripts/dev/pre_ci.sh" \
    [--origin-task-id TSK-P1-000] \
    [--origin-gate-id pre_ci.example]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) phase="$2"; shift 2 ;;
    --slug) slug="$2"; shift 2 ;;
    --failure-signature) failure_signature="$2"; shift 2 ;;
    --origin-task-id) origin_task_id="$2"; shift 2 ;;
    --origin-gate-id) origin_gate_id="$2"; shift 2 ;;
    --repro-command) repro_command="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$phase" || -z "$slug" || -z "$failure_signature" || -z "$repro_command" ]]; then
  echo "ERROR: --phase, --slug, --failure-signature, and --repro-command are required" >&2
  usage
  exit 2
fi

if [[ -z "$origin_task_id" && -z "$origin_gate_id" ]]; then
  echo "ERROR: one of --origin-task-id or --origin-gate-id is required" >&2
  exit 2
fi

slug="$(printf '%s' "$slug" | tr ' /' '__' | tr -cd 'a-zA-Z0-9._-')"
case_dir="docs/plans/${phase}/REM-${today}_${slug}"
mkdir -p "$case_dir"

cat > "$case_dir/PLAN.md" <<EOF
# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: ${failure_signature}
${origin_task_id:+origin_task_id: ${origin_task_id}}
${origin_gate_id:+origin_gate_id: ${origin_gate_id}}
repro_command: ${repro_command}
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- pending
EOF

cat > "$case_dir/EXEC_LOG.md" <<EOF
# REMEDIATION EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: ${failure_signature}
${origin_task_id:+origin_task_id: ${origin_task_id}}
${origin_gate_id:+origin_gate_id: ${origin_gate_id}}
repro_command: ${repro_command}
verification_commands_run: pending
final_status: OPEN

- created_at_utc: $(date -u +%FT%TZ)
- action: remediation casefile scaffold created
EOF

echo "$case_dir"


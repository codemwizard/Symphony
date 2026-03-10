#!/usr/bin/env bash
set -euo pipefail

# pre_ci_debug_contract.sh
#
# Shared debug/remediation helpers for scripts/dev/pre_ci.sh.
# Keeps first-fail triage, failure-layer taxonomy, and two-strike
# non-convergence escalation in one place so they can be tested directly.

PRE_CI_FAILURE_LAYER="${PRE_CI_FAILURE_LAYER:-unclassified}"
PRE_CI_FAILURE_SIGNATURE="${PRE_CI_FAILURE_SIGNATURE:-PRECI.UNKNOWN}"
PRE_CI_FAILURE_GATE_ID="${PRE_CI_FAILURE_GATE_ID:-pre_ci.unknown}"
PRE_CI_FAILURE_LABEL="${PRE_CI_FAILURE_LABEL:-Unknown pre_ci gate}"
PRE_CI_REPRO_COMMAND="${PRE_CI_REPRO_COMMAND:-scripts/dev/pre_ci.sh}"
PRE_CI_DEBUG_DIR="${PRE_CI_DEBUG_DIR:-$ROOT/.toolchain/pre_ci_debug}"
PRE_CI_FAILURE_STATE_FILE="${PRE_CI_FAILURE_STATE_FILE:-$PRE_CI_DEBUG_DIR/failure_state.env}"

pre_ci_debug_init() {
  mkdir -p "$PRE_CI_DEBUG_DIR"
}

pre_ci_print_triage_banner() {
  cat <<'EOF'
==> Fail-first triage
Do not treat repeated local gate failures as blind rerun problems.
On failure, isolate the first failing layer, record remediation state, and use:
  - docs/process/debug-remediation-policy.md
  - docs/operations/REMEDIATION_TRACE_WORKFLOW.md
EOF
}

pre_ci_set_context() {
  PRE_CI_FAILURE_LAYER="$1"
  PRE_CI_FAILURE_SIGNATURE="$2"
  PRE_CI_FAILURE_GATE_ID="$3"
  PRE_CI_FAILURE_LABEL="$4"
  export PRE_CI_FAILURE_LAYER PRE_CI_FAILURE_SIGNATURE PRE_CI_FAILURE_GATE_ID PRE_CI_FAILURE_LABEL
}

pre_ci_scaffold_hint() {
  local slug
  slug="$(printf '%s' "$PRE_CI_FAILURE_GATE_ID" | tr '/.' '-' | tr -cd 'a-zA-Z0-9_-')"
  cat <<EOF
Suggested scaffolder:
  scripts/audit/new_remediation_casefile.sh --phase phase1 --slug ${slug} --failure-signature ${PRE_CI_FAILURE_SIGNATURE} --origin-gate-id ${PRE_CI_FAILURE_GATE_ID} --repro-command "${PRE_CI_REPRO_COMMAND}"
EOF
}

pre_ci_load_failure_state() {
  PRE_CI_LAST_SIGNATURE=""
  PRE_CI_LAST_LAYER=""
  PRE_CI_LAST_GATE_ID=""
  PRE_CI_LAST_COUNT=0
  if [[ -f "$PRE_CI_FAILURE_STATE_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$PRE_CI_FAILURE_STATE_FILE"
  fi
}

pre_ci_write_failure_state() {
  local count="$1"
  cat > "$PRE_CI_FAILURE_STATE_FILE" <<EOF
PRE_CI_LAST_SIGNATURE='${PRE_CI_FAILURE_SIGNATURE}'
PRE_CI_LAST_LAYER='${PRE_CI_FAILURE_LAYER}'
PRE_CI_LAST_GATE_ID='${PRE_CI_FAILURE_GATE_ID}'
PRE_CI_LAST_COUNT=${count}
EOF
}

pre_ci_record_failure() {
  local count
  pre_ci_load_failure_state
  if [[ "${PRE_CI_LAST_SIGNATURE:-}" == "$PRE_CI_FAILURE_SIGNATURE" ]]; then
    count=$(( ${PRE_CI_LAST_COUNT:-0} + 1 ))
  else
    count=1
  fi
  pre_ci_write_failure_state "$count"
  printf 'FAILURE_LAYER=%s\n' "$PRE_CI_FAILURE_LAYER"
  printf 'FAILURE_GATE_ID=%s\n' "$PRE_CI_FAILURE_GATE_ID"
  printf 'FAILURE_SIGNATURE=%s\n' "$PRE_CI_FAILURE_SIGNATURE"
  printf 'FAILURE_LABEL=%s\n' "$PRE_CI_FAILURE_LABEL"
  printf 'NONCONVERGENCE_COUNT=%s\n' "$count"
  printf 'FIRST_FAIL_GUIDANCE=Stop after the first failing layer and isolate root cause before rerun.\n'
  if (( count >= 2 )); then
    printf 'TWO_STRIKE_NONCONVERGENCE=1\n'
    printf 'ESCALATION=DRD_FULL_REQUIRED\n'
    pre_ci_scaffold_hint
  else
    printf 'TWO_STRIKE_NONCONVERGENCE=0\n'
  fi
}

pre_ci_clear_failure_state() {
  rm -f "$PRE_CI_FAILURE_STATE_FILE"
}


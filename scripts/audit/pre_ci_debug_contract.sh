#!/usr/bin/env bash
set -euo pipefail

# pre_ci_debug_contract.sh
#
# Shared debug/remediation helpers for scripts/dev/pre_ci.sh.
# Keeps first-fail triage, failure-layer taxonomy, and two-strike
# non-convergence escalation in one place so they can be tested directly.
#
# DRD LOCKOUT BEHAVIOUR:
# When NONCONVERGENCE_COUNT >= 2 on the same failure signature, this script
# writes a DRD lockout file. pre_ci.sh checks for this file at startup and
# refuses to run until a human clears it by:
#   1. Running: scripts/audit/new_remediation_casefile.sh ...
#   2. Documenting root cause in the generated PLAN.md
#   3. Running: rm .toolchain/pre_ci_debug/drd_lockout.env
#
# This converts DRD escalation from advisory output into a mechanical block.
# Exit code 99 is reserved exclusively for DRD lockout — no other gate uses it.

PRE_CI_FAILURE_LAYER="${PRE_CI_FAILURE_LAYER:-unclassified}"
PRE_CI_FAILURE_SIGNATURE="${PRE_CI_FAILURE_SIGNATURE:-PRECI.UNKNOWN}"
PRE_CI_FAILURE_GATE_ID="${PRE_CI_FAILURE_GATE_ID:-pre_ci.unknown}"
PRE_CI_FAILURE_LABEL="${PRE_CI_FAILURE_LABEL:-Unknown pre_ci gate}"
PRE_CI_REPRO_COMMAND="${PRE_CI_REPRO_COMMAND:-scripts/dev/pre_ci.sh}"
PRE_CI_DEBUG_DIR="${PRE_CI_DEBUG_DIR:-$ROOT/.toolchain/pre_ci_debug}"
PRE_CI_FAILURE_STATE_FILE="${PRE_CI_FAILURE_STATE_FILE:-$PRE_CI_DEBUG_DIR/failure_state.env}"
PRE_CI_DRD_LOCKOUT_FILE="${PRE_CI_DRD_LOCKOUT_FILE:-$PRE_CI_DEBUG_DIR/drd_lockout.env}"

pre_ci_debug_init() {
  mkdir -p "$PRE_CI_DEBUG_DIR"
}

# -- DRD lockout check --------------------------------------------------------
# Call this at the START of pre_ci.sh (before any gate runs).
# If a DRD lockout is active, pre_ci refuses to run and prints the exact
# commands needed to clear it. The agent cannot bypass this by retrying —
# it must create the remediation casefile and remove the lockout file first.
pre_ci_check_drd_lockout() {
  if [[ ! -f "$PRE_CI_DRD_LOCKOUT_FILE" ]]; then
    return 0
  fi

  # shellcheck disable=SC1090
  source "$PRE_CI_DRD_LOCKOUT_FILE"

  echo "? DRD LOCKOUT ACTIVE — pre_ci.sh is blocked." >&2
  echo "" >&2
  echo "  Failure signature : ${DRD_LOCKED_SIGNATURE:-unknown}" >&2
  echo "  Failure gate      : ${DRD_LOCKED_GATE_ID:-unknown}" >&2
  echo "  Nonconvergence    : ${DRD_LOCKED_COUNT:-?} consecutive failures" >&2
  echo "  Locked at         : ${DRD_LOCKED_AT:-unknown}" >&2
  echo "" >&2
  echo "  This is a mandatory DRD Full escalation." >&2
  echo "  Blind reruns are blocked until a remediation casefile exists." >&2
  echo "" >&2
  echo "  REQUIRED STEPS (in order):" >&2
  echo "  1. Create the remediation casefile:" >&2
  echo "     ${DRD_SCAFFOLD_CMD:-scripts/audit/new_remediation_casefile.sh ...}" >&2
  echo "  2. Document root cause in the generated PLAN.md" >&2
  echo "  3. Verify the casefile and clear the lockout:" >&2
  echo "     bash scripts/audit/verify_drd_casefile.sh --clear" >&2
  echo "  4. Re-run pre_ci.sh" >&2
  echo "" >&2

  # Registry lookup — if failure_signatures.yml exists, print the playbook link
  local registry="${ROOT:-$(pwd)}/docs/operations/failure_signatures.yml"
  local sig="${DRD_LOCKED_SIGNATURE:-}"
  if [[ -n "$sig" && -f "$registry" ]]; then
    local playbook
    playbook="$(python3 - <<PY 2>/dev/null || true
import sys
registry = open("$registry", encoding="utf-8").read()
sig = "$sig"
in_sig = False
for line in registry.splitlines():
    if line.startswith(sig + ":"):
        in_sig = True
        continue
    if in_sig:
        if line and not line.startswith(" "):
            break
        if "remediation_playbook:" in line:
            print(line.split("remediation_playbook:", 1)[1].strip())
            break
PY
)"
    if [[ -n "$playbook" ]]; then
      echo "  Remediation playbook: $playbook" >&2
    fi
  fi

  # Failure index reference
  local index="${ROOT:-$(pwd)}/docs/operations/failure_index.md"
  if [[ -f "$index" ]]; then
    echo "  Prior incidents: docs/operations/failure_index.md (search: ${sig})" >&2
  fi

  echo "" >&2
  echo "  See: .agent/policies/debug-remediation-policy.md" >&2
  exit 99
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
  echo "scripts/audit/new_remediation_casefile.sh --phase phase1 --slug ${slug} --failure-signature ${PRE_CI_FAILURE_SIGNATURE} --origin-gate-id ${PRE_CI_FAILURE_GATE_ID} --repro-command \"${PRE_CI_REPRO_COMMAND}\""
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

pre_ci_write_drd_lockout() {
  local count="$1"
  local scaffold_cmd
  scaffold_cmd="$(pre_ci_scaffold_hint)"
  cat > "$PRE_CI_DRD_LOCKOUT_FILE" <<EOF
DRD_LOCKED_SIGNATURE='${PRE_CI_FAILURE_SIGNATURE}'
DRD_LOCKED_LAYER='${PRE_CI_FAILURE_LAYER}'
DRD_LOCKED_GATE_ID='${PRE_CI_FAILURE_GATE_ID}'
DRD_LOCKED_COUNT=${count}
DRD_LOCKED_AT='$(date -u +%Y-%m-%dT%H:%M:%SZ)'
DRD_SCAFFOLD_CMD='${scaffold_cmd}'
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

    local scaffold_cmd
    scaffold_cmd="$(pre_ci_scaffold_hint)"
    printf 'Suggested scaffolder:\n  %s\n' "$scaffold_cmd"

    # Write the DRD lockout file — this is the mechanical block.
    # pre_ci.sh will refuse to run on the next invocation until cleared.
    pre_ci_write_drd_lockout "$count"

    printf '\n'
    printf '? DRD LOCKOUT WRITTEN: %s\n' "$PRE_CI_DRD_LOCKOUT_FILE"
    printf '   pre_ci.sh is now BLOCKED for this failure signature.\n'
    printf '   Create the remediation casefile, then remove the lockout file.\n'
    printf '   See: .agent/policies/debug-remediation-policy.md\n'
  else
    printf 'TWO_STRIKE_NONCONVERGENCE=0\n'
  fi
}

pre_ci_clear_failure_state() {
  rm -f "$PRE_CI_FAILURE_STATE_FILE"
  # Note: drd_lockout.env is NOT cleared here.
  # It is only cleared manually after a remediation casefile is created.
  # This is intentional — success on an unrelated gate must not lift a DRD lockout.
}

#!/usr/bin/env bash
set -euo pipefail

# pre_ci_debug_contract.sh — STAGING SNAPSHOT (Layer 3 + registry lookup)
# TARGET: scripts/audit/pre_ci_debug_contract.sh
# STATUS: This snapshot is the live version already written to repo,
#         PLUS an enhancement to pre_ci_check_drd_lockout() that looks up
#         the failure signature in docs/operations/failure_signatures.yml
#         and prints the remediation playbook link.
#
# TO APPLY THE REGISTRY LOOKUP ENHANCEMENT:
#   Replace pre_ci_check_drd_lockout() in the live file with the version below.
#   Everything else in the live file remains unchanged.

# ΓöÇΓöÇ ENHANCED pre_ci_check_drd_lockout() ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
# Replace the existing function body with this version.
# The addition is the "Registry lookup" block after the REQUIRED STEPS section.

pre_ci_check_drd_lockout() {
  if [[ ! -f "$PRE_CI_DRD_LOCKOUT_FILE" ]]; then
    return 0
  fi

  # shellcheck disable=SC1090
  source "$PRE_CI_DRD_LOCKOUT_FILE"

  echo "❌ DRD LOCKOUT ACTIVE — pre_ci.sh is blocked." >&2
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
  echo "  3. Remove the lockout file:" >&2
  echo "     rm $PRE_CI_DRD_LOCKOUT_FILE" >&2
  echo "  4. Re-run pre_ci.sh" >&2
  echo "" >&2

  # ΓöÇΓöÇ Registry lookup (new addition) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  # If failure_signatures.yml exists, look up this signature and print the
  # playbook link. This converts the lockout from a hard stop into a
  # guided hard stop — agents and humans know exactly where to look.
  # Uses yaml.safe_load — not line scanning — so valid YAML formatting,
  # multiline descriptions, and field reordering never break the lookup.
  local registry="${ROOT:-$(pwd)}/docs/operations/failure_signatures.yml"
  local sig="${DRD_LOCKED_SIGNATURE:-}"
  if [[ -n "$sig" && -f "$registry" ]]; then
    local playbook
    playbook="$(python3 - "$registry" "$sig" <<'PY'
import sys, yaml
registry_path, sig = sys.argv[1], sys.argv[2]
try:
    data = yaml.safe_load(open(registry_path, encoding="utf-8")) or {}
    entry = data.get(sig) or {}
    print(entry.get("remediation_playbook", ""))
except Exception:
    print("")
PY
)"
    if [[ -n "$playbook" ]]; then
      echo "  Remediation playbook for ${sig}:" >&2
      echo "    ${playbook}" >&2
      echo "" >&2
    fi
  fi

  # ΓöÇΓöÇ Failure index reference ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  local index="${ROOT:-$(pwd)}/docs/operations/failure_index.md"
  if [[ -f "$index" ]]; then
    echo "  Prior incidents for this signature:" >&2
    echo "    docs/operations/failure_index.md (search: ${sig})" >&2
    echo "" >&2
  fi

  echo "  See: .agent/policies/debug-remediation-policy.md" >&2
  exit 99
}

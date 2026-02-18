#!/usr/bin/env bash
set -euo pipefail

parity_critical_scripts() {
  cat <<'EOF'
scripts/audit/enforce_change_rule.sh
scripts/audit/verify_baseline_change_governance.sh
scripts/audit/verify_remediation_trace.sh
scripts/audit/verify_invariants_local.sh
EOF
}

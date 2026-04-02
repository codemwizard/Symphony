# LAYER 3: DRD Mechanical Lockout
# STATUS: Already written to repo. These are canonical snapshots.
#
# Files modified in repo:
#   scripts/audit/pre_ci_debug_contract.sh  -- added pre_ci_write_drd_lockout(), pre_ci_check_drd_lockout()
#   scripts/dev/pre_ci.sh                   -- added pre_ci_check_drd_lockout() call at startup
#   scripts/agent/run_task.sh               -- added rejection context with DRD state
#   AGENT_ENTRYPOINT.md                     -- added Pre-Step with DRD lockout awareness
#
# How it works:
#   1. pre_ci_record_failure() in pre_ci_debug_contract.sh counts failures per signature
#   2. When count >= 2: writes .toolchain/pre_ci_debug/drd_lockout.env
#   3. pre_ci.sh calls pre_ci_check_drd_lockout() before any gate runs
#   4. If lockout file exists: exits with code 99 and prints scaffold command
#   5. run_task.sh reads lockout state and includes it in rejection_context.md
#   6. AGENT_ENTRYPOINT.md tells agents to check DRD_STATUS before any action
#
# To clear a lockout (after creating remediation casefile):
#   rm .toolchain/pre_ci_debug/drd_lockout.env
#
# Exit code 99 is reserved for DRD lockout. No other gate uses it.
# This makes DRD lockout distinguishable from normal failures (exit 1).

#!/usr/bin/env bash
# =============================================================================
# strip_bypass_env_vars.sh
# Symphony -- Bypass Environment Variable Enforcement
#
# Closes the env-var bypass attack:
#   An agent sets SKIP_CI_DB_PARITY_PROBE=1 before calling pre_ci.sh.
#   pre_ci.sh previously honoured the flag and skipped the real DB checks.
#
# This script MUST be sourced (not executed) near the TOP of pre_ci.sh,
# immediately after pre_ci_check_drd_lockout and before any gate runs.
#
#   source scripts/audit/strip_bypass_env_vars.sh
#
# What it does
# ------------
# 1. Captures and validates known bypass variables BEFORE unsetting them.
# 2. Logs any that were set (with values) to .toolchain/audit/bypass_attempt.log.
# 3. Hard-fails (return 1 / exit 1) if a hard-bypass variable was present,
#    UNLESS SYMPHONY_HUMAN_DEBUG_SESSION=1 is explicitly set by a human.
# 4. Unsets all bypass variables and re-exports safe defaults.
#
# IMPORTANT: this script cannot protect itself if the agent has write access
# to scripts/audit/. Apply UBUNTU_ACCESS_HARDENING.md first.
#
# EXIT CODES (when sourced):
#   returns 0  -- environment was clean or only soft-bypass vars were present
#   returns 1  -- hard-bypass variable was present and session is not whitelisted
# =============================================================================

# ---------------------------------------------------------------------------
# Hard bypass variables: presence of any of these at a non-zero/non-empty
# value triggers a hard fail and blocks the run.
# ---------------------------------------------------------------------------
_HARD_BYPASS_VARS=(
  SKIP_CI_DB_PARITY_PROBE
  SKIP_VALIDATION
  SKIP_GATES
  CI_BYPASS
  DEBUG_OVERRIDE
  FORCE_PASS
)

# ---------------------------------------------------------------------------
# Soft bypass variables: logged and reset to safe defaults but do not
# trigger a hard fail on their own.
# ---------------------------------------------------------------------------
_SOFT_BYPASS_VARS=(
  SKIP_POLICY_SEED
  KEEP_TEMP_DB
  CLEAN_EVIDENCE
  PII_LINT_ROOTS
)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
_log_bypass() {
  local var="$1" val="$2"
  local log_dir=".toolchain/audit"
  mkdir -p "$log_dir"
  printf '%s bypass_env_var_detected var=%s val=%.80s pid=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$var" "$val" "$$" \
    >> "$log_dir/bypass_attempt.log"
}

# ---------------------------------------------------------------------------
# Step 1: Validate and capture BEFORE unsetting
# (RUN_DEMO_GATES needs range check before it is lost to unset)
# ---------------------------------------------------------------------------
_found_hard_bypass=0
_found_soft_bypass=0

# RUN_DEMO_GATES: must be exactly "0" or "1" — anything else is treated as
# a hard bypass attempt (an agent injecting an arbitrary truthy value).
_rdg_val="${RUN_DEMO_GATES:-0}"
if [[ "$_rdg_val" != "0" && "$_rdg_val" != "1" ]]; then
  echo "SECURITY: RUN_DEMO_GATES='${_rdg_val}' is not a valid value (must be 0 or 1)" >&2
  _log_bypass "RUN_DEMO_GATES" "$_rdg_val"
  _found_hard_bypass=1
fi
# Reset regardless — we will re-export the validated value below.
unset RUN_DEMO_GATES

# Check hard bypass vars
for _var in "${_HARD_BYPASS_VARS[@]}"; do
  _val="${!_var:-}"
  if [[ -n "$_val" && "$_val" != "0" ]]; then
    echo "SECURITY: bypass variable ${_var}='${_val}' detected — UNSETTING" >&2
    _log_bypass "$_var" "$_val"
    _found_hard_bypass=1
  fi
  unset "$_var"
done

# Check soft bypass vars
for _var in "${_SOFT_BYPASS_VARS[@]}"; do
  _val="${!_var:-}"
  if [[ -n "$_val" && "$_val" != "0" && "$_val" != "1" ]]; then
    echo "WARN: soft bypass variable ${_var}='${_val}' detected — resetting to safe default" >&2
    _log_bypass "$_var" "$_val"
    _found_soft_bypass=1
  fi
  unset "$_var"
done

# ---------------------------------------------------------------------------
# Step 2: Re-export safe defaults unconditionally
# These are the ONLY values pre_ci.sh should operate with.
# ---------------------------------------------------------------------------
export SKIP_CI_DB_PARITY_PROBE=0
export SKIP_VALIDATION=0
export SKIP_GATES=0
export CI_BYPASS=0
export DEBUG_OVERRIDE=0
export FORCE_PASS=0
export SKIP_POLICY_SEED=0
export KEEP_TEMP_DB=0
export CLEAN_EVIDENCE=1
export PII_LINT_ROOTS=""
# Restore RUN_DEMO_GATES to the validated value (0 if it was invalid).
export RUN_DEMO_GATES="${_rdg_val:-0}"
if [[ "$_rdg_val" != "0" && "$_rdg_val" != "1" ]]; then
  export RUN_DEMO_GATES=0
fi

# ---------------------------------------------------------------------------
# Step 3: Decision — fail hard or continue
# ---------------------------------------------------------------------------
if [[ "$_found_hard_bypass" -ne 0 ]]; then
  if [[ "${SYMPHONY_HUMAN_DEBUG_SESSION:-0}" == "1" ]]; then
    echo "WARN: Hard bypass variables were present." >&2
    echo "  SYMPHONY_HUMAN_DEBUG_SESSION=1 is set — continuing with safe defaults." >&2
    echo "  All bypass variables have been unset. This session is logged." >&2
  else
    echo "" >&2
    echo "FATAL: Bypass environment variables were detected in the agent environment." >&2
    echo "  This is a known rogue-agent exploit vector." >&2
    echo "  All bypass variables have been unset. This run is BLOCKED." >&2
    echo "" >&2
    echo "  If you are a human developer who legitimately needs a bypass:" >&2
    echo "    export SYMPHONY_HUMAN_DEBUG_SESSION=1" >&2
    echo "  This still logs, unsets, and restores defaults; it only prevents the hard fail." >&2
    echo "  See .toolchain/audit/bypass_attempt.log for details." >&2
    echo "" >&2
    # return if sourced; exit if run directly
    unset _found_hard_bypass _found_soft_bypass _var _val _rdg_val
    unset _HARD_BYPASS_VARS _SOFT_BYPASS_VARS
    exit 1
  fi
fi

# Soft bypass: log-only, do not fail
if [[ "$_found_soft_bypass" -ne 0 ]]; then
  echo "WARN: Soft bypass variables were present and reset to safe defaults." >&2
fi

# Clean up all local variables so they do not pollute the sourcing shell.
unset _found_hard_bypass _found_soft_bypass _var _val _rdg_val
unset _HARD_BYPASS_VARS _SOFT_BYPASS_VARS

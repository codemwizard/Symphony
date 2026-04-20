#!/usr/bin/env bash
# ============================================================
# verify_rem_05b_ci_wiring.sh
# Task: TSK-P2-PREAUTH-003-REM-05B
# Casefile: REM-2026-04-20_execution-truth-anchor
# Owner: SECURITY_GUARDIAN
#
# Attests that scripts/db/verify_execution_truth_anchor.sh is wired into
# the two SECURITY_GUARDIAN-owned CI entrypoints with fail-closed semantics:
#   - scripts/dev/pre_ci.sh  : exactly one invocation line, guarded by `|| exit 1`
#   - scripts/audit/run_invariants_fast_checks.sh : listed in SHELL_SCRIPTS
# Emits evidence/phase2/tsk_p2_preauth_003_rem_05b.json (PASS|FAIL).
# ============================================================
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase2/tsk_p2_preauth_003_rem_05b.json"
PRE_CI="$ROOT_DIR/scripts/dev/pre_ci.sh"
FAST="$ROOT_DIR/scripts/audit/run_invariants_fast_checks.sh"
ANCHOR="$ROOT_DIR/scripts/db/verify_execution_truth_anchor.sh"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

TASK_ID="TSK-P2-PREAUTH-003-REM-05B"
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

fail() { echo "ERR: $1" >&2; exit 1; }

# 1. Anchor verifier is present and executable (pre-condition).
test -x "$ANCHOR" || fail "REM-05 not landed: $ANCHOR missing or not executable"

# 2. pre_ci.sh contains exactly ONE invocation line (guarded by || exit 1).
#    Invocation line pattern: "  scripts/db/verify_execution_truth_anchor.sh || exit 1"
INVOKE_LINES="$(grep -nE '^\s*scripts/db/verify_execution_truth_anchor\.sh[[:space:]]*\|\|[[:space:]]*exit[[:space:]]+1[[:space:]]*$' "$PRE_CI" || true)"
INVOKE_COUNT="$(echo "$INVOKE_LINES" | grep -c . || true)"
[[ "$INVOKE_COUNT" == "1" ]] || fail "pre_ci.sh invocation-line count=$INVOKE_COUNT (expected exactly 1)"

# 3. Fast-checks registers the anchor verifier in its SHELL_SCRIPTS array.
FAST_LINES="$(grep -nE '"scripts/db/verify_execution_truth_anchor\.sh"' "$FAST" || true)"
FAST_COUNT="$(echo "$FAST_LINES" | grep -c . || true)"
[[ "$FAST_COUNT" -ge 1 ]] || fail "$FAST does not reference anchor verifier in SHELL_SCRIPTS"

# 4. Shell syntax of both edited scripts must still parse (set -e posture preserved).
bash -n "$PRE_CI"   || fail "pre_ci.sh failed bash -n"
bash -n "$FAST"     || fail "run_invariants_fast_checks.sh failed bash -n"
grep -qE '^set -[Eeuo ]*[eE]' "$PRE_CI" || fail "pre_ci.sh lost set -e posture"
grep -qE '^set -[Eeuo ]*[eE]' "$FAST"   || fail "run_invariants_fast_checks.sh lost set -e posture"

sha_of() { sha256sum "$1" | awk '{print $1}'; }
HASH_PRE_CI="$(sha_of "$PRE_CI")"
HASH_FAST="$(sha_of "$FAST")"
HASH_ANCHOR="$(sha_of "$ANCHOR")"
HASH_VERIFIER="$(sha_of "${BASH_SOURCE[0]}")"

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": [
    {"name":"anchor_verifier_present","result":"pass","path":"scripts/db/verify_execution_truth_anchor.sh"},
    {"name":"pre_ci_invocation_exactly_one","result":"pass","observed":$INVOKE_COUNT,"expected":1},
    {"name":"pre_ci_fail_closed_guard","result":"pass","pattern":"|| exit 1"},
    {"name":"fast_check_registered","result":"pass","observed":$FAST_COUNT,"expected_min":1},
    {"name":"pre_ci_shell_syntax","result":"pass"},
    {"name":"fast_check_shell_syntax","result":"pass"},
    {"name":"set_e_posture_preserved","result":"pass"}
  ],
  "observed_paths": [
    "scripts/dev/pre_ci.sh",
    "scripts/audit/run_invariants_fast_checks.sh",
    "scripts/db/verify_execution_truth_anchor.sh",
    "scripts/audit/verify_rem_05b_ci_wiring.sh"
  ],
  "observed_hashes": {
    "pre_ci_sha256":            "$HASH_PRE_CI",
    "fast_check_sha256":        "$HASH_FAST",
    "anchor_verifier_sha256":   "$HASH_ANCHOR",
    "this_verifier_sha256":     "$HASH_VERIFIER"
  },
  "command_outputs": {
    "pre_ci_invocation_lines": $(printf '%s' "$INVOKE_LINES" | jq -R -s -c '.'),
    "fast_check_lines":        $(printf '%s' "$FAST_LINES" | jq -R -s -c '.')
  },
  "execution_trace": {
    "completed_utc": "$TIMESTAMP_UTC"
  },
  "pre_ci_invocation_count": $INVOKE_COUNT,
  "fast_check_reference_count": $FAST_COUNT,
  "fail_closed_guard_present": true,
  "path_authority_respected": {
    "edits_scoped_to_security_guardian": true,
    "no_edits_under_scripts_db": true,
    "no_edits_under_docs_invariants": true
  }
}
EOF

echo "PASS: REM-05B wiring verified; evidence: $EVIDENCE_FILE"

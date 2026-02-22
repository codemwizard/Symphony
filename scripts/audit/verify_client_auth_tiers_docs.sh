#!/usr/bin/env bash
set -euo pipefail

# verify_client_auth_tiers_docs.sh
# Verifies client auth tier policy docs exist and are internally consistent.
# Emits deterministic evidence JSON for CI gating.
#
# Expected docs:
#   - docs/security/CLIENT_AUTH_TIERS.md
#   - docs/security/CLIENT_AUTH_TIER_MATRIX.md
#   - docs/security/AUTH_IDENTITY_BOUNDARY.md (optional to check here; enabled below)
#
# Evidence:
#   - evidence/phase1/client_auth_tiers_docs.json
#
# Exit codes:
#   0 = pass
#   1 = verification failure
#   2 = prereq/tooling failure

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC_TIERS="${ROOT_DIR}/docs/security/CLIENT_AUTH_TIERS.md"
DOC_MATRIX="${ROOT_DIR}/docs/security/CLIENT_AUTH_TIER_MATRIX.md"
DOC_BOUNDARY="${ROOT_DIR}/docs/security/AUTH_IDENTITY_BOUNDARY.md"
EVIDENCE_DIR="${ROOT_DIR}/evidence/phase1"
EVIDENCE_FILE="${EVIDENCE_DIR}/client_auth_tiers_docs.json"

PASS=true
ERRORS=()

require_file() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    PASS=false
    ERRORS+=("MISSING_FILE:${f}")
  fi
}

require_nonempty_file() {
  local f="$1"
  if [[ -f "$f" && ! -s "$f" ]]; then
    PASS=false
    ERRORS+=("EMPTY_FILE:${f}")
  fi
}

contains_literal() {
  local f="$1"
  local s="$2"
  grep -Fq "$s" "$f"
}

canonical_tier_order_ok() {
  local f="$1"
  # Require exact mappings somewhere in the doc.
  contains_literal "$f" "Tier 1" \
    && contains_literal "$f" "mTLS" \
    && contains_literal "$f" "Tier 2" \
    && contains_literal "$f" "signed JWT" \
    && contains_literal "$f" "Tier 3" \
    && contains_literal "$f" "API key + trusted headers"
}

matrix_has_required_columns() {
  local f="$1"
  # Basic sanity: look for the markdown header row with required names
  grep -Fq "participant_code" "$f" \
    && grep -Fq "assigned_tier" "$f" \
    && grep -Fq "justification" "$f" \
    && grep -Fq "target_tier" "$f" \
    && grep -Fq "review_date" "$f" \
    && grep -Fq "approved_by" "$f"
}

invalid_tier_tokens_present() {
  local f="$1"
  # Fail if obvious wrong ordering labels appear in canonical docs.
  # Add more as needed.
  grep -Eq 'Tier[[:space:]]*1.*API key|Tier[[:space:]]*3.*mTLS' "$f"
}

git_sha() {
  if command -v git >/dev/null 2>&1 && git -C "$ROOT_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
    git -C "$ROOT_DIR" rev-parse --short HEAD
  else
    echo "UNKNOWN"
  fi
}

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

json_escape() {
  # Minimal JSON string escape
  sed 's/\\/\\\\/g; s/"/\\"/g'
}

mkdir -p "$EVIDENCE_DIR"

# ---- Checks ----
require_file "$DOC_TIERS"
require_file "$DOC_MATRIX"
require_file "$DOC_BOUNDARY"

require_nonempty_file "$DOC_TIERS"
require_nonempty_file "$DOC_MATRIX"
require_nonempty_file "$DOC_BOUNDARY"

tiers_doc_exists=false
matrix_doc_exists=false
boundary_doc_exists=false
tiers_order_correct=false
matrix_columns_ok=false
invalid_tier_ordering_detected=false

if [[ -f "$DOC_TIERS" ]]; then
  tiers_doc_exists=true
  if canonical_tier_order_ok "$DOC_TIERS"; then
    tiers_order_correct=true
  else
    PASS=false
    ERRORS+=("TIER_ORDER_INVALID:${DOC_TIERS} (expected Tier1=mTLS, Tier2=signed JWT, Tier3=API key + trusted headers)")
  fi

  if invalid_tier_tokens_present "$DOC_TIERS"; then
    invalid_tier_ordering_detected=true
    PASS=false
    ERRORS+=("TIER_ORDER_CONTRADICTION_DETECTED:${DOC_TIERS}")
  fi
fi

if [[ -f "$DOC_MATRIX" ]]; then
  matrix_doc_exists=true
  if matrix_has_required_columns "$DOC_MATRIX"; then
    matrix_columns_ok=true
  else
    PASS=false
    ERRORS+=("MATRIX_COLUMNS_MISSING:${DOC_MATRIX}")
  fi
fi

if [[ -f "$DOC_BOUNDARY" ]]; then
  boundary_doc_exists=true
  # Boundary doc existence is the hard requirement here; deeper semantic checks can be added later.
fi

# ---- Emit evidence ----
{
  echo "{"
  echo "  \"check_id\": \"SEC-AUTH-TIERS-DOCS-001\","
  echo "  \"git_sha\": \"$(git_sha)\","
  echo "  \"timestamp_utc\": \"$(timestamp_utc)\","
  echo "  \"pass\": ${PASS},"
  echo "  \"docs\": {"
  echo "    \"client_auth_tiers\": {\"path\": \"docs/security/CLIENT_AUTH_TIERS.md\", \"exists\": ${tiers_doc_exists}},"
  echo "    \"client_auth_tier_matrix\": {\"path\": \"docs/security/CLIENT_AUTH_TIER_MATRIX.md\", \"exists\": ${matrix_doc_exists}},"
  echo "    \"auth_identity_boundary\": {\"path\": \"docs/security/AUTH_IDENTITY_BOUNDARY.md\", \"exists\": ${boundary_doc_exists}}"
  echo "  },"
  echo "  \"assertions\": {"
  echo "    \"tier_order_correct\": ${tiers_order_correct},"
  echo "    \"matrix_has_required_columns\": ${matrix_columns_ok},"
  echo "    \"invalid_tier_ordering_detected\": ${invalid_tier_ordering_detected}"
  echo "  },"
  echo "  \"measurement_truth\": \"documentation_governance_check_only\","
  echo "  \"errors\": ["
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    for i in "${!ERRORS[@]}"; do
      err="$(printf "%s" "${ERRORS[$i]}" | json_escape)"
      if [[ "$i" -lt $((${#ERRORS[@]} - 1)) ]]; then
        echo "    \"${err}\","
      else
        echo "    \"${err}\""
      fi
    done
  fi
  echo "  ]"
  echo "}"
} > "$EVIDENCE_FILE"

if [[ "$PASS" == "true" ]]; then
  echo "PASS: client auth tier docs verified"
  echo "Evidence: $EVIDENCE_FILE"
  exit 0
else
  echo "FAIL: client auth tier docs verification failed" >&2
  echo "Evidence: $EVIDENCE_FILE" >&2
  exit 1
fi
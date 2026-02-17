#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT_DIR/docs/security/AUDIT_LOGGING_RETENTION_POLICY.md"
MANIFEST="$ROOT_DIR/docs/security/SECURITY_MANIFEST.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/audit_logging_retention_policy.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

status="PASS"
errors=()

if [[ ! -f "$DOC" ]]; then
  status="FAIL"
  errors+=("missing_policy_doc:docs/security/AUDIT_LOGGING_RETENTION_POLICY.md")
else
  # Minimal content assertions to prevent empty policy stubs from passing.
  if ! rg -n "^## Retention Targets" "$DOC" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("missing_section:Retention Targets")
  fi
  if ! rg -n "^## Review Cadence" "$DOC" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("missing_section:Review Cadence")
  fi
  if ! rg -n "^## Time Synchronization" "$DOC" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("missing_section:Time Synchronization")
  fi
fi

if [[ ! -f "$MANIFEST" ]]; then
  status="FAIL"
  errors+=("missing_security_manifest:docs/security/SECURITY_MANIFEST.yml")
else
  if ! rg -n "AUDIT_LOGGING_RETENTION_POLICY\\.md" "$MANIFEST" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("policy_not_referenced_in_security_manifest")
  fi
fi

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-AUDIT-RETENTION-POLICY\"" \
  "\"timestamp_utc\": \"${ts}\"" \
  "\"git_sha\": \"${sha}\"" \
  "\"schema_fingerprint\": \"${fp}\"" \
  "\"status\": \"${status}\"" \
  "\"errors\": $(python3 - <<'PY'
import json,sys
print(json.dumps(sys.argv[1:]))
PY
${errors[@]})"

if [[ "$status" != "PASS" ]]; then
  echo "❌ Audit logging retention policy verification failed. Evidence: $EVIDENCE_FILE" >&2
  printf ' - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "Audit logging retention policy verification OK. Evidence: $EVIDENCE_FILE"


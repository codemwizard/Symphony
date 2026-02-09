#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT_DIR/docs/security/KEY_MANAGEMENT_POLICY.md"
MANIFEST="$ROOT_DIR/docs/security/SECURITY_MANIFEST.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/policy_key_management_stub.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

status="PASS"
errors=()

if [[ ! -f "$DOC" ]]; then
  status="FAIL"
  errors+=("missing_doc:docs/security/KEY_MANAGEMENT_POLICY.md")
else
  if ! rg -n "^## (Scope|Principles)" "$DOC" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("missing_section:Scope_or_Principles")
  fi
fi

if [[ ! -f "$MANIFEST" ]]; then
  status="FAIL"
  errors+=("missing_security_manifest:docs/security/SECURITY_MANIFEST.yml")
else
  if ! rg -n "KEY_MANAGEMENT_POLICY\\.md" "$MANIFEST" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("doc_not_referenced_in_security_manifest")
  fi
fi

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"GOV-POLICY-KEY-MGMT\"" \
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
  echo "❌ Key management policy stub verification failed. Evidence: $EVIDENCE_FILE" >&2
  printf ' - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "Key management policy stub verification OK. Evidence: $EVIDENCE_FILE"


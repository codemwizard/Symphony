#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT_DIR/docs/security/SECURE_SDLC_POLICY.md"
MANIFEST="$ROOT_DIR/docs/security/SECURITY_MANIFEST.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/sdlc_sast_readiness.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

status="PASS"
errors=()

if [[ ! -f "$DOC" ]]; then
  status="FAIL"
  errors+=("missing_doc:docs/security/SECURE_SDLC_POLICY.md")
else
  if ! rg -n "^## (Static Analysis|SAST|Tooling)" "$DOC" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("missing_section:Static Analysis/SAST/Tooling")
  fi
fi

if [[ ! -f "$MANIFEST" ]]; then
  status="FAIL"
  errors+=("missing_security_manifest:docs/security/SECURITY_MANIFEST.yml")
else
  if ! rg -n "SECURE_SDLC_POLICY\\.md" "$MANIFEST" >/dev/null 2>&1; then
    status="FAIL"
    errors+=("doc_not_referenced_in_security_manifest")
  fi
fi

# Tooling readiness: semgrep runner must exist (tooling installation is handled by toolchain bootstrap).
if [[ ! -x "$ROOT_DIR/scripts/security/run_semgrep_sast.sh" ]]; then
  status="FAIL"
  errors+=("missing_semgrep_runner:scripts/security/run_semgrep_sast.sh")
fi

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-SDLC-SAST-READINESS\"" \
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
  echo "❌ SDLC/SAST readiness verification failed. Evidence: $EVIDENCE_FILE" >&2
  printf ' - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "SDLC/SAST readiness verification OK. Evidence: $EVIDENCE_FILE"


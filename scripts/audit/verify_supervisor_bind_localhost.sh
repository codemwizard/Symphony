#!/usr/bin/env bash
set -euo pipefail

# R-000 Regression Gate: Verify supervisor_api binds to localhost only.
# Checks launchSettings.json and any ASPNETCORE_URLS / --urls overrides.
# Produces evidence at evidence/security_remediation/r_000_containment.json (partial).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib/evidence.sh"

EVIDENCE_DIR="$ROOT_DIR/evidence/security_remediation"
EVIDENCE_FILE="$EVIDENCE_DIR/r_000_containment.json"
mkdir -p "$EVIDENCE_DIR"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

status="PASS"
errors=()
bind_address="localhost"
external_reachable="false"

LAUNCH_SETTINGS="$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Properties/launchSettings.json"

# --- Check 1: launchSettings.json must only reference localhost / 127.0.0.1 ---
if [[ -f "$LAUNCH_SETTINGS" ]]; then
  # Extract all applicationUrl values
  urls="$(python3 -c "
import json,sys
with open(sys.argv[1]) as f: d=json.load(f)
for p in d.get('profiles', {}).values():
    u = p.get('applicationUrl', '')
    if u: print(u)
" "$LAUNCH_SETTINGS")"

  while IFS= read -r url_line; do
    # Split on semicolons (multiple URLs per profile)
    IFS=';' read -ra parts <<< "$url_line"
    for part in "${parts[@]}"; do
      part="$(echo "$part" | xargs)"  # trim
      [[ -z "$part" ]] && continue
      # Extract host portion
      host="$(python3 -c "from urllib.parse import urlparse; print(urlparse('$part').hostname or '')")"
      case "$host" in
        localhost|127.0.0.1|"") ;;
        *)
          status="FAIL"
          external_reachable="true"
          bind_address="$host"
          errors+=("launchSettings binds to external host: $host ($part)")
          ;;
      esac
    done
  done <<< "$urls"
else
  # No launchSettings = ASP.NET defaults to localhost; that's fine.
  :
fi

# --- Check 2: Scan for 0.0.0.0 bind overrides in source/config ---
if grep -rInE '(ASPNETCORE_URLS|--urls).*0\.0\.0\.0' \
    --include '*.cs' --include '*.json' --include '*.yml' --include '*.yaml' \
    --include '*.env' --include 'Dockerfile*' --include 'docker-compose*' \
    "$ROOT_DIR/services/ledger-api" "$ROOT_DIR/docker" 2>/dev/null; then
  status="FAIL"
  external_reachable="true"
  bind_address="0.0.0.0"
  errors+=("Found 0.0.0.0 bind override in source or config")
fi

# --- Check 3: x-admin-claim bypass must NOT exist ---
admin_bypass="false"
if grep -rInE 'x-admin-claim' \
    --include '*.cs' \
    "$ROOT_DIR/services/ledger-api" 2>/dev/null; then
  status="FAIL"
  admin_bypass="true"
  errors+=("x-admin-claim header trust pattern still present in source")
fi

# --- Check 4: ADMIN_API_KEY fail-closed: verify 503 pattern exists ---
admin_auth_required="false"
# These appear on adjacent lines in the source, so check each independently.
if grep -qE 'AUTHZ_CONFIG_MISSING' \
    "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs" 2>/dev/null \
  && grep -qE 'ADMIN_API_KEY must be configured' \
    "$ROOT_DIR/services/ledger-api/dotnet/src/LedgerApi/Program.cs" 2>/dev/null; then
  admin_auth_required="true"
else
  status="FAIL"
  errors+=("ADMIN_API_KEY fail-closed 503 pattern not found in Program.cs")
fi

errors_json="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "${errors[@]+"${errors[@]}"}")"

write_json "$EVIDENCE_FILE" \
  "\"task_id\": \"R-000\"" \
  "\"check_id\": \"R-000-BIND-LOCALHOST\"" \
  "\"timestamp_utc\": \"${ts}\"" \
  "\"git_sha\": \"${sha}\"" \
  "\"schema_fingerprint\": \"${fp}\"" \
  "\"status\": \"${status}\"" \
  "\"bind_address\": \"${bind_address}\"" \
  "\"external_reachability\": ${external_reachable}" \
  "\"admin_bypass_present\": ${admin_bypass}" \
  "\"admin_auth_required\": ${admin_auth_required}" \
  "\"errors\": ${errors_json}"

if [[ "$status" != "PASS" ]]; then
  echo "❌ R-000 containment check FAILED." >&2
  for e in "${errors[@]}"; do echo "  - $e" >&2; done
  echo "Evidence: $EVIDENCE_FILE" >&2
  exit 1
fi

echo "✅ R-000 containment check PASSED. Evidence: $EVIDENCE_FILE"

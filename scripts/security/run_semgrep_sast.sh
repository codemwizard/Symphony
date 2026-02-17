#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES="$ROOT_DIR/security/semgrep/rules.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/semgrep_sast.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
# Load pinned semgrep version when available (CI enforces exact match).
if [[ -f "$ROOT_DIR/scripts/audit/ci_toolchain_versions.env" ]]; then
  # shellcheck disable=SC1090
  source "$ROOT_DIR/scripts/audit/ci_toolchain_versions.env"
fi
EXPECTED_SEMGREP_VERSION="${SEMGREP_VERSION:-}"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

status="PASS"
errors=()
semgrep_version="UNKNOWN"
scanned=()
findings="[]"

if [[ ! -f "$RULES" ]]; then
  status="FAIL"
  errors+=("missing_ruleset:security/semgrep/rules.yml")
else
  if ! command -v semgrep >/dev/null 2>&1; then
    # Tier-1 / CI parity: CI must not silently degrade SAST to SKIPPED.
    if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
      status="FAIL"
      errors+=("semgrep_not_installed")
    else
      status="SKIPPED"
      errors+=("semgrep_not_installed")
    fi
  else
    semgrep_version="$(semgrep --version | tr -d '\n' || echo "UNKNOWN")"
    scanned=("src" "packages")

    if [[ "${GITHUB_ACTIONS:-}" == "true" && -n "$EXPECTED_SEMGREP_VERSION" ]]; then
      if [[ "$semgrep_version" != "$EXPECTED_SEMGREP_VERSION" ]]; then
        status="FAIL"
        errors+=("semgrep_version_mismatch:${semgrep_version}!=${EXPECTED_SEMGREP_VERSION}")
      fi
    fi

    # semgrep exits non-zero when findings are present; avoid `set +e` by capturing status via `if`.
    if out="$(semgrep --config "$RULES" --json src packages)"; then
      rc=0
    else
      rc=$?
    fi

    if [[ "$rc" -eq 2 ]]; then
      status="FAIL"
      errors+=("semgrep_error")
    else
      findings="$(python3 - <<'PY' "$out"
import json,sys
try:
  d=json.loads(sys.argv[1])
except Exception:
  print("[]")
  raise SystemExit(0)
print(json.dumps(d.get("results", []), indent=2))
PY
)"
      count="$(python3 - <<'PY' "$out"
import json,sys
try:
  d=json.loads(sys.argv[1])
except Exception:
  print("0"); raise SystemExit(0)
print(len(d.get("results", [])))
PY
)"
      if [[ "$count" != "0" ]]; then
        status="FAIL"
      fi
    fi
  fi
fi

scanned_json="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "${scanned[@]+"${scanned[@]}"}")"
errors_json="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "${errors[@]+"${errors[@]}"}")"

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-SEMGREP-SAST\"" \
  "\"timestamp_utc\": \"${ts}\"" \
  "\"git_sha\": \"${sha}\"" \
  "\"schema_fingerprint\": \"${fp}\"" \
  "\"status\": \"${status}\"" \
  "\"semgrep_version\": $(json_escape "$semgrep_version")" \
  "\"scanned_roots\": ${scanned_json}" \
  "\"errors\": ${errors_json}" \
  "\"findings\": ${findings}"

if [[ "$status" == "FAIL" ]]; then
  echo "❌ Semgrep SAST failed. Evidence: $EVIDENCE_FILE" >&2
  exit 1
fi

echo "Semgrep SAST: ${status}. Evidence: $EVIDENCE_FILE"

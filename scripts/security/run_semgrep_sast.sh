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
SEMGRP_TMP_JSON="$(mktemp)"
trap 'rm -f "$SEMGRP_TMP_JSON"' EXIT

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
    scanned=("src" "packages" "services" "scripts")

    if [[ "${GITHUB_ACTIONS:-}" == "true" && -n "$EXPECTED_SEMGREP_VERSION" ]]; then
      if [[ "$semgrep_version" != "$EXPECTED_SEMGREP_VERSION" ]]; then
        status="FAIL"
        errors+=("semgrep_version_mismatch:${semgrep_version}!=${EXPECTED_SEMGREP_VERSION}")
      fi
    fi

    # semgrep exits non-zero when findings are present; avoid `set +e` by capturing status via `if`.
    targets=()
    for root in "${scanned[@]}"; do
      [[ -d "$ROOT_DIR/$root" ]] && targets+=("$root")
    done
    if [[ "${#targets[@]}" -eq 0 ]]; then
      status="FAIL"
      errors+=("no_required_scan_roots_found")
      out='{"results":[]}'
      rc=0
    elif out="$(semgrep --config "$RULES" --json "${targets[@]}")"; then
      rc=0
    else
      rc=$?
    fi

    if [[ "$rc" -eq 2 ]]; then
      status="FAIL"
      errors+=("semgrep_error")
    else
      printf '%s' "$out" > "$SEMGRP_TMP_JSON"
      findings="$(python3 - <<'PY' "$SEMGRP_TMP_JSON"
import json,sys
try:
  d=json.loads(open(sys.argv[1], encoding="utf-8").read())
except Exception:
  print("[]")
  raise SystemExit(0)
print(json.dumps(d.get("results", []), indent=2))
PY
)"
      count="$(python3 - <<'PY' "$SEMGRP_TMP_JSON"
import json,sys
try:
  d=json.loads(open(sys.argv[1], encoding="utf-8").read())
except Exception:
  print("0"); raise SystemExit(0)
print(len(d.get("results", [])))
PY
)"
      root_counts="$(python3 - <<'PY' "$SEMGRP_TMP_JSON" "${targets[@]}"
import json,sys
from pathlib import PurePosixPath
raw_path=sys.argv[1]
targets=sys.argv[2:]
try:
    data=json.loads(open(raw_path, encoding="utf-8").read())
except Exception:
    print("{}")
    raise SystemExit(0)
counts={t:0 for t in targets}
for item in data.get("results", []):
    path=item.get("path","")
    p=PurePosixPath(path)
    root=p.parts[0] if p.parts else ""
    if root in counts:
        counts[root]+=1
print(json.dumps(counts, sort_keys=True))
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
SEMGREP_SCANNED_JSON="$scanned_json" \
SEMGREP_ERRORS_JSON="$errors_json" \
SEMGREP_TARGETS="$(IFS=,; printf '%s' "${targets[*]-}")" \
python3 - <<'PY' "$EVIDENCE_FILE" "$ts" "$sha" "$fp" "$status" "$semgrep_version" "$SEMGRP_TMP_JSON"
import json, os, sys
from pathlib import PurePosixPath

path, ts, sha, fp, status, version, semgrep_json_path = sys.argv[1:]
targets = [t for t in os.environ.get("SEMGREP_TARGETS", "").split(",") if t]
scanned_roots = json.loads(os.environ.get("SEMGREP_SCANNED_JSON", "[]"))
errors = json.loads(os.environ.get("SEMGREP_ERRORS_JSON", "[]"))
findings = []
root_counts = {t: 0 for t in targets}
if semgrep_json_path:
    try:
        raw = json.loads(open(semgrep_json_path, encoding="utf-8").read())
        findings = raw.get("results", [])
        for item in findings:
            p = PurePosixPath(item.get("path", ""))
            root = p.parts[0] if p.parts else ""
            if root in root_counts:
                root_counts[root] += 1
    except Exception:
        findings = []
payload = {
    "check_id": "SEC-SEMGREP-SAST",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": fp,
    "status": status,
    "semgrep_version": version,
    "scanned_roots": scanned_roots,
    "required_root_counts": root_counts,
    "errors": errors,
    "findings": findings,
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
    fh.write("\n")
PY

if [[ "$status" == "FAIL" ]]; then
  echo "❌ Semgrep SAST failed. Evidence: $EVIDENCE_FILE" >&2
  exit 1
fi

echo "Semgrep SAST: ${status}. Evidence: $EVIDENCE_FILE"

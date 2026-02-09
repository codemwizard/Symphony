#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_OUT="$EVIDENCE_DIR/ci_artifact_upload_verified.json"
WORKFLOW="$ROOT_DIR/.github/workflows/invariants.yml"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

is_ci=0
if [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]]; then
  is_ci=1
fi

status="PASS"
errors=()
details=()

if [[ $is_ci -eq 0 ]]; then
  status="SKIPPED"
  details+=("not_running_in_ci")
else
  # 1) Evidence directory must exist and contain at least the canonical evidence root evidence.json.
  if [[ ! -d "$ROOT_DIR/evidence" ]]; then
    errors+=("missing_dir:evidence")
  fi
  if [[ ! -f "$EVIDENCE_DIR/evidence.json" ]]; then
    errors+=("missing_file:evidence/phase0/evidence.json")
  fi
  # 2) Workflow must be configured to upload Phase-0 evidence artifact from evidence/**.
  if [[ ! -f "$WORKFLOW" ]]; then
    errors+=("missing_workflow:.github/workflows/invariants.yml")
  else
    if command -v rg >/dev/null 2>&1; then
      rg -n "name:\\s*phase0-evidence\\b" "$WORKFLOW" >/dev/null 2>&1 || errors+=("workflow_missing_artifact_name:phase0-evidence")
      rg -n "path:\\s*\\|\\s*$" "$WORKFLOW" >/dev/null 2>&1 || true
      rg -n "evidence/\\*\\*" "$WORKFLOW" >/dev/null 2>&1 || errors+=("workflow_missing_artifact_path:evidence/**")
    else
      grep -q "name: phase0-evidence" "$WORKFLOW" || errors+=("workflow_missing_artifact_name:phase0-evidence")
      grep -q "evidence/**" "$WORKFLOW" || errors+=("workflow_missing_artifact_path:evidence/**")
    fi
  fi
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  status="FAIL"
fi

# Include a small listing for auditability (bounded size).
file_list="$(python3 - <<'PY'
import os
from pathlib import Path

root = Path("evidence/phase0")
out = []
if root.exists():
    for p in sorted(root.glob("*.json"))[:50]:
        out.append(str(p))
print("\\n".join(out))
PY
)"

ERRORS_JOINED="$(printf '%s\n' "${errors[@]}")"
DETAILS_JOINED="$(printf '%s\n' "${details[@]}")"
FILE_LIST_JOINED="$file_list"

ERRORS_JOINED="$ERRORS_JOINED" DETAILS_JOINED="$DETAILS_JOINED" FILE_LIST_JOINED="$FILE_LIST_JOINED" write_json "$EVIDENCE_OUT" \
  "\"check_id\": \"CI-ARTIFACT-UPLOAD-PHASE0-EVIDENCE\"" \
  "\"timestamp_utc\": \"$(evidence_now_utc)\"" \
  "\"git_sha\": \"$(git_sha)\"" \
  "\"schema_fingerprint\": \"$(schema_fingerprint)\"" \
  "\"status\": \"$status\"" \
  "\"errors\": $(python3 - <<'PY'
import json, os
errs=[e for e in os.environ.get("ERRORS_JOINED","").split("\\n") if e]
print(json.dumps(errs))
PY
  )" \
  "\"details\": $(python3 - <<'PY'
import json, os
details=[d for d in os.environ.get("DETAILS_JOINED","").split("\\n") if d]
files=[f for f in os.environ.get("FILE_LIST_JOINED","").split("\\n") if f]
print(json.dumps({"notes": details, "phase0_json_files": files}))
PY
)"

if [[ "$status" == "FAIL" ]]; then
  echo "❌ CI artifact upload verification failed. Evidence: $EVIDENCE_OUT" >&2
  printf ' - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "CI artifact upload verification ${status}. Evidence: $EVIDENCE_OUT"

#!/usr/bin/env bash
set -euo pipefail

# verify_skipped_gate_stubs.sh
#
# Mechanical enforcement for Approach B:
# - stub scripts must be marked and must use the shared SKIPPED evidence helper
# - stub scripts must reference the evidence path they are expected to emit (from CONTROL_PLANES.yml)
#
# This is a fast (no-DB) verifier used in CI and local pre-CI.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CP_FILE="$ROOT_DIR/docs/control_planes/CONTROL_PLANES.yml"
HELPER="$ROOT_DIR/scripts/audit/emit_skipped_evidence.sh"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/skipped_gate_stubs.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

errors=()
checked=()

if [[ ! -f "$CP_FILE" ]]; then
  errors+=("missing_control_planes_file")
fi
if [[ ! -x "$HELPER" ]]; then
  errors+=("missing_or_nonexec_helper:scripts/audit/emit_skipped_evidence.sh")
fi

if [[ "${#errors[@]}" -eq 0 ]]; then
  # Parse CONTROL_PLANES.yml without introducing new deps (PyYAML is already toolchain-pinned).
  CP_FILE="$CP_FILE" python3 - <<'PY' >"$EVIDENCE_DIR/.skipped_stub_gates.tmp"
import os,sys
from pathlib import Path
import yaml  # type: ignore

cp = yaml.safe_load(Path(os.environ["CP_FILE"]).read_text(encoding="utf-8")) or {}
planes = (cp.get("control_planes") or {})

rows = []
for plane_name, plane in (planes or {}).items():
    gates = plane.get("required_gates") or []
    if not isinstance(gates, list):
        continue
    for g in gates:
        if not isinstance(g, dict):
            continue
        script = g.get("script")
        evidence = g.get("evidence")
        gate_id = g.get("gate_id")
        if not script or not evidence or not gate_id:
            continue
        rows.append((gate_id, script, evidence))

for gate_id, script, evidence in rows:
    print(f"{gate_id}\t{script}\t{evidence}")
PY

  while IFS=$'\t' read -r gate_id script evidence; do
    script_path="$ROOT_DIR/$script"
    [[ -f "$script_path" ]] || continue

    # Only enforce for scripts that declare themselves as stubs.
    if ! rg -n "^#\\s*symphony:skipped_stub\\b" "$script_path" >/dev/null 2>&1; then
      continue
    fi

    checked+=("$gate_id:$script")

    # Must use helper (uniform schema).
    if ! rg -n "scripts/audit/emit_skipped_evidence\\.sh" "$script_path" >/dev/null 2>&1; then
      errors+=("stub_missing_helper_ref:${gate_id}:${script}")
    fi

    # Must reference the evidence path it is expected to emit.
    if ! rg -n -F "$evidence" "$script_path" >/dev/null 2>&1; then
      errors+=("stub_missing_evidence_path:${gate_id}:${script}:${evidence}")
    fi
  done <"$EVIDENCE_DIR/.skipped_stub_gates.tmp"
fi

status="PASS"
if [[ "${#errors[@]}" -ne 0 ]]; then
  status="FAIL"
fi

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SKIPPED-GATE-STUBS\"" \
  "\"timestamp_utc\": \"${ts}\"" \
  "\"git_sha\": \"${sha}\"" \
  "\"schema_fingerprint\": \"${fp}\"" \
  "\"status\": \"${status}\"" \
  "\"checked\": $(python3 - <<'PY' "${checked[@]:-}"
import json,sys
print(json.dumps(sys.argv[1:]))
PY
)" \
  "\"errors\": $(python3 - <<'PY' "${errors[@]:-}"
import json,sys
print(json.dumps(sys.argv[1:]))
PY
)"

rm -f "$EVIDENCE_DIR/.skipped_stub_gates.tmp" || true

if [[ "$status" != "PASS" ]]; then
  echo "❌ SKIPPED gate stub verification failed. Evidence: $EVIDENCE_FILE" >&2
  printf ' - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "SKIPPED gate stub verification OK. Evidence: $EVIDENCE_FILE"

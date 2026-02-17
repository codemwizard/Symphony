#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REG="$ROOT_DIR/docs/iso20022/contract_registry.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/iso20022_contract_registry.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

PYTHON_BIN="python3"
if [[ -x "$ROOT_DIR/.venv/bin/python3" ]]; then
  PYTHON_BIN="$ROOT_DIR/.venv/bin/python3"
fi

status="PASS"
errors=()

if [[ ! -f "$REG" ]]; then
  status="FAIL"
  errors+=("missing_registry:docs/iso20022/contract_registry.yml")
else
  # Parse check: verify YAML is readable and has required top-level keys.
  if ! "$PYTHON_BIN" - <<'PY' "$REG"; then
import sys
from pathlib import Path
import yaml

path = Path(sys.argv[1])
doc = yaml.safe_load(path.read_text(encoding="utf-8"))
if not isinstance(doc, dict):
    raise SystemExit(1)
for k in ("registry_version", "in_scope", "out_of_scope"):
    if k not in doc:
        raise SystemExit(1)
print("ok")
PY
    status="FAIL"
    errors+=("registry_unparseable_or_missing_keys")
  fi
fi

errors_json="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "${errors[@]+"${errors[@]}"}")"
write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-ISO20022-REGISTRY\"" \
  "\"timestamp_utc\": \"${ts}\"" \
  "\"git_sha\": \"${sha}\"" \
  "\"schema_fingerprint\": \"${fp}\"" \
  "\"status\": \"${status}\"" \
  "\"errors\": ${errors_json}"

if [[ "$status" != "PASS" ]]; then
  echo "❌ ISO 20022 registry verification failed. Evidence: $EVIDENCE_FILE" >&2
  printf ' - %s\n' "${errors[@]}" >&2
  exit 1
fi

echo "ISO 20022 registry verification OK. Evidence: $EVIDENCE_FILE"

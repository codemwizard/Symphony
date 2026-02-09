#!/usr/bin/env bash
set -euo pipefail

# emit_skipped_evidence.sh
#
# Canonical helper for Approach B SKIPPED stubs.
# Writes a deterministic Phase-0 evidence JSON file with status=SKIPPED.
#
# Required args:
#   --evidence <path>   evidence/phase0/*.json
#   --check-id <id>
#   --gate-id <id>
#   --reason <string>
#
# Optional:
#   --invariant-id <id>
#
# NOTE: SKIPPED stubs MUST exit 0. This helper always exits 0 unless misused.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE=""
CHECK_ID=""
GATE_ID=""
INVARIANT_ID=""
REASON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_FILE="${2:-}"; shift 2 ;;
    --check-id) CHECK_ID="${2:-}"; shift 2 ;;
    --gate-id) GATE_ID="${2:-}"; shift 2 ;;
    --invariant-id) INVARIANT_ID="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    *)
      echo "ERROR: unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$EVIDENCE_FILE" || -z "$CHECK_ID" || -z "$GATE_ID" || -z "$REASON" ]]; then
  echo "ERROR: missing required args. Usage:" >&2
  echo "  $0 --evidence evidence/phase0/x.json --check-id X --gate-id G --reason \"...\" [--invariant-id INV-###]" >&2
  exit 2
fi

if [[ "$EVIDENCE_FILE" != evidence/phase0/* ]]; then
  echo "ERROR: evidence path must be under evidence/phase0/: $EVIDENCE_FILE" >&2
  exit 2
fi

mkdir -p "$ROOT_DIR/evidence/phase0"
source "$ROOT_DIR/scripts/lib/evidence.sh"

ts="$(evidence_now_utc)"
sha="$(git_sha)"
fp="$(schema_fingerprint)"

extra=()
if [[ -n "$INVARIANT_ID" ]]; then
  extra+=("\"invariant_id\": \"${INVARIANT_ID}\"")
fi

write_json "$ROOT_DIR/$EVIDENCE_FILE" \
  "\"check_id\": \"${CHECK_ID}\"" \
  "\"timestamp_utc\": \"${ts}\"" \
  "\"git_sha\": \"${sha}\"" \
  "\"schema_fingerprint\": \"${fp}\"" \
  "\"status\": \"SKIPPED\"" \
  "\"gate_id\": \"${GATE_ID}\"" \
  "${extra[@]:-}" \
  "\"reason\": $(python3 - <<'PY' "$REASON"
import json,sys
print(json.dumps(sys.argv[1]))
PY
)"

exit 0


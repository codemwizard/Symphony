#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/routing_fallback_validation.json"

mkdir -p "$EVIDENCE_DIR"

if [[ -x "$ROOT_DIR/scripts/audit/verify_routing_fallback.sh" ]]; then
  "$ROOT_DIR/scripts/audit/verify_routing_fallback.sh"
  # copy evidence to expected validation artifact
  if [[ -f "$ROOT_DIR/evidence/phase0/routing_fallback.json" ]]; then
    cp "$ROOT_DIR/evidence/phase0/routing_fallback.json" "$EVIDENCE_FILE"
  fi
else
  echo "Missing verify_routing_fallback.sh" >&2
  exit 1
fi

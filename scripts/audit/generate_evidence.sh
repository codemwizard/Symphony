#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/evidence.json"
MIGRATIONS_HASH_FILE="$EVIDENCE_DIR/schema_hash.txt"

mkdir -p "$EVIDENCE_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
GIT_SHA="$(git_sha)"
TIMESTAMP_UTC="$(evidence_now_utc)"
PRODUCER="generate_evidence.sh"

# Canonical schema fingerprint is the baseline schema (Phase-0 schema anchor).
SCHEMA_FP="$(schema_fingerprint)"

# Deterministic migrations fingerprint (separate from baseline fingerprint).
MIGRATIONS_FP=$(find "$ROOT_DIR/schema/migrations" -type f -name '*.sql' -print0 \
  | sort -z \
  | xargs -0 sha256sum \
  | sha256sum \
  | awk '{print $1}')

printf '%s' "$MIGRATIONS_FP" > "$MIGRATIONS_HASH_FILE"

python3 - <<PY
import json
from pathlib import Path

out = {
  "check_id": "EVIDENCE-GENERATE",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "git_sha": "$GIT_SHA",
  "schema_fingerprint": "$SCHEMA_FP",
  "migrations_fingerprint": "$MIGRATIONS_FP",
  "status": "PASS",
  "producer": "$PRODUCER",
  "inputs": {
    "migrations_hash_file": "${MIGRATIONS_HASH_FILE}",
    "migrations_dir": "schema/migrations"
  }
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
print("Evidence written: " + "$EVIDENCE_FILE")
PY

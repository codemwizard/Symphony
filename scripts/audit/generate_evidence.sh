#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/evidence.json"
SCHEMA_HASH_FILE="$EVIDENCE_DIR/schema_hash.txt"

mkdir -p "$EVIDENCE_DIR"

GIT_SHA=$(git -C "$ROOT_DIR" rev-parse HEAD)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PRODUCER="generate_evidence.sh"

# deterministic schema hash from migrations
SCHEMA_HASH=$(find "$ROOT_DIR/schema/migrations" -type f -name '*.sql' -print0 \
  | sort -z \
  | xargs -0 sha256sum \
  | sha256sum \
  | awk '{print $1}')

printf '%s' "$SCHEMA_HASH" > "$SCHEMA_HASH_FILE"

python3 - <<PY
import json
from pathlib import Path

out = {
  "git_sha": "$GIT_SHA",
  "schema_hash": "$SCHEMA_HASH",
  "timestamp": "$TIMESTAMP",
  "producer": "$PRODUCER",
  "inputs": {
    "schema_hash_file": "${SCHEMA_HASH_FILE}",
    "migrations_dir": "schema/migrations"
  }
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
print("Evidence written: " + "$EVIDENCE_FILE")
PY

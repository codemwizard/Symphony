#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"

if [[ -z "$EVIDENCE_DIR" || "$EVIDENCE_DIR" == "/" ]]; then
  echo "ERROR: unsafe evidence dir: $EVIDENCE_DIR" >&2
  exit 1
fi

mkdir -p "$EVIDENCE_DIR"

echo "🧹 Cleaning evidence directory: $EVIDENCE_DIR"
rm -rf "$EVIDENCE_DIR"/*
mkdir -p "$EVIDENCE_DIR"
echo "✅ Evidence directory cleaned."

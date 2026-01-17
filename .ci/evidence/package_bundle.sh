#!/usr/bin/env bash
set -euo pipefail

echo "📦 Packaging evidence bundle..."

RUN_ID="${GITHUB_RUN_ID:-local}"
ZIP_NAME="evidence-bundle-${RUN_ID}.zip"

zip -q "$ZIP_NAME" \
  evidence-bundle.json \
  evidence-bundle.sha256

echo "✅ Packaged: $ZIP_NAME"

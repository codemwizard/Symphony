#!/usr/bin/env bash
set -euo pipefail

echo "🔐 Computing evidence bundle hash..."

# Compute hash of the bundle (excluding the hash field itself)
HASH=$(sha256sum evidence-bundle.json | awk '{print $1}')

# Embed hash into the bundle
# Use jq if available, otherwise use sed
if command -v jq &> /dev/null; then
  jq --arg hash "$HASH" \
    '.immutability.bundle_hash = $hash' \
    evidence-bundle.json > tmp.json
  mv tmp.json evidence-bundle.json
else
  # Fallback: use sed for local testing
  sed -i "s/\"bundle_hash\": \"\"/\"bundle_hash\": \"$HASH\"/" evidence-bundle.json
fi

# Write hash to separate file for verification
echo "$HASH  evidence-bundle.json" > evidence-bundle.sha256

echo "✅ Hash computed: $HASH"

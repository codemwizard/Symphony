#!/usr/bin/env bash
set -euo pipefail
file="docs/security/TLS_DEPLOYMENT_GUIDE.md"
[[ -f "$file" ]] || { echo "❌ TLS deployment guide missing"; exit 1; }
for section in \
  "## TLS Termination" \
  "## Certificate Rotation" \
  "## TLS Minimum Versions and Ciphers" \
  "## Log Redaction Requirements"; do
  rg -n "^${section}$" "$file" >/dev/null || { echo "❌ Missing section: $section"; exit 1; }
done
echo "✅ TLS deployment doc sections verified"

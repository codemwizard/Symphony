#!/usr/bin/env bash

# Dev bootstrap script for tenant allowlist
# Helps developers populate the required SYMPHONY_KNOWN_TENANTS variable 
# without breaking the deny-all production default.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEV_TENANTS_FILE="$REPO_ROOT/docs/dev/known_tenants_dev.txt"

if [[ ! -f "$DEV_TENANTS_FILE" ]]; then
    echo "ERROR: Missing developer tenant allowlist definition."
    echo "File not found: $DEV_TENANTS_FILE"
    echo "Generate or request this file before bootstrapping."
    exit 1
fi

raw_list=$(cat "$DEV_TENANTS_FILE" | grep -v '^#' | grep -v '^$' | tr '\n' ',' | sed 's/,$//')

if [[ -z "$raw_list" ]]; then
    echo "ERROR: Dev tenants file is empty or only contains comments."
    exit 1
fi

echo "To configure your shell for local development, run:"
echo ""
echo "    export SYMPHONY_KNOWN_TENANTS=\"$raw_list\""
echo ""
echo "Or append it to your .env.local file."

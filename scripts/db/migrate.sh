#!/usr/bin/env bash
set -e

echo "Applying Symphony schema v1..."

# Ensure we are in the project root or adjust path
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SCHEMA_DIR="$BASE_DIR/schema/v1"

for file in "$SCHEMA_DIR"/*.sql; do
  echo "Running $file"
  psql symphony -f "$file"
done

echo "Schema applied successfully."

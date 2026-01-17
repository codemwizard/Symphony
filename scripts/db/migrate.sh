#!/usr/bin/env bash
set -e

echo "Applying Symphony schema v1..."

# Ensure we are in the project root or adjust path
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SCHEMA_DIR="$BASE_DIR/schema/v1"

# Use DATABASE_URL if set, otherwise fall back to local connection
DB_CONN="${DATABASE_URL:-symphony}"

# Function to run SQL
run_sql() {
  local file="$1"
  if command -v psql &> /dev/null; then
    psql "$DB_CONN" -f "$file"
  elif docker ps | grep -q symphony-postgres; then
    # Fallback to Docker if local psql is missing but container is running
    echo "⚠️  Local psql not found. Running inside Docker container..."
    docker exec -i symphony-postgres psql -U symphony_admin -d symphony -f - < "$file"
  else
    echo "❌ Error: 'psql' command not found and 'symphony-postgres' container not running."
    echo "   Please install postgresql-client or start the docker container."
    exit 1
  fi
}

for file in "$SCHEMA_DIR"/*.sql; do
  echo "Running $file"
  run_sql "$file"
done

echo "Schema applied successfully."

#!/usr/bin/env bash
set -e

echo "Initializing Symphony database..."

createdb symphony || true
psql symphony -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
psql symphony -c "CREATE EXTENSION IF NOT EXISTS citext;"

echo "Database initialized."

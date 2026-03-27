#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# Migration Runner — 0095 RLS Dual-Policy Architecture
# TSK-RLS-ARCH-001 v10.1
#
# Required interface — DO NOT run 0095 directly via psql.
# Implements NOWAIT + retry with exponential backoff.
# ══════════════════════════════════════════════════════════════════════════════

MAX_RETRIES=3
MIGRATION="schema/migrations/0095_rls_dual_policy_architecture.sql"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -z "${DATABASE_URL:-}" ]; then
    echo "FATAL: DATABASE_URL not set"
    exit 1
fi

if [ ! -f "$REPO_ROOT/$MIGRATION" ]; then
    echo "FATAL: Migration file not found: $MIGRATION"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Migration Runner: 0095 RLS Dual-Policy Architecture"
echo "═══════════════════════════════════════════════════════"

for attempt in $(seq 1 "$MAX_RETRIES"); do
    echo ""
    echo "[$(date -u +%FT%TZ)] Attempt $attempt/$MAX_RETRIES"

    if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$REPO_ROOT/$MIGRATION" 2>&1; then
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "Migration 0095 applied successfully."
        echo "═══════════════════════════════════════════════════════"
        exit 0
    fi

    if [ "$attempt" -lt "$MAX_RETRIES" ]; then
        delay=$((2 ** attempt))
        echo ""
        echo "Migration failed (likely lock acquisition). Backing off ${delay}s..."
        sleep "$delay"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "FATAL: Migration 0095 failed after $MAX_RETRIES attempts."
echo "Check for blocking sessions and retry in maintenance window."
echo "═══════════════════════════════════════════════════════"
exit 1
